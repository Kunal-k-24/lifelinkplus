import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class SOSService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Emergency numbers
  static const String emergencyNumber = '108';
  
  // Demo emergency contacts (in a real app, these would come from user settings)
  final List<Map<String, String>> emergencyContacts = [
    {'name': 'Emergency Services', 'number': '108'},
    {'name': 'Police', 'number': '100'},
    {'name': 'Ambulance', 'number': '102'},
  ];

  Future<void> _requestPermissions() async {
    await Permission.phone.request();
    await Permission.sms.request();
  }

  Future<void> playAlarm() async {
    if (_isPlaying) {
      await stopAlarm();
      return;
    }

    try {
      _isPlaying = true;
      await _audioPlayer.play(AssetSource('sounds/emergency_alarm.mp3'));
      _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the alarm sound
    } catch (e) {
      debugPrint('Error playing alarm: $e');
    }
  }

  Future<void> stopAlarm() async {
    try {
      _isPlaying = false;
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  Future<void> callEmergency() async {
    await _requestPermissions();
    try {
      await FlutterPhoneDirectCaller.callNumber(emergencyNumber);
    } catch (e) {
      debugPrint('Error making emergency call: $e');
    }
  }

  String getDemoSMSText() {
    return '''
EMERGENCY ALERT!

This is a demo emergency SMS that would be sent in a real emergency.

Location: [Current Location]
Blood Group: [User's Blood Group]
Medical Conditions: [User's Medical Conditions]
Allergies: [User's Allergies]

This person needs immediate medical assistance.
''';
  }

  void dispose() {
    _audioPlayer.dispose();
  }
} 