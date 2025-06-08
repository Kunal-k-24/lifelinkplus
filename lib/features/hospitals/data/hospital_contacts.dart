import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyContact {
  final String name;
  final String number;
  final String description;
  final IconData icon;

  const EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
    this.icon = Icons.emergency,
  });
}

class HospitalContacts {
  // Essential emergency numbers only
  static const List<EmergencyContact> mainEmergencyContacts = [
    EmergencyContact(
      name: 'Ambulance',
      number: '108',
      description: 'Emergency Medical Services',
      icon: Icons.local_hospital,
    ),
    EmergencyContact(
      name: 'Police',
      number: '100',
      description: 'Police Emergency Services',
      icon: Icons.local_police,
    ),
    EmergencyContact(
      name: 'Fire',
      number: '101',
      description: 'Fire Emergency Services',
      icon: Icons.fire_truck,
    ),
  ];

  // Additional emergency services
  static const List<EmergencyContact> additionalEmergencyContacts = [
    EmergencyContact(
      name: 'Women Helpline',
      number: '1091',
      description: 'Women Safety & Support',
      icon: Icons.woman,
    ),
    EmergencyContact(
      name: 'Child Helpline',
      number: '1098',
      description: 'Child Safety & Support',
      icon: Icons.child_care,
    ),
    EmergencyContact(
      name: 'Blood Bank',
      number: '104',
      description: 'Blood Bank Services',
      icon: Icons.bloodtype,
    ),
    EmergencyContact(
      name: 'Covid-19 Helpline',
      number: '1075',
      description: 'Covid-19 Related Support',
      icon: Icons.coronavirus,
    ),
  ];

  // Healthcare department numbers
  static const List<EmergencyContact> healthcareDepartments = [
    EmergencyContact(
      name: 'AIIMS Emergency',
      number: '011-26588700',
      description: 'AIIMS Hospital Emergency',
      icon: Icons.local_hospital,
    ),
    EmergencyContact(
      name: 'Health Department',
      number: '011-23219311',
      description: 'Government Health Department',
      icon: Icons.health_and_safety,
    ),
    EmergencyContact(
      name: 'Red Cross',
      number: '011-23711551',
      description: 'Red Cross Emergency Services',
      icon: Icons.medical_services,
    ),
  ];

  // Launch phone dialer with improved functionality
  static Future<void> launchDialer(String phoneNumber, BuildContext context) async {
    try {
      // Clean and format the phone number
      String number = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (number.length == 10) {
        number = '+91$number';
      }

      // Try different URL schemes in order of preference
      final schemes = [
        'tel://$number',  // Android direct dial
        'tel:$number',    // Standard tel scheme
        'telprompt:$number', // iOS prompt
      ];

      bool launched = false;
      for (final scheme in schemes) {
        try {
          final uri = Uri.parse(scheme);
          if (await canLaunchUrl(uri)) {
            launched = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );
            if (launched) break;
          }
        } catch (e) {
          debugPrint('Error with scheme $scheme: $e');
          continue;
        }
      }

      // If all attempts fail, try one last time with platform default
      if (!launched) {
        final uri = Uri.parse('tel:$number');
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      // If still not launched, show dialog
      if (!launched && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Could not open dialer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Number: $number'),
                const SizedBox(height: 8),
                const Text('Would you like to:'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: number));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Number copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Copy Number'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  // Try with intent flag
                  final uri = Uri.parse('tel:$number');
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalNonBrowserApplication,
                  );
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unable to make call. Please try manually dialing $phoneNumber'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () => Clipboard.setData(ClipboardData(text: phoneNumber)),
            ),
          ),
        );
      }
    }
  }

  // Get emergency message
  static String getEmergencyMessage() {
    return '''
    🚨 Main Emergency Numbers:
    • Ambulance: 108
    • National Emergency: 112
    • Medical Emergency: 102
    
    Call any of these numbers for immediate assistance.
    ''';
  }

  // Common hospital phone number patterns by region/city
  // Add more patterns as needed for different regions
  static const Map<String, List<String>> hospitalPhonePatterns = {
    'Mumbai': ['022'],
    'Delhi': ['011'],
    'Bangalore': ['080'],
    'Chennai': ['044'],
    'Kolkata': ['033'],
    'Hyderabad': ['040'],
    // Add more cities as needed
  };

  // Default hospital numbers (replace these with actual numbers for your region)
  static const List<String> defaultHospitalNumbers = [
    '+91 22 6657 8000',
    '+91 22 2444 9199',
    '+91 22 2646 9449',
    '+91 22 6767 6767',
    '+91 22 3989 8989',
    '+91 22 2353 8245',
    '+91 22 6731 8888',
    '+91 22 2411 6666',
    '+91 22 2411 2373',
    '+91 22 2412 7777',
    // Add more reliable hospital numbers for your region
  ];

  // Format phone number for display
  static String formatPhoneNumber(String number) {
    final digits = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length > 10) {
      return '${digits.substring(0, digits.length - 10)} ${digits.substring(digits.length - 10, digits.length - 7)} ${digits.substring(digits.length - 7, digits.length - 4)} ${digits.substring(digits.length - 4)}';
    }
    return number;
  }
} 