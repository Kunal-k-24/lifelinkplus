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
  StreamSubscription<List<SOSContact>>? _sosContactsSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToSOSContacts();
    _initializeLocation();
  }

  @override
  void dispose() {
    _sosContactsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToSOSContacts() {
    _sosContactsSubscription = SOSContactsManager.getContactsStream().listen(
      (contacts) {
        setState(() {
          _sosContacts = contacts;
        });
      },
      onError: (error) {
        debugPrint('Error loading SOS contacts: $error');
        // Show error in UI if needed
      },
    );
  }

  Future<void> _addSOSContact(String name, String number) async {
    try {
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

      if (!mounted) return;

      final selectedRelationship = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Relationship'),
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

      if (selectedRelationship == null) return;  // User cancelled relationship selection

      String finalRelationship = selectedRelationship;
      if (selectedRelationship == 'Other') {
        if (!mounted) return;

        // Show custom relationship input
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
              autofocus: true,
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

        if (customResult != true || !mounted) return;  // User cancelled or context disposed
        finalRelationship = relationshipController.text.trim();
      }

      // Add the contact
      final success = await SOSContactsManager.addContact(
        SOSContact(
          name: name,
          number: number,
          relationship: finalRelationship,
        ),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $name to emergency contacts'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding contact: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeSOSContact(SOSContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Are you sure you want to remove ${contact.name} from your emergency contacts?'),
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
      final success = await SOSContactsManager.removeContact(contact.id);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency contact removed')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove contact. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

    await showModalBottomSheet(
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
                      onPressed: () {
                        Navigator.pop(context);
                        _pickContact();
                      },
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
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  // Remove any non-digit characters as they're typed
                  final digits = value.replaceAll(RegExp(r'[^\d+]'), '');
                  if (digits != value) {
                    numberController.text = digits;
                    numberController.selection = TextSelection.fromPosition(
                      TextPosition(offset: digits.length),
                    );
                  }
                },
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
                        Navigator.pop(context);
                        _addSOSContact(
                          nameController.text.trim(),
                          numberController.text.trim(),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            duration: Duration(seconds: 2),
                          ),
                        );
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
      // Check permission status first
      final permission = await FlutterContacts.requestPermission();
      if (!permission) {
        if (!mounted) return;
        
        // Show permission explanation dialog
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contacts Permission Required'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app needs access to your contacts to allow you to select emergency contacts.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'You can grant this permission in your device settings.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldRequest == true && mounted) {
          // Open app settings
          await FlutterContacts.openExternalPick();
        }
        return;
      }

      // Proceed with contact picking
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;  // User cancelled selection

      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load contact details'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (fullContact.phones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected contact has no phone numbers'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // If contact has multiple numbers, show number picker
      String selectedNumber = fullContact.phones.first.number;
      if (fullContact.phones.length > 1) {
        final numberResult = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select number for ${fullContact.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: fullContact.phones.map((phone) => ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phone.number),
                subtitle: Text(phone.label.name),
                onTap: () => Navigator.pop(context, phone.number),
              )).toList(),
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

      if (!mounted) return;

      final selectedRelationship = await showDialog<String>(
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

      if (selectedRelationship == null) return;  // User cancelled relationship selection

      String finalRelationship = selectedRelationship;
      if (selectedRelationship == 'Other') {
        if (!mounted) return;

        // Show custom relationship input
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
              autofocus: true,
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

        if (customResult != true || !mounted) return;  // User cancelled or context disposed
        finalRelationship = relationshipController.text.trim();
      }

      // Add the contact
      final success = await SOSContactsManager.addContact(
        SOSContact(
          name: fullContact.displayName,
          number: selectedNumber,
          relationship: finalRelationship,
        ),
      );

      if (!mounted) return;

      if (success) {
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

  Future<void> _showEmergencyNumbers() async {
    await showModalBottomSheet(
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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Numbers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...contacts.map((contact) => ListTile(
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.call),
            color: Colors.green,
            onPressed: () => _launchPhone(contact.number),
          ),
        )),
      ],
    );
  }

  Future<void> _showSOSContacts() async {
    await showModalBottomSheet(
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
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                        tooltip: 'Add Manually',
                        onPressed: _sosContacts.length < SOSContactsManager.maxContacts
                            ? _showAddSOSContactDialog
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.contacts),
                        tooltip: 'Pick from Contacts',
                        onPressed: _sosContacts.length < SOSContactsManager.maxContacts
                            ? _pickSOSContact
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<SOSContact>>(
                stream: SOSContactsManager.getContactsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading contacts: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final contacts = snapshot.data!;
                  
                  if (contacts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.contact_phone_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No emergency contacts added yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showAddSOSContactDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Add Manually'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _pickSOSContact,
                                icon: const Icon(Icons.contacts),
                                label: const Text('Pick from Contacts'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  return ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: contacts.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final reorderedContacts = List<SOSContact>.from(contacts);
                      final item = reorderedContacts.removeAt(oldIndex);
                      reorderedContacts.insert(newIndex, item);
                      SOSContactsManager.reorderContacts(reorderedContacts);
                    },
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return Dismissible(
                        key: Key(contact.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => _removeSOSContact(contact),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: contact.color.withOpacity(0.2),
                            child: Icon(contact.icon, color: contact.color),
                          ),
                          title: Text(contact.name),
                          subtitle: Text(contact.number),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                contact.relationship,
                                style: TextStyle(
                                  color: contact.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call),
                                color: Colors.green,
                                onPressed: () => HospitalContacts.launchDialer(
                                  contact.number,
                                  context,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddSOSContactDialog() async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();

    await showModalBottomSheet(
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
                'Add Emergency Contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter contact name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  // Remove any non-digit characters as they're typed
                  final digits = value.replaceAll(RegExp(r'[^\d+]'), '');
                  if (digits != value) {
                    numberController.text = digits;
                    numberController.selection = TextSelection.fromPosition(
                      TextPosition(offset: digits.length),
                    );
                  }
                },
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
                        Navigator.pop(context);
                        _addSOSContact(
                          nameController.text.trim(),
                          numberController.text.trim(),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSOSContact() async {
    try {
      // Check permission status first
      final permission = await FlutterContacts.requestPermission();
      if (!permission) {
        if (!mounted) return;
        
        // Show permission explanation dialog
        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contacts Permission Required'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This app needs access to your contacts to allow you to select emergency contacts.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 12),
                Text(
                  'You can grant this permission in your device settings.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldRequest == true && mounted) {
          // Open app settings
          await FlutterContacts.openExternalPick();
        }
        return;
      }

      // Proceed with contact picking
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;  // User cancelled selection

      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not load contact details'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (fullContact.phones.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected contact has no phone numbers'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // If contact has multiple numbers, show number picker
      String selectedNumber = fullContact.phones.first.number;
      if (fullContact.phones.length > 1) {
        final numberResult = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Select number for ${fullContact.displayName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: fullContact.phones.map((phone) => ListTile(
                leading: const Icon(Icons.phone),
                title: Text(phone.number),
                subtitle: Text(phone.label.name),
                onTap: () => Navigator.pop(context, phone.number),
              )).toList(),
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

      if (!mounted) return;

      final selectedRelationship = await showDialog<String>(
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

      if (selectedRelationship == null) return;  // User cancelled relationship selection

      String finalRelationship = selectedRelationship;
      if (selectedRelationship == 'Other') {
        if (!mounted) return;

        // Show custom relationship input
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
              autofocus: true,
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

        if (customResult != true || !mounted) return;  // User cancelled or context disposed
        finalRelationship = relationshipController.text.trim();
      }

      // Add the contact
      final success = await SOSContactsManager.addContact(
        SOSContact(
          name: fullContact.displayName,
          number: selectedNumber,
          relationship: finalRelationship,
        ),
      );

      if (!mounted) return;

      if (success) {
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