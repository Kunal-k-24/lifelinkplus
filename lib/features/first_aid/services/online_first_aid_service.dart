import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/api_config.dart';
import '../models/first_aid_response.dart';

class OnlineFirstAidService {
  final ImagePicker _imagePicker = ImagePicker();
  bool _hasCheckedConnection = false;
  bool _lastKnownStatus = false;
  DateTime? _lastCheckTime;
  
  Future<bool> isOnline() async {
    // Check if we have a recent status (within last 30 seconds)
    if (_hasCheckedConnection && _lastCheckTime != null) {
      final difference = DateTime.now().difference(_lastCheckTime!);
      if (difference.inSeconds < 30) {
        return _lastKnownStatus;
      }
    }

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _updateConnectionStatus(false);
        return false;
      }
      
      // Check if OpenRouter API is reachable
      final response = await http.post(
        Uri.parse('${ApiConfig.gptBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.gptApiKey}',
          ...ApiConfig.defaultHeaders,
        },
        body: jsonEncode({
          'model': 'openai/gpt-3.5-turbo',
          'messages': [{'role': 'user', 'content': 'test'}],
          'max_tokens': 1
        }),
      ).timeout(const Duration(seconds: 5));
      
      final isOnline = response.statusCode == 200;
      _updateConnectionStatus(isOnline);
      return isOnline;
    } catch (e) {
      print('Connection check error: $e');
      _updateConnectionStatus(false);
      return false;
    }
  }

  void _updateConnectionStatus(bool status) {
    _hasCheckedConnection = true;
    _lastKnownStatus = status;
    _lastCheckTime = DateTime.now();
  }

  Future<FirstAidResponse> getAIResponse(String query, {XFile? image}) async {
    if (!await isOnline()) {
      throw Exception('No internet connection available. Please check your connection and try again.');
    }

    try {
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': _buildSystemPrompt(),
        }
      ];

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        messages.add({
          'role': 'user',
          'content': '''
Analysis request for the following image:
Image data: data:image/jpeg;base64,$base64Image

Query: $query'''
        });
      } else {
        messages.add({
          'role': 'user',
          'content': query,
        });
      }

      final Map<String, dynamic> requestBody = {
        'model': 'openai/gpt-3.5-turbo',  // Using GPT-3.5 to reduce token usage
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 250,  // Reduced token limit
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.gptBaseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.gptApiKey}',
          ...ApiConfig.defaultHeaders,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 402) {
        // Handle credit limit error
        throw Exception('Credit limit reached. The response may be truncated. Please try a shorter query or contact support.');
      } else if (response.statusCode != 200) {
        print('API Error Response: ${response.body}');
        throw Exception('API request failed with status ${response.statusCode}: ${response.body}');
      }

      try {
        final responseData = jsonDecode(response.body);
        if (responseData['choices'] == null || responseData['choices'].isEmpty) {
          throw Exception('Invalid API response format: Missing choices array');
        }
        final aiResponse = responseData['choices'][0]['message']['content'];
        if (aiResponse == null || aiResponse.toString().trim().isEmpty) {
          throw Exception('Empty response from AI service');
        }
        
        return _processResponse(aiResponse.toString(), query);
      } catch (e) {
        print('Response parsing error. Response body: ${response.body}');
        throw Exception('Error parsing API response: $e');
      }
    } catch (e) {
      if (e.toString().contains('No internet connection')) {
        throw e;
      }
      throw Exception('Error getting AI response: $e');
    }
  }

  String _buildSystemPrompt() {
    return '''You are a first aid assistant. Respond in the same language as the user's query. Keep responses concise:
1. Provide clear first aid steps
2. Identify emergencies
3. Give accurate information
4. Analyze any images
5. Prioritize life-threatening conditions

Format:
- Brief assessment
- Numbered steps
- Mark emergencies with "⚠️"
- End with key warning if needed''';
  }

  Future<XFile?> captureImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('Error capturing image: $e');
    }
  }

  List<String> getSuggestions(String query) {
    final commonQueries = [
      'What to do for a burn?',
      'How to handle bleeding?',
      'CPR steps',
      'Choking first aid',
      'Sprain treatment',
      'Heart attack signs',
    ];
    
    if (query.isEmpty) {
      return commonQueries;
    }
    
    return commonQueries.where((suggestion) =>
      suggestion.toLowerCase().contains(query.toLowerCase())).toList();
  }

  String _generateTitle(String query) {
    final words = query.split(' ');
    if (words.length <= 5) return query;
    return words.take(5).join(' ') + '...';
  }

  FirstAidResponse _processResponse(String content, String query) {
    final bool isEmergency = _detectEmergency(content);
    final List<String> steps = _extractSteps(content);
    final String? imageUrl = content.contains('imageUrl') ? content.split(': ')[1].split(',')[0] : null;
    final String? detectedCondition = content.contains('detectedCondition') ? content.split(': ')[1].split(',')[0] : null;
    
    String title = detectedCondition ?? _generateTitle(query);
    
    return FirstAidResponse(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      type: steps.isNotEmpty ? ResponseType.steps : (imageUrl != null ? ResponseType.image : ResponseType.text),
      steps: steps,
      imageUrl: imageUrl,
      isEmergency: isEmergency,
    );
  }

  bool _detectEmergency(String response) {
    final emergencyKeywords = [
      'emergency',
      'immediate medical attention',
      'call 911',
      'life-threatening',
      'severe',
      'critical'
    ];
    
    return emergencyKeywords.any((keyword) => 
      response.toLowerCase().contains(keyword.toLowerCase()));
  }

  List<String> _extractSteps(String response) {
    final steps = <String>[];
    final lines = response.split('\n');
    
    for (final line in lines) {
      if (RegExp(r'^\d+[\.\)]').hasMatch(line.trim())) {
        steps.add(line.trim());
      }
    }
    
    return steps;
  }
} 