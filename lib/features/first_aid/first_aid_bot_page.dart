import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/widgets/base_layout.dart';

class FirstAidBotPage extends StatelessWidget {
  const FirstAidBotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      currentIndex: 2,
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildWelcomeMessage(context),
                        const SizedBox(height: 16),
                        _buildCommonQuestions(context),
                        const SizedBox(height: 16),
                        _buildFirstAidTips(context),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.medical_services, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'First Aid Bot',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Online',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Hello! I\'m your First Aid assistant. I can help you with emergency first aid information and guidance. Please note that I\'m not a substitute for professional medical help - in case of serious emergencies, always call emergency services.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildCommonQuestions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Questions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuestionChip(
                  label: 'How to treat a burn?',
                  onTap: () {},
                ),
                _QuestionChip(
                  label: 'CPR steps',
                  onTap: () {},
                ),
                _QuestionChip(
                  label: 'Choking first aid',
                  onTap: () {},
                ),
                _QuestionChip(
                  label: 'Bleeding control',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 200));
  }

  Widget _buildFirstAidTips(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick First Aid Tips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _TipTile(
              icon: Icons.healing,
              title: 'Check ABC',
              description: 'Airway, Breathing, Circulation',
            ),
            _TipTile(
              icon: Icons.phone_in_talk,
              title: 'Call for Help',
              description: 'Don\'t hesitate to call emergency services',
            ),
            _TipTile(
              icon: Icons.security,
              title: 'Stay Safe',
              description: 'Ensure the scene is safe before helping',
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(delay: const Duration(milliseconds: 400));
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ask a first aid question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'First Aid Bot',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QuestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuestionChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      avatar: Icon(
        Icons.help_outline,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TipTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(title),
      subtitle: Text(description),
    );
  }
} 