import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class SOSContact {
  final String name;
  final String number;
  final String relationship;
  final IconData icon;
  final Color color;

  SOSContact({
    required this.name,
    required this.number,
    required this.relationship,
    this.icon = Icons.person,
    this.color = Colors.blue,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'number': number,
    'relationship': relationship,
    'icon': icon.codePoint,
    'color': color.value,
  };

  factory SOSContact.fromJson(Map<String, dynamic> json) => SOSContact(
    name: json['name'] as String,
    number: json['number'] as String,
    relationship: json['relationship'] as String,
    icon: IconData(json['icon'] as int? ?? Icons.person.codePoint, fontFamily: 'MaterialIcons'),
    color: Color(json['color'] as int? ?? Colors.blue.value),
  );

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
  static const String _prefsKey = 'sos_contacts';
  static const int maxContacts = 5; // Limit to 5 emergency contacts
  
  static Future<List<SOSContact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList(_prefsKey) ?? [];
    return contactsJson
        .map((json) => SOSContact.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<bool> addContact(SOSContact newContact) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
      
      contacts.add(contact);
      await _saveContacts(contacts, prefs);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeContact(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = await getContacts();
      if (index >= 0 && index < contacts.length) {
        contacts.removeAt(index);
        await _saveContacts(contacts, prefs);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _saveContacts(List<SOSContact> contacts, SharedPreferences prefs) async {
    final contactsJson = contacts
        .map((contact) => jsonEncode(contact.toJson()))
        .toList();
    await prefs.setStringList(_prefsKey, contactsJson);
  }

  static Future<bool> reorderContacts(int oldIndex, int newIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contacts = await getContacts();
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final contact = contacts.removeAt(oldIndex);
      contacts.insert(newIndex, contact);
      
      await _saveContacts(contacts, prefs);
      return true;
    } catch (e) {
      return false;
    }
  }
} 