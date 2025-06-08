import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class EmergencyContactsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> contacts;

  const EmergencyContactsDialog({super.key, required this.contacts});

  @override
  State<EmergencyContactsDialog> createState() => _EmergencyContactsDialogState();
}

class _EmergencyContactsDialogState extends State<EmergencyContactsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _relationshipController = TextEditingController();
  late final UserProfileService _userProfileService;
  bool _isLoading = false;
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _initializeService();
    _contacts = List.from(widget.contacts);
  }

  Future<void> _initializeService() async {
    _userProfileService = await UserProfileService.create();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contact = {
        'name': _nameController.text,
        'number': _numberController.text,
        'relationship': _relationshipController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _userProfileService.addEmergencyContact(contact);

      setState(() {
        _contacts.add(contact);
        _nameController.clear();
        _numberController.clear();
        _relationshipController.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding contact: $e')),
        );
      }
    }
  }

  Future<void> _editContact(Map<String, dynamic> contact) async {
    _nameController.text = contact['name'] ?? '';
    _numberController.text = contact['number'] ?? '';
    _relationshipController.text = contact['relationship'] ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Contact'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _relationshipController,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the relationship';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _numberController.clear();
              _relationshipController.clear();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final updatedContact = {
          ...contact,
          'name': _nameController.text,
          'number': _numberController.text,
          'relationship': _relationshipController.text,
        };

        final contactId = contact['id'] as String?;
        if (contactId == null) {
          throw Exception('Contact ID not found');
        }

        await _userProfileService.updateEmergencyContact(contactId, updatedContact);

        setState(() {
          final index = _contacts.indexOf(contact);
          if (index != -1) {
            _contacts[index] = updatedContact;
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating contact: $e')),
          );
        }
      }
    }

    _nameController.clear();
    _numberController.clear();
    _relationshipController.clear();
  }

  Future<void> _removeContact(Map<String, dynamic> contact) async {
    try {
      final contactId = contact['id'] as String?;
      if (contactId == null) {
        throw Exception('Contact ID not found');
      }

      await _userProfileService.removeEmergencyContact(contactId);

      setState(() {
        _contacts.remove(contact);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing contact: $e')),
        );
      }
    }
  }

  Future<void> _reorderContacts(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final contact = _contacts.removeAt(oldIndex);
      _contacts.insert(newIndex, contact);
      setState(() {});

      // Update each contact with a new order field
      for (var i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        final contactId = contact['id'] as String?;
        if (contactId != null) {
          await _userProfileService.updateEmergencyContact(
            contactId,
            {...contact, 'order': i},
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reordering contacts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _numberController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _relationshipController,
                            decoration: const InputDecoration(
                              labelText: 'Relationship',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the relationship';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _addContact,
                              icon: const Icon(Icons.add),
                              label: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Add Contact'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_contacts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _contacts.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(contact['name'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contact['number'] ?? ''),
                                Text(
                                  contact['relationship'] ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editContact(contact),
                                  tooltip: 'Edit Contact',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeContact(contact),
                                  tooltip: 'Remove Contact',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 