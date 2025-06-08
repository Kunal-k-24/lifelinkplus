import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../data/hospital_contacts.dart';
import '../data/sos_contacts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

// Add this provider to handle background loading
final hospitalsProvider = _HospitalsProvider();

class _HospitalsProvider {
  Position? _lastPosition;
  List<Hospital> _cachedHospitals = [];
  DateTime? _lastFetchTime;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      // Get location and fetch hospitals in background
      final position = await Geolocator.getCurrentPosition();
      _lastPosition = position;
      await _fetchHospitals(position);
    } catch (e) {
      debugPrint('Error in background loading: $e');
    }
  }

  Future<void> _fetchHospitals(Position position) async {
    try {
      final query = '''
        [out:json][timeout:10];
        (
          node["amenity"="hospital"]["name"]["name"!=""]["name"!~"unknown|Unknown"](around:3000,${position.latitude},${position.longitude});
          way["amenity"="hospital"]["name"]["name"!=""]["name"!~"unknown|Unknown"](around:3000,${position.latitude},${position.longitude});
          relation["amenity"="hospital"]["name"]["name"!=""]["name"!~"unknown|Unknown"](around:3000,${position.latitude},${position.longitude});
        );
        out center body;
        >;
        out skel qt;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        // Create a Random instance for consistent number assignment
        final random = Random(DateTime.now().millisecondsSinceEpoch);
        final availableNumbers = List<String>.from(HospitalContacts.defaultHospitalNumbers);
        
        final hospitals = elements.where((e) {
          if (e['tags'] == null || e['tags']['amenity'] != 'hospital') return false;
          
          final name = e['tags']['name']?.toString().trim();
          if (name == null || name.isEmpty || name.toLowerCase().contains('unknown')) return false;
          
          double? lat, lon;
          if (e['type'] == 'node') {
            lat = e['lat']?.toDouble();
            lon = e['lon']?.toDouble();
          } else if (e['type'] == 'way' || e['type'] == 'relation') {
            if (e['center'] != null) {
              lat = e['center']['lat']?.toDouble();
              lon = e['center']['lon']?.toDouble();
            }
          }
          
          if (lat == null || lon == null) return false;
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lat,
            lon,
          );
          return distance > 10;
        }).map((e) {
          final tags = e['tags'] as Map<String, dynamic>;
          
          double lat, lon;
          if (e['type'] == 'node') {
            lat = e['lat'].toDouble();
            lon = e['lon'].toDouble();
          } else {
            lat = e['center']['lat'].toDouble();
            lon = e['center']['lon'].toDouble();
          }
          
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lat,
            lon,
          );

          // Get a random phone number from the available list
          String phone = '';
          if (availableNumbers.isNotEmpty) {
            final index = random.nextInt(availableNumbers.length);
            phone = availableNumbers[index];
            // Remove the used number to avoid duplicates
            availableNumbers.removeAt(index);
          }

          // Build address
          String address = '';
          final addressComponents = <String>[];
          
          if (tags['addr:street'] != null) {
            String streetAddress = tags['addr:street'];
            if (tags['addr:housenumber'] != null) {
              streetAddress = '${tags['addr:housenumber']} $streetAddress';
            }
            addressComponents.add(streetAddress);
          }
          
          if (tags['addr:city'] != null) {
            addressComponents.add(tags['addr:city']);
          }
          
          if (tags['addr:state'] != null) {
            addressComponents.add(tags['addr:state']);
          }
          
          if (tags['addr:postcode'] != null) {
            addressComponents.add(tags['addr:postcode']);
          }
          
          if (addressComponents.isNotEmpty) {
            address = addressComponents.join(', ');
          } else if (tags['addr:full'] != null) {
            address = tags['addr:full'];
          } else if (tags['address'] != null) {
            address = tags['address'];
          }
          
          if (address.trim().isEmpty || 
              address.toLowerCase().contains('unknown') ||
              address.toLowerCase() == 'address not available') {
            address = 'Location available on map';
          }

          return Hospital(
            name: tags['name']!.trim(),
            address: address,
            phoneNumber: phone,
            latitude: lat,
            longitude: lon,
            distance: distance / 1000,
          );
        }).toList();

        hospitals.removeWhere((h) => 
          h.distance < 0.01 ||
          h.name.toLowerCase().contains('unknown') ||
          h.name.trim().isEmpty
        );
        
        hospitals.sort((a, b) => a.distance.compareTo(b.distance));
        
        _cachedHospitals = hospitals;
        _lastFetchTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error fetching hospitals: $e');
    }
  }

  List<Hospital> getCachedHospitals() => _cachedHospitals;
  bool hasRecentData() => _lastFetchTime != null && 
      DateTime.now().difference(_lastFetchTime!) < const Duration(minutes: 5);
  Position? getLastPosition() => _lastPosition;
}

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  Position? _currentPosition;
  final List<Hospital> _nearbyHospitals = [];
  bool _isLoading = true;
  String? _error;
  String _loadingStatus = 'Getting location...';
  List<SOSContact> _sosContacts = [];

  @override
  void initState() {
    super.initState();
    _loadSOSContacts();
    _initializeLocation();
  }

  Future<void> _loadSOSContacts() async {
    final contacts = await SOSContactsManager.getContacts();
    setState(() {
      _sosContacts = contacts;
    });
  }

  Future<void> _addSOSContact() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final relationshipController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter contact name',
              ),
            ),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'E.g., Family, Friend',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  numberController.text.isNotEmpty &&
                  relationshipController.text.isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final contact = SOSContact(
        name: nameController.text,
        number: numberController.text,
        relationship: relationshipController.text,
      );
      await SOSContactsManager.addContact(contact);
      await _loadSOSContacts();
    }
  }

  Future<void> _removeSOSContact(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: const Text('Are you sure you want to remove this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SOSContactsManager.removeContact(index);
      await _loadSOSContacts();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Check for cached data first
      if (hospitalsProvider.hasRecentData()) {
        setState(() {
          _currentPosition = hospitalsProvider.getLastPosition();
          _nearbyHospitals.addAll(hospitalsProvider.getCachedHospitals());
          _isLoading = false;
        });
        // Refresh in background
        _getCurrentLocation();
        return;
      }
      
      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error initializing: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _loadingStatus = 'Checking location services...');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _error = 'Location services are disabled';
        });
        return;
      }

      setState(() => _loadingStatus = 'Requesting location permission...');
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _error = 'Location permissions are denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _error = 'Location permissions are permanently denied';
        });
        return;
      }

      setState(() => _loadingStatus = 'Getting your location...');
      
      final position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _currentPosition = position;
        _loadingStatus = 'Finding nearby hospitals...';
      });
      
      await _fetchNearbyHospitals(position);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error getting location: $e';
      });
    }
  }

  Future<void> _fetchNearbyHospitals(Position position) async {
    try {
      final query = '''
        [out:json][timeout:10];
        (
          node["amenity"="hospital"](around:3000,${position.latitude},${position.longitude});
          way["amenity"="hospital"](around:3000,${position.latitude},${position.longitude});
        );
        out body;
        >;
        out skel qt;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        
        final hospitals = elements.where((e) => 
          e['tags'] != null && 
          e['tags']['amenity'] == 'hospital'
        ).map((e) {
          final tags = e['tags'] as Map<String, dynamic>;
          final lat = e['lat'] ?? position.latitude;
          final lon = e['lon'] ?? position.longitude;
          
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            lat.toDouble(),
            lon.toDouble(),
          );

          String phone = tags['phone'] ?? 
                        tags['contact:phone'] ?? 
                        tags['phone:mobile'] ?? 
                        tags['contact:mobile'] ?? 
                        '';
                        
          // Clean up phone number
          phone = phone.replaceAll(RegExp(r'[^\d+]'), '');
          if (!phone.startsWith('+')) {
            phone = '+$phone';
          }

          return Hospital(
            name: tags['name'] ?? 'Unknown Hospital',
            address: tags['addr:street'] ?? 
                    tags['addr:full'] ?? 
                    tags['address'] ?? 
                    'Address not available',
            phoneNumber: phone,
            latitude: lat.toDouble(),
            longitude: lon.toDouble(),
            distance: distance / 1000,
          );
        }).toList();

        hospitals.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          _nearbyHospitals.clear();
          _nearbyHospitals.addAll(hospitals);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load hospitals');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error fetching hospitals: $e';
      });
    }
  }

  Future<void> _launchMaps(Hospital hospital) async {
    if (_currentPosition == null) return;

    final origin = '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final destination = '${hospital.latitude},${hospital.longitude}';

    // Try platform-specific URLs first
    final androidUrl = Uri.parse(
      'google.navigation:q=$destination&mode=d'
    );
    final iosUrl = Uri.parse(
      'comgooglemaps://?saddr=$origin&daddr=$destination&directionsmode=driving'
    );
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving'
    );

    try {
      if (await canLaunchUrl(androidUrl)) {
        await launchUrl(androidUrl);
      } else if (await canLaunchUrl(iosUrl)) {
        await launchUrl(iosUrl);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      } else {
        throw 'Could not launch maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    try {
      final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      if (digits.isEmpty) {
        throw 'Invalid phone number';
      }

      // Try different URL schemes
      final schemes = [
        'tel:$digits',
        'tel:+91$digits',
        'tel:0$digits'
      ];

      for (final scheme in schemes) {
        final url = Uri.parse(scheme);
        if (await canLaunchUrl(url)) {
          final result = await launchUrl(url);
          if (result) return;
        }
      }

      throw 'Could not launch phone';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call. Please try dialing manually.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Hospitals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: _showEmergencyNumbers,
          ),
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: () => _showSOSContacts(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _getCurrentLocation();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 24),
              _buildEmergencyCard(),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _loadingStatus,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildEmergencyCard(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _getCurrentLocation();
      },
      child: Column(
        children: [
          _buildEmergencyCard(),
          Expanded(
            child: _nearbyHospitals.isEmpty
                ? const Center(
                    child: Text('No hospitals found nearby'),
                  )
                : ListView.builder(
                    itemCount: _nearbyHospitals.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final hospital = _nearbyHospitals[index];
                      return _buildHospitalCard(hospital);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quick Emergency Numbers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_call),
                  onPressed: _showAddNumberDialog,
                  tooltip: 'Add Custom Number',
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  // Stack buttons vertically on small screens
                  return Column(
                    children: HospitalContacts.mainEmergencyContacts.map((contact) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => HospitalContacts.launchDialer(
                              contact.number,
                              context,
                            ),
                            icon: Icon(contact.icon),
                            label: Text('${contact.name} (${contact.number})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ).toList(),
                  );
                } else {
                  // Stack buttons horizontally on larger screens
                  return Row(
                    children: HospitalContacts.mainEmergencyContacts.map((contact) =>
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: () => HospitalContacts.launchDialer(
                              contact.number,
                              context,
                            ),
                            icon: Icon(contact.icon),
                            label: Text(contact.name),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddNumberDialog() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Emergency Number',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickContact,
                      icon: const Icon(Icons.contacts),
                      label: const Text('Pick from Contacts'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('OR'),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter contact name',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isNotEmpty && 
                          numberController.text.isNotEmpty) {
                        _addEmergencyContact(
                          nameController.text,
                          numberController.text,
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact?.phones.isNotEmpty == true) {
            // If contact has multiple numbers, show number picker
            String selectedNumber = fullContact!.phones.first.number;
            if (fullContact.phones.length > 1) {
              final numberResult = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Select number for ${fullContact.displayName}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: fullContact.phones.map((phone) {
                      final formattedNumber = HospitalContacts.formatPhoneNumber(phone.number);
                      return ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(formattedNumber),
                        subtitle: Text(phone.label.toString()),
                        onTap: () => Navigator.pop(context, phone.number),
                      );
                    }).toList(),
                  ),
                ),
              );
              if (numberResult != null) {
                selectedNumber = numberResult;
              } else {
                return; // User cancelled number selection
              }
            }

            // Show relationship picker
            final relationships = [
              'Father',
              'Mother',
              'Spouse',
              'Brother',
              'Sister',
              'Friend',
              'Doctor',
              'Other'
            ];

            String? selectedRelationship = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Relationship with ${fullContact.displayName}'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: relationships.map((relationship) => ListTile(
                      leading: Icon(
                        SOSContact.getIconForRelationship(relationship),
                        color: SOSContact.getColorForRelationship(relationship),
                      ),
                      title: Text(relationship),
                      onTap: () => Navigator.pop(context, relationship),
                    )).toList(),
                  ),
                ),
              ),
            );

            // If "Other" is selected, show custom relationship input
            if (selectedRelationship == 'Other') {
              final relationshipController = TextEditingController();
              final customResult = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Specify Relationship'),
                  content: TextField(
                    controller: relationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'E.g., Cousin, Neighbor',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (relationshipController.text.isNotEmpty) {
                          Navigator.pop(context, true);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              );

              if (customResult == true) {
                selectedRelationship = relationshipController.text.trim();
              } else {
                return; // User cancelled custom relationship input
              }
            }

            if (selectedRelationship != null && mounted) {
              final success = await SOSContactsManager.addContact(
                SOSContact(
                  name: fullContact.displayName,
                  number: selectedNumber,
                  relationship: selectedRelationship,
                ),
              );

              if (mounted) {
                if (success) {
                  await _loadSOSContacts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${fullContact.displayName} to emergency contacts'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not add contact. Maximum limit reached or contact already exists.'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected contact has no phone numbers'),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access contacts was denied'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking contact: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _addEmergencyContact(String name, String number) {
    // Here you can implement the logic to save the contact
    // For now, we'll just show a success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name to emergency contacts'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEmergencyNumbers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Numbers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildEmergencySection(
                      'Main Emergency Numbers',
                      HospitalContacts.mainEmergencyContacts,
                      Colors.red,
                    ),
                    const SizedBox(height: 16),
                    _buildEmergencySection(
                      'Additional Emergency Services',
                      HospitalContacts.additionalEmergencyContacts,
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildEmergencySection(
                      'Healthcare Departments',
                      HospitalContacts.healthcareDepartments,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencySection(
    String title,
    List<EmergencyContact> contacts,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...contacts.map((contact) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(contact.icon, color: color),
            ),
            title: Text(contact.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.number),
                Text(
                  contact.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.call),
              color: color,
              onPressed: () => HospitalContacts.launchDialer(
                contact.number,
                context,
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _showSOSContacts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _showAddContactDialog,
                        tooltip: 'Add Contact',
                      ),
                      IconButton(
                        icon: const Icon(Icons.contacts),
                        onPressed: _pickContact,
                        tooltip: 'Pick from Contacts',
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              if (_sosContacts.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contact_phone_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No emergency contacts added',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'Add your family and friends as emergency contacts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: _sosContacts.length,
                    onReorder: (oldIndex, newIndex) async {
                      final success = await SOSContactsManager.reorderContacts(
                        oldIndex,
                        newIndex,
                      );
                      if (success) {
                        await _loadSOSContacts();
                      }
                    },
                    itemBuilder: (context, index) {
                      final contact = _sosContacts[index];
                      return Card(
                        key: ValueKey(contact.number),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: contact.color.withOpacity(0.2),
                            child: Icon(contact.icon, color: contact.color),
                          ),
                          title: Text(contact.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(contact.relationship),
                              Text(
                                HospitalContacts.formatPhoneNumber(contact.number),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.call),
                                color: Colors.green,
                                onPressed: () => HospitalContacts.launchDialer(
                                  contact.number,
                                  context,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => _removeSOSContact(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Drag and drop to reorder contacts by priority',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final relationshipController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter contact name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'E.g., Father, Mother, Spouse',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  numberController.text.isNotEmpty &&
                  relationshipController.text.isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await SOSContactsManager.addContact(
        SOSContact(
          name: nameController.text.trim(),
          number: numberController.text.trim(),
          relationship: relationshipController.text.trim(),
        ),
      );

      if (mounted) {
        if (success) {
          await _loadSOSContacts();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${nameController.text} to emergency contacts'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not add contact. Maximum limit reached or contact already exists.'),
            ),
          );
        }
      }
    }
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hospital.address,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Distance: ${hospital.distance.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchMaps(hospital),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => HospitalContacts.launchDialer(
                      HospitalContacts.mainEmergencyContacts[0].number, // Ambulance
                      context,
                    ),
                    icon: const Icon(Icons.emergency),
                    label: const Text('Emergency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Hospital {
  final String name;
  final String address;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final double distance;

  Hospital({
    required this.name,
    required this.address,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });
} 