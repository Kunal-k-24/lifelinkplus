import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SOSContact {
  final String id;  // Document ID for Firestore
  final String name;
  final String number;
  final String relationship;
  final IconData icon;
  final Color color;
  final DateTime createdAt;

  SOSContact({
    String? id,
    required this.name,
    required this.number,
    required this.relationship,
    this.icon = Icons.person,
    this.color = Colors.blue,
    DateTime? createdAt,
  }) : 
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
    this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'number': number,
    'relationship': relationship,
    'icon': icon.codePoint,
    'color': color.value,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory SOSContact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SOSContact(
      id: doc.id,
      name: data['name'] as String,
      number: data['number'] as String,
      relationship: data['relationship'] as String,
      icon: IconData(data['icon'] as int? ?? Icons.person.codePoint, fontFamily: 'MaterialIcons'),
      color: Color(data['color'] as int? ?? Colors.blue.value),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Get appropriate icon based on relationship
  static IconData getIconForRelationship(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'father':
      case 'dad':
        return Icons.man;
      case 'mother':
      case 'mom':
        return Icons.woman;
      case 'spouse':
      case 'wife':
      case 'husband':
        return Icons.favorite;
      case 'brother':
      case 'sister':
      case 'sibling':
        return Icons.family_restroom;
      case 'friend':
        return Icons.people;
      case 'doctor':
        return Icons.medical_services;
      default:
        return Icons.person;
    }
  }

  // Get appropriate color based on relationship
  static Color getColorForRelationship(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'father':
      case 'dad':
      case 'mother':
      case 'mom':
        return Colors.green;
      case 'spouse':
      case 'wife':
      case 'husband':
        return Colors.red;
      case 'brother':
      case 'sister':
      case 'sibling':
        return Colors.orange;
      case 'friend':
        return Colors.purple;
      case 'doctor':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }
}

class SOSContactsManager {
  static const int maxContacts = 5; // Limit to 5 emergency contacts
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the collection reference for the current user's contacts
  static CollectionReference<Map<String, dynamic>> _getContactsCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('emergency_contacts');
  }

  // Get contacts as a real-time stream
  static Stream<List<SOSContact>> getContactsStream() {
    try {
      return _getContactsCollection()
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SOSContact.fromFirestore(doc))
              .toList());
    } catch (e) {
      debugPrint('Error getting contacts stream: $e');
      return Stream.value([]);
    }
  }

  // Get contacts as Future
  static Future<List<SOSContact>> getContacts() async {
    try {
      final snapshot = await _getContactsCollection().orderBy('createdAt').get();
      return snapshot.docs
          .map((doc) => SOSContact.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting contacts: $e');
      return [];
    }
  }

  // Add a new contact
  static Future<bool> addContact(SOSContact newContact) async {
    try {
      final contacts = await getContacts();
      
      // Check if contact already exists
      if (contacts.any((contact) => contact.number == newContact.number)) {
        return false;
      }
      
      // Check maximum contacts limit
      if (contacts.length >= maxContacts) {
        return false;
      }

      // Create contact with appropriate icon and color
      final contact = SOSContact(
        name: newContact.name,
        number: newContact.number,
        relationship: newContact.relationship,
        icon: SOSContact.getIconForRelationship(newContact.relationship),
        color: SOSContact.getColorForRelationship(newContact.relationship),
      );
      
      await _getContactsCollection().doc(contact.id).set(contact.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return false;
    }
  }

  // Remove a contact
  static Future<bool> removeContact(String contactId) async {
    try {
      await _getContactsCollection().doc(contactId).delete();
      return true;
    } catch (e) {
      debugPrint('Error removing contact: $e');
      return false;
    }
  }

  // Reorder contacts
  static Future<bool> reorderContacts(List<SOSContact> contacts) async {
    try {
      final batch = _firestore.batch();
      final collection = _getContactsCollection();
      
      // Update each contact with new timestamp to maintain order
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        final updatedContact = SOSContact(
          id: contact.id,
          name: contact.name,
          number: contact.number,
          relationship: contact.relationship,
          icon: contact.icon,
          color: contact.color,
          createdAt: DateTime.now().add(Duration(milliseconds: i)),
        );
        batch.set(collection.doc(contact.id), updatedContact.toFirestore());
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error reordering contacts: $e');
      return false;
    }
  }
} 