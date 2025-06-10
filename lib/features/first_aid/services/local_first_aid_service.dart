import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/first_aid_response.dart';

class LocalFirstAidService {
  static const String _storageKey = 'local_first_aid_data';
  final List<dynamic> _localResponses = [];
  String _currentLanguage = 'en'; // Default to English

  Future<void> initialize() async {
    await _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    print('Loading local first aid data...');
    try {
      final String jsonString = await rootBundle.loadString('assets/data/first_aid_data.json');
      print('JSON string loaded: ${jsonString.substring(0, min(100, jsonString.length))}...');
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      print('JSON data decoded successfully');
      
      _localResponses.clear();
      if (jsonData['emergency_responses'] != null) {
        _localResponses.addAll(jsonData['emergency_responses'] as List<dynamic>);
      }
      if (jsonData['common_responses'] != null) {
        _localResponses.addAll(jsonData['common_responses'] as List<dynamic>);
      }
      
      print('Local responses loaded: ${_localResponses.length} total responses');
    } catch (e, stackTrace) {
      print('Error loading local data: $e');
      print('Stack trace: $stackTrace');
      _localResponses.clear();
    }
  }

  void setLanguage(String languageCode) {
    if (['en', 'hi', 'mr'].contains(languageCode)) {
      _currentLanguage = languageCode;
    }
  }

  FirstAidResponse? _convertToResponse(Map<String, dynamic> data) {
    try {
      final responses = data['responses'] as Map<String, dynamic>;
      final langResponse = responses[_currentLanguage] as Map<String, dynamic>;
      
      final response = FirstAidResponse(
        id: data['id'],
        title: langResponse['title'],
        content: langResponse['content'],
        steps: List<String>.from(langResponse['steps']),
        type: ResponseType.steps,  // All our responses have steps
        isEmergency: langResponse['isEmergency'] ?? false,
      );
      
      print('Converted response: ${response.title} (isEmergency: ${response.isEmergency})');
      return response;
    } catch (e) {
      print('Error converting response: $e');
      print('Data: $data');
      return null;
    }
  }

  Future<List<FirstAidResponse>> searchResponses(String query) async {
    query = query.toLowerCase();
    final results = <FirstAidResponse>[];
    
    for (final response in _localResponses) {
      final converted = _convertToResponse(response);
      if (converted != null) {
        final title = converted.title.toLowerCase();
        final content = converted.content.toLowerCase();
        if (title.contains(query) || content.contains(query)) {
          results.add(converted);
        }
      }
    }
    
    return results;
  }

  Future<FirstAidResponse?> getEmergencyResponse(String query) async {
    for (final response in _localResponses) {
      final converted = _convertToResponse(response);
      if (converted != null && converted.isEmergency) {
        final title = converted.title.toLowerCase();
        final content = converted.content.toLowerCase();
        if (title.contains(query.toLowerCase()) || content.contains(query.toLowerCase())) {
          return converted;
        }
      }
    }
    return null;
  }

  Future<List<FirstAidResponse>> getEmergencyResponses() async {
    final emergencyResponses = <FirstAidResponse>[];
    
    for (final response in _localResponses) {
      final converted = _convertToResponse(response);
      if (converted != null && converted.isEmergency) {
        emergencyResponses.add(converted);
      }
    }
    
    print('Found ${emergencyResponses.length} emergency responses');
    for (final response in emergencyResponses) {
      print('Emergency response: ${response.title} (isEmergency: ${response.isEmergency})');
    }
    
    return emergencyResponses;
  }

  Future<List<FirstAidResponse>> getCommonResponses() async {
    final commonResponses = <FirstAidResponse>[];
    
    print('Total local responses: ${_localResponses.length}');
    
    for (final response in _localResponses) {
      final converted = _convertToResponse(response);
      print('Converting response: ${response['id']}, isEmergency: ${converted?.isEmergency}');
      if (converted != null && !converted.isEmergency) {
        commonResponses.add(converted);
      }
    }
    
    print('Found ${commonResponses.length} common responses');
    for (final response in commonResponses) {
      print('Common response: ${response.title}');
    }
    
    return commonResponses;
  }

  Future<void> clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _localResponses.clear();
  }
} 