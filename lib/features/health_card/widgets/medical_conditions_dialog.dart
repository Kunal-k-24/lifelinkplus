import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class MedicalConditionsDialog extends StatefulWidget {
  final List<String> allergies;
  final List<String> conditions;

  const MedicalConditionsDialog({
    super.key,
    required this.allergies,
    required this.conditions,
  });

  @override
  State<MedicalConditionsDialog> createState() => _MedicalConditionsDialogState();
}

class _MedicalConditionsDialogState extends State<MedicalConditionsDialog> {
  final _allergyController = TextEditingController();
  final _conditionController = TextEditingController();
  late final UserProfileService _userProfileService;
  bool _isLoading = false;
  List<String> _allergies = [];
  List<String> _conditions = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _allergies = List.from(widget.allergies);
    _conditions = List.from(widget.conditions);
  }

  Future<void> _initializeService() async {
    _userProfileService = await UserProfileService.create();
  }

  @override
  void dispose() {
    _allergyController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _addAllergy() async {
    if (_allergyController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      _allergies.add(_allergyController.text);
      await _userProfileService.updateAllergies(_allergies);

      setState(() {
        _allergyController.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding allergy: $e')),
        );
      }
    }
  }

  Future<void> _removeAllergy(String allergy) async {
    try {
      _allergies.remove(allergy);
      await _userProfileService.updateAllergies(_allergies);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing allergy: $e')),
        );
      }
    }
  }

  Future<void> _addCondition() async {
    if (_conditionController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      _conditions.add(_conditionController.text);
      await _userProfileService.updateMedicalConditions(_conditions);

      setState(() {
        _conditionController.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding condition: $e')),
        );
      }
    }
  }

  Future<void> _removeCondition(String condition) async {
    try {
      _conditions.remove(condition);
      await _userProfileService.updateMedicalConditions(_conditions);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing condition: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Medical Conditions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allergies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _allergyController,
                    decoration: const InputDecoration(
                      labelText: 'Add Allergy',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addAllergy(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  onPressed: _isLoading ? null : _addAllergy,
                ),
              ],
            ),
            if (_allergies.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allergies.map((allergy) {
                  return Chip(
                    label: Text(allergy),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeAllergy(allergy),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Medical Conditions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _conditionController,
                    decoration: const InputDecoration(
                      labelText: 'Add Medical Condition',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addCondition(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  onPressed: _isLoading ? null : _addCondition,
                ),
              ],
            ),
            if (_conditions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _conditions.map((condition) {
                  return Chip(
                    label: Text(condition),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeCondition(condition),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
} 