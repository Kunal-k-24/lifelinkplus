import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SharedPreferences _prefs;
  static const String _cacheKey = 'user_profile_cache';
  static const Duration _cacheDuration = Duration(minutes: 5);

  UserProfileService._({required SharedPreferences prefs}) : _prefs = prefs;

  static Future<UserProfileService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfileService._(prefs: prefs);
  }

  String get _userId => _auth.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(_userId);

  CollectionReference<Map<String, dynamic>> get _emergencyContactsCollection =>
      _userDoc.collection('emergency_contacts');

  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      if (value is Map) {
        return MapEntry(key, _convertTimestamps(Map<String, dynamic>.from(value)));
      }
      if (value is List) {
        return MapEntry(key, value.map((item) {
          if (item is Map) {
            return _convertTimestamps(Map<String, dynamic>.from(item));
          }
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          }
          return item;
        }).toList());
      }
      return MapEntry(key, value);
    });
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_userId.isEmpty) return null;

    try {
      // Check cache first
      final cachedData = _prefs.getString(_cacheKey);
      if (cachedData != null) {
        final cached = json.decode(cachedData) as Map<String, dynamic>;
        final timestamp = DateTime.parse(cached['timestamp'] as String);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return cached['data'] as Map<String, dynamic>;
        }
      }

      // Fetch user data from Firestore
      final doc = await _userDoc.get();
      if (!doc.exists) return null;

      final userData = _convertTimestamps(doc.data()!);
      
      // Fetch emergency contacts
      final emergencyContacts = await _emergencyContactsCollection.get();
      final contacts = emergencyContacts.docs.map((doc) {
        final data = _convertTimestamps(doc.data());
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Combine user data with emergency contacts
      final data = {
        ...userData,
        'emergencyContacts': contacts,
      };
      
      // Cache the data
      await _prefs.setString(_cacheKey, json.encode({
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      }));

      return data;
    } catch (e) {
      print('Error fetching user profile: $e');
      // If there's an error, try to return cached data as fallback
      try {
        final cachedData = _prefs.getString(_cacheKey);
        if (cachedData != null) {
          final cached = json.decode(cachedData) as Map<String, dynamic>;
          return cached['data'] as Map<String, dynamic>;
        }
      } catch (_) {
        // If even the cache fails, rethrow the original error
        rethrow;
      }
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getUserProfileStream() {
    if (_userId.isEmpty) {
      return Stream.value(null);
    }

    // Combine user data stream with emergency contacts stream
    return _userDoc.snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;
      
      final userData = _convertTimestamps(doc.data()!);
      
      // Fetch emergency contacts
      final emergencyContacts = await _emergencyContactsCollection.get();
      final contacts = emergencyContacts.docs.map((doc) {
        final data = _convertTimestamps(doc.data());
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      final data = {
        ...userData,
        'emergencyContacts': contacts,
      };
      
      // Update cache
      await _prefs.setString(_cacheKey, json.encode({
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      }));
      
      return data;
    });
  }

  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      await _userDoc.set(data, SetOptions(merge: true));
      
      // Update cache
      final cachedData = _prefs.getString(_cacheKey);
      if (cachedData != null) {
        final cached = json.decode(cachedData) as Map<String, dynamic>;
        final updatedData = {
          ...(cached['data'] as Map<String, dynamic>),
          ...data,
        };
        await _prefs.setString(_cacheKey, json.encode({
          'timestamp': DateTime.now().toIso8601String(),
          'data': updatedData,
        }));
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  Future<void> updateEmergencyContact(String contactId, Map<String, dynamic> data) async {
    await _emergencyContactsCollection.doc(contactId).update(data);
  }

  Future<void> addEmergencyContact(Map<String, dynamic> contact) async {
    await _emergencyContactsCollection.add(contact);
  }

  Future<void> removeEmergencyContact(String contactId) async {
    await _emergencyContactsCollection.doc(contactId).delete();
  }

  // Basic profile update methods
  Future<void> updateBloodType(String bloodType) async {
    await _userDoc.update({'bloodType': bloodType});
  }

  Future<void> updateAge(int age) async {
    await _userDoc.update({'age': age});
  }

  Future<void> updateHeight(double height) async {
    await _userDoc.update({'height': height});
  }

  Future<void> updateWeight(double weight) async {
    await _userDoc.update({'weight': weight});
  }

  Future<void> updateAllergies(List<String> allergies) async {
    await _userDoc.update({'allergies': allergies});
  }

  Future<void> updateMedicalConditions(List<String> conditions) async {
    await _userDoc.update({'medicalConditions': conditions});
  }

  Future<void> updateQRData(String qrData) async {
    await _userDoc.update({'qrData': qrData});
  }

  Future<void> updateInsuranceInfo(Map<String, dynamic> info) async {
    await _userDoc.update({'insuranceInfo': info});
  }

  Future<void> updateMedicationReminders(List<Map<String, dynamic>> reminders) async {
    await _userDoc.update({'medicationReminders': reminders});
  }

  Future<void> addMedicationReminder(Map<String, dynamic> reminder) async {
    await _userDoc.update({
      'medicationReminders': FieldValue.arrayUnion([reminder]),
    });
  }

  Future<void> removeMedicationReminder(Map<String, dynamic> reminder) async {
    await _userDoc.update({
      'medicationReminders': FieldValue.arrayRemove([reminder]),
    });
  }
} 