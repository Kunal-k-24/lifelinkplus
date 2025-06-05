import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/styled_card.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final _questions = [
    'What should I do in case of a heart attack?',
    'How to treat a burn?',
    'What to do for a sprained ankle?',
    'How to perform CPR?',
    'What to do for a bleeding wound?',
    'How to handle a seizure?',
  ];

  final _answers = {
    'What should I do in case of a heart attack?': [
      '1. Call emergency services (911) immediately',
      '2. Help the person sit or lie down',
      '3. Loosen any tight clothing',
      '4. If prescribed, assist with taking aspirin',
      '5. Begin CPR if the person becomes unconscious',
    ],
    'How to treat a burn?': [
      '1. Cool the burn under cool (not cold) running water',
      '2. Remove any jewelry or tight items',
      '3. Don\'t break blisters',
      '4. Apply moisturizer or aloe vera',
      '5. Bandage loosely with sterile gauze',
    ],
    'What to do for a sprained ankle?': [
      'Remember RICE:',
      '- Rest: Avoid putting weight on it',
      '- Ice: Apply ice for 15-20 minutes',
      '- Compression: Use an elastic bandage',
      '- Elevation: Keep it above heart level',
    ],
    'How to perform CPR?': [
      '1. Check for responsiveness',
      '2. Call for emergency help',
      '3. Start chest compressions:',
      '   - Place hands on center of chest',
      '   - Push hard and fast (100-120/minute)',
      '   - Allow chest to recoil completely',
      '4. Give rescue breaths if trained',
      '5. Continue until help arrives',
    ],
    'What to do for a bleeding wound?': [
      '1. Clean your hands and wear gloves if available',
      '2. Apply direct pressure with clean cloth',
      '3. Keep pressure until bleeding stops',
      '4. Clean wound with soap and water',
      '5. Apply antibiotic ointment and bandage',
    ],
    'How to handle a seizure?': [
      '1. Keep the person safe from injury',
      '2. Ease them to the floor if standing',
      '3. Turn them on their side',
      '4. Remove tight clothing around neck',
      '5. Time the seizure',
      '6. Stay with them until fully conscious',
    ],
  };

  String? _selectedQuestion;
  final _scrollController = ScrollController();

  void _selectQuestion(String question) {
    setState(() {
      _selectedQuestion = question;
    });
    
    // Scroll to bottom after animation
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            children: [
              Text(
                'First Aid Guide',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: 8),
              Text(
                'Select a question to get instant first aid guidance',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(),
              const SizedBox(height: 24),

              // Chat-like interface
              if (_selectedQuestion != null) ...[
                // Question bubble
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen
                          ? mediaQuery.size.width * 0.75
                          : mediaQuery.size.width * 0.5,
                    ),
                    child: StyledCard(
                      color: theme.colorScheme.primaryContainer,
                      child: Text(
                        _selectedQuestion!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 16),

                // Answer bubble
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen
                          ? mediaQuery.size.width * 0.75
                          : mediaQuery.size.width * 0.5,
                    ),
                    child: StyledCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._answers[_selectedQuestion]!.map((step) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              step,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )).toList(),
                          const SizedBox(height: 8),
                          Text(
                            'Remember: In case of emergency, always call 911',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),

        // Question buttons
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _questions.map((question) => ActionChip(
                  label: Text(question),
                  onPressed: () => _selectQuestion(question),
                  backgroundColor: _selectedQuestion == question
                      ? theme.colorScheme.primaryContainer
                      : null,
                )).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 