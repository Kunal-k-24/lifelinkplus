import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_profile.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  final String displayName;
  final String? photoUrl;

  const ProfileSetupScreen({
    super.key,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  int _currentStep = 0;

  late final TextEditingController _nameController;
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedBloodGroup = 'A+';
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw 'User not found';

      final profile = UserProfile(
        uid: user.uid,
        fullName: _nameController.text,
        email: widget.email,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        bloodGroup: _selectedBloodGroup,
        allergies: _allergiesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        medicalConditions: _conditionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        photoUrl: widget.photoUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _authService.createUserProfile(profile);

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Complete Your Profile'),
            centerTitle: true,
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: Stepper(
                        currentStep: _currentStep,
                        onStepContinue: () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep++);
                          } else {
                            _handleSubmit();
                          }
                        },
                        onStepCancel: () {
                          if (_currentStep > 0) {
                            setState(() => _currentStep--);
                          }
                        },
                        controlsBuilder: (context, details) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                FilledButton(
                                  onPressed: details.onStepContinue,
                                  child: Text(
                                    _currentStep == 2 ? 'Submit' : 'Continue',
                                  ),
                                ),
                                if (_currentStep > 0) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: details.onStepCancel,
                                    child: const Text('Back'),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                        steps: [
                          _buildBasicInfoStep(),
                          _buildHealthInfoStep(),
                          _buildMedicalInfoStep(),
                        ],
                      ).animate().fadeIn(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildBasicInfoStep() {
    return Step(
      title: const Text('Basic Information'),
      content: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value);
              if (age == null || age < 0 || age > 120) {
                return 'Please enter a valid age';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: _genders
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedGender = value);
              }
            },
          ),
        ],
      ).animate().slideX(),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildHealthInfoStep() {
    return Step(
      title: const Text('Health Information'),
      content: Column(
        children: [
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your height';
              }
              final height = double.tryParse(value);
              if (height == null || height < 0 || height > 300) {
                return 'Please enter a valid height';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight < 0 || weight > 500) {
                return 'Please enter a valid weight';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedBloodGroup,
            decoration: const InputDecoration(
              labelText: 'Blood Group',
              border: OutlineInputBorder(),
            ),
            items: _bloodGroups
                .map((group) => DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedBloodGroup = value);
              }
            },
          ),
        ],
      ).animate().slideX(),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildMedicalInfoStep() {
    return Step(
      title: const Text('Medical Information'),
      content: Column(
        children: [
          TextFormField(
            controller: _allergiesController,
            decoration: const InputDecoration(
              labelText: 'Allergies (comma-separated)',
              border: OutlineInputBorder(),
              helperText: 'Leave empty if none',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conditionsController,
            decoration: const InputDecoration(
              labelText: 'Medical Conditions (comma-separated)',
              border: OutlineInputBorder(),
              helperText: 'Leave empty if none',
            ),
            maxLines: 2,
          ),
        ],
      ).animate().slideX(),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
    );
  }
} 