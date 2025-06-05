import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/styled_card.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _selectedLanguage = 'English';
  bool _isLoading = false;

  final _languages = ['English', 'Spanish', 'French', 'German'];

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showEditProfileDialog(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        profile: profile,
        onSave: (updatedProfile) async {
          try {
            await _authService.updateUserProfile(updatedProfile);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.toString())),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Animate(
            effects: [
              FadeEffect(duration: 300.ms),
              SlideEffect(
                begin: const Offset(-0.2, 0),
                end: const Offset(0, 0),
                duration: 300.ms,
              ),
            ],
            child: Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 200.ms),
              SlideEffect(
                begin: const Offset(-0.2, 0),
                end: const Offset(0, 0),
                duration: 300.ms,
                delay: 200.ms,
              ),
            ],
            child: Text(
              'Customize your app experience',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Profile Section
          StreamBuilder<UserProfile?>(
            stream: _authService.userProfileStream(_authService.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading profile'),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final profile = snapshot.data!;

              return Animate(
                effects: [
                  FadeEffect(duration: 300.ms, delay: 400.ms),
                  SlideEffect(
                    begin: const Offset(0, 0.2),
                    end: const Offset(0, 0),
                    duration: 300.ms,
                    delay: 400.ms,
                  ),
                ],
                child: StyledCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Profile',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showEditProfileDialog(profile),
                            icon: const Icon(Icons.edit_rounded),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profile.photoUrl != null
                              ? NetworkImage(profile.photoUrl!)
                              : null,
                          child: profile.photoUrl == null
                              ? const Icon(Icons.person_rounded)
                              : null,
                        ),
                        title: Text(profile.fullName),
                        subtitle: Text(profile.email),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.info_rounded),
                        title: const Text('Basic Info'),
                        subtitle: Text(
                          'Age: ${profile.age} • Gender: ${profile.gender}',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.monitor_heart_rounded),
                        title: const Text('Health Info'),
                        subtitle: Text(
                          'Height: ${profile.height}cm • Weight: ${profile.weight}kg • Blood: ${profile.bloodGroup}',
                        ),
                      ),
                      if (profile.allergies.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.warning_rounded),
                          title: const Text('Allergies'),
                          subtitle: Text(profile.allergies.join(', ')),
                        ),
                      if (profile.medicalConditions.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.medical_information_rounded),
                          title: const Text('Medical Conditions'),
                          subtitle: Text(profile.medicalConditions.join(', ')),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Appearance Settings
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 600.ms),
              SlideEffect(
                begin: const Offset(0, 0.2),
                end: const Offset(0, 0),
                duration: 300.ms,
                delay: 600.ms,
              ),
            ],
            child: StyledCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      'Use dark theme',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      // TODO: Implement theme switching
                    },
                  ),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(
                      'Select your preferred language',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      items: _languages.map((lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                          // TODO: Implement language switching
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notifications Settings
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 800.ms),
              SlideEffect(
                begin: const Offset(0, 0.2),
                end: const Offset(0, 0),
                duration: 300.ms,
                delay: 800.ms,
              ),
            ],
            child: StyledCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: Text(
                      'Receive important alerts',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      // TODO: Implement notifications toggle
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Settings
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 1000.ms),
              SlideEffect(
                begin: const Offset(0, 0.2),
                end: const Offset(0, 0),
                duration: 300.ms,
                delay: 1000.ms,
              ),
            ],
            child: StyledCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Location Services'),
                    subtitle: Text(
                      'Allow access to your location',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() => _locationEnabled = value);
                      // TODO: Implement location toggle
                    },
                  ),
                  ListTile(
                    title: const Text('Delete Account'),
                    subtitle: Text(
                      'Permanently remove your account',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    trailing: Icon(
                      Icons.warning_rounded,
                      color: theme.colorScheme.error,
                    ),
                    onTap: () {
                      // TODO: Implement account deletion
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion coming soon'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign Out Button
          Animate(
            effects: [
              FadeEffect(duration: 300.ms, delay: 1200.ms),
              SlideEffect(
                begin: const Offset(0, 0.2),
                end: const Offset(0, 0),
                duration: 300.ms,
                delay: 1200.ms,
              ),
            ],
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleSignOut,
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.logout_rounded),
                label: Text(_isLoading ? 'Signing out...' : 'Sign Out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileDialog extends StatefulWidget {
  final UserProfile profile;
  final Function(UserProfile) onSave;

  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;

  late String _selectedGender;
  late String _selectedBloodGroup;

  final _genders = ['Male', 'Female', 'Other'];
  final _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _ageController = TextEditingController(text: widget.profile.age.toString());
    _heightController = TextEditingController(text: widget.profile.height.toString());
    _weightController = TextEditingController(text: widget.profile.weight.toString());
    _allergiesController = TextEditingController(text: widget.profile.allergies.join(', '));
    _conditionsController = TextEditingController(text: widget.profile.medicalConditions.join(', '));
    _selectedGender = widget.profile.gender;
    _selectedBloodGroup = widget.profile.bloodGroup;
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = UserProfile(
        uid: widget.profile.uid,
        fullName: _nameController.text,
        email: widget.profile.email,
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
        photoUrl: widget.profile.photoUrl,
        createdAt: widget.profile.createdAt,
        updatedAt: DateTime.now(),
      );

      await widget.onSave(updatedProfile);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;

    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_rounded),
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
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                items: _genders.map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  prefixIcon: Icon(Icons.height_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_rounded),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBloodGroup,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_rounded),
                ),
                items: _bloodGroups.map((group) => DropdownMenuItem(
                  value: group,
                  child: Text(group),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedBloodGroup = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies (comma-separated)',
                  prefixIcon: Icon(Icons.warning_rounded),
                  hintText: 'e.g. Peanuts, Penicillin',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(
                  labelText: 'Medical Conditions (comma-separated)',
                  prefixIcon: Icon(Icons.medical_information_rounded),
                  hintText: 'e.g. Asthma, Diabetes',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 