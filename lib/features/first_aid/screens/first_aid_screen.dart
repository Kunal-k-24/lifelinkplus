import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/first_aid_response.dart';
import '../services/local_first_aid_service.dart';
import '../services/online_first_aid_service.dart';
import '../widgets/chat_message.dart';
import '../widgets/emergency_banner.dart';
import '../widgets/suggestion_chips.dart';
import '../widgets/chat_input.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final LocalFirstAidService _localService = LocalFirstAidService();
  final OnlineFirstAidService _onlineService = OnlineFirstAidService();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<FirstAidResponse> _responses = [];
  bool _isLoading = false;
  bool _isOnline = true;
  List<String> _suggestions = [];
  XFile? _currentImage;
  String _currentLanguage = 'en';

  Map<String, Map<String, String>> get _translations => {
    'en': {
      'appTitle': 'First Aid Assistant',
      'offlineMessage': 'You are offline. Select from available first aid guides:',
      'searchHint': 'Select a first aid guide',
      'emergency': 'Emergency Guides',
      'common': 'Common First Aid',
      'retryConnection': 'Retry Connection',
    },
    'hi': {
      'appTitle': 'प्राथमिक चिकित्सा सहायक',
      'offlineMessage': 'आप ऑफ़लाइन हैं। उपलब्ध प्राथमिक चिकित्सा गाइड में से चुनें:',
      'searchHint': 'प्राथमिक चिकित्सा गाइड चुनें',
      'emergency': 'आपातकालीन गाइड',
      'common': 'सामान्य प्राथमिक चिकित्सा',
      'retryConnection': 'पुनः प्रयास करें',
    },
    'mr': {
      'appTitle': 'प्रथमोपचार सहाय्यक',
      'offlineMessage': 'आपण ऑफलाइन आहात. उपलब्ध प्रथमोपचार मार्गदर्शकांमधून निवडा:',
      'searchHint': 'प्रथमोपचार मार्गदर्शक निवडा',
      'emergency': 'आणीबाणी मार्गदर्शक',
      'common': 'सामान्य प्रथमोपचार',
      'retryConnection': 'पुन्हा प्रयत्न करा',
    },
  };

  String _translate(String key) => _translations[_currentLanguage]?[key] ?? _translations['en']![key]!;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);
    print('Initializing services...');
    await _localService.initialize();
    await _checkOnlineStatus();
    print('Loading initial responses...');
    await _loadInitialResponses();
    print('Services initialized, isOnline: $_isOnline');
    setState(() => _isLoading = false);
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
      _localService.setLanguage(languageCode);
      _responses.clear();
    });
    _loadInitialResponses();
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी';
      case 'mr': return 'मराठी';
      default: return code;
    }
  }

  Future<void> _checkOnlineStatus() async {
    final isOnline = await _onlineService.isOnline();
    if (mounted) {
      setState(() => _isOnline = isOnline);
    }
  }

  Future<void> _loadInitialResponses() async {
    if (_isOnline) {
      setState(() {
        _responses.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Getting emergency and common responses...');
      final emergencyResponses = await _localService.getEmergencyResponses();
      final commonResponses = await _localService.getCommonResponses();
      print('Responses retrieved - Emergency: ${emergencyResponses.length}, Common: ${commonResponses.length}');
      
      if (mounted) {
        setState(() {
          _responses.clear();
          _responses.addAll([...emergencyResponses, ...commonResponses]);
          print('Total responses in state: ${_responses.length}');
        });
      }
    } catch (e) {
      print('Error loading responses: $e');
      print('Stack trace: ${StackTrace.current}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _queryController.clear();
      _suggestions = [];
    });

    try {
      if (_isOnline) {
        FirstAidResponse response;
        try {
          response = await _onlineService.getAIResponse(
            query,
            image: _currentImage,
          );
        } catch (apiError) {
          // Handle API-specific errors
          setState(() => _isLoading = false);
          _showError('AI Service Error: ${apiError.toString()}');
          
          // Fallback to local service
          final localResponses = await _localService.searchResponses(query);
          if (localResponses.isNotEmpty) {
            setState(() {
              _responses.addAll(localResponses);
              _currentImage = null;
            });
            _scrollToBottom();
          }
          return;
        }

        setState(() {
          _responses.add(response);
          _currentImage = null;
        });

        if (response.isEmergency) {
          try {
            final emergencyResponse = await _localService.getEmergencyResponse(query);
            if (emergencyResponse != null) {
              setState(() {
                _responses.add(emergencyResponse);
              });
            }
          } catch (emergencyError) {
            print('Error fetching emergency response: $emergencyError');
          }
        }
      } else {
        final localResponses = await _localService.searchResponses(query);
        if (localResponses.isEmpty) {
          setState(() {
            _responses.add(FirstAidResponse(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Offline Mode',
              content: '''You are currently offline. Please check your internet connection to access AI assistance. Meanwhile, here are some basic first aid tips:

1. For any life-threatening emergency, call emergency services immediately
2. Keep the person calm and still
3. Check for breathing and consciousness
4. Stop any bleeding by applying direct pressure
5. Do not move the person unless they are in immediate danger
6. If unsure, seek professional medical help when possible''',
              type: ResponseType.steps,
              isEmergency: true,
            ));
          });
        } else {
          setState(() {
            _responses.addAll(localResponses);
          });
        }
      }

      _scrollToBottom();
    } catch (e) {
      print('General error in _handleQuery: $e');
      _showError('Error: Unable to process request. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleImageCapture() async {
    if (!_isOnline) {
      _showError('Camera analysis requires internet connection');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final image = await _onlineService.captureImage();
      if (image != null) {
        setState(() => _currentImage = image);
        final response = await _onlineService.getAIResponse(
          'Please analyze this image and provide first aid guidance',
          image: image,
        );
        setState(() {
          _responses.add(response);
          _currentImage = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Error processing image');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onQueryChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    if (_isOnline) {
      final suggestions = await _onlineService.getSuggestions(value);
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildOfflineContent() {
    final emergencyResponses = _responses.where((r) => r.isEmergency).toList();
    final commonResponses = _responses.where((r) => !r.isEmergency).toList();
    
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _translate('offlineMessage'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        if (emergencyResponses.isNotEmpty) ...[
          Text(
            _translate('emergency'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...emergencyResponses.map((response) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    Icons.warning_rounded,
                    color: theme.colorScheme.error,
                    size: 28,
                  ),
                  title: Text(
                    response.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        response.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      if (response.steps != null && response.steps!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...response.steps!.map((step) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  step,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
        ],
        if (commonResponses.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            _translate('common'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...commonResponses.map((response) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                color: theme.colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    response.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        response.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      if (response.steps != null && response.steps!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...response.steps!.map((step) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  step,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ],
                  ),
                  isThreeLine: true,
                ),
              )),
        ],
        if (emergencyResponses.isEmpty && commonResponses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No first aid guides available.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_translate('appTitle')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: 'Change Language',
            onSelected: _changeLanguage,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Text(_getLanguageName('en')),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Text(_getLanguageName('hi')),
              ),
              PopupMenuItem(
                value: 'mr',
                child: Text(_getLanguageName('mr')),
              ),
            ],
          ),
          IconButton(
            icon: Icon(_isOnline ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _checkOnlineStatus,
            tooltip: _isOnline ? 'Online Mode' : 'Offline Mode',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isOnline
              ? Column(
                  children: [
                    EmergencyBanner(
                      message: _translate('offlineMessage'),
                      actionLabel: _translate('retryConnection'),
                      onAction: _checkOnlineStatus,
                    ),
                    Expanded(child: _buildOfflineContent()),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _responses.length,
                        itemBuilder: (context, index) {
                          final response = _responses[index];
                          return ChatMessage(
                            response: response,
                            isLastMessage: index == _responses.length - 1,
                          );
                        },
                      ),
                    ),
                    if (_suggestions.isNotEmpty)
                      SuggestionChips(
                        suggestions: _suggestions,
                        onSelected: (suggestion) {
                          _queryController.text = suggestion;
                          _handleQuery(suggestion);
                        },
                      ),
                    if (_isLoading) const LinearProgressIndicator(),
                    if (_currentImage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: Row(
                          children: [
                            Icon(
                              Icons.image,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Image attached for analysis'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _currentImage = null),
                            ),
                          ],
                        ),
                      ),
                    ChatInput(
                      controller: _queryController,
                      onChanged: _onQueryChanged,
                      onSubmitted: _handleQuery,
                      isLoading: _isLoading,
                      onCameraPressed: _handleImageCapture,
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 