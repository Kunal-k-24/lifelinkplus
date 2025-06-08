import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/medical_record.dart';
import 'file_upload_widget.dart';

class MedicalRecordForm extends StatefulWidget {
  final MedicalRecord? record;

  const MedicalRecordForm({super.key, this.record});

  @override
  State<MedicalRecordForm> createState() => _MedicalRecordFormState();
}

class _MedicalRecordFormState extends State<MedicalRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _hospitalNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Diagnosis';
  bool _isLoading = false;
  List<FileData> _prescriptions = [];
  List<FileData> _reports = [];

  final List<String> _recordTypes = [
    'Diagnosis',
    'Surgery',
    'Vaccination',
    'Medication',
    'Test',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _titleController.text = widget.record!.title;
      _descriptionController.text = widget.record!.description;
      _doctorNameController.text = widget.record!.doctorName ?? '';
      _hospitalNameController.text = widget.record!.hospitalName ?? '';
      _selectedDate = widget.record!.date;
      _selectedType = widget.record!.type;
      _prescriptions = List.from(widget.record!.prescriptions);
      _reports = List.from(widget.record!.reports);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _doctorNameController.dispose();
    _hospitalNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final recordsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medical_records');

      // Check for existing record with same title and date
      if (widget.record == null) {
        final existingRecords = await recordsRef
            .where('title', isEqualTo: _titleController.text)
            .where('date', isEqualTo: _selectedDate.toIso8601String())
            .get();

        if (existingRecords.docs.isNotEmpty) {
          throw Exception('A record with this title and date already exists');
        }
      }

      final record = MedicalRecord(
        id: widget.record?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        type: _selectedType,
        doctorName: _doctorNameController.text.isEmpty
            ? null
            : _doctorNameController.text,
        hospitalName: _hospitalNameController.text.isEmpty
            ? null
            : _hospitalNameController.text,
        prescriptions: _prescriptions,
        reports: _reports,
        attachments: widget.record?.attachments ?? [],
        additionalInfo: widget.record?.additionalInfo ?? {},
      );

      if (widget.record != null) {
        await recordsRef.doc(widget.record!.id).update(record.toFirestore());
      } else {
        await recordsRef.add(record.toFirestore());
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.record != null
                  ? 'Medical record updated successfully'
                  : 'Medical record added successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFileUploaded(String url, String type) {
    final fileData = FileData(
      fileUrl: url,
      uploadedAt: DateTime.now(),
    );

    setState(() {
      if (type == 'prescriptions') {
        _prescriptions.add(fileData);
      } else if (type == 'reports') {
        _reports.add(fileData);
      }
    });
  }

  void _onFileDeleted(String url, String type) {
    setState(() {
      if (type == 'prescriptions') {
        _prescriptions.removeWhere((p) => p.fileUrl == url);
      } else if (type == 'reports') {
        _reports.removeWhere((r) => r.fileUrl == url);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record != null ? 'Edit Record' : 'Add Record'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Record Type',
                border: OutlineInputBorder(),
              ),
              items: _recordTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a record type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Doctor Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hospitalNameController,
              decoration: const InputDecoration(
                labelText: 'Hospital/Clinic Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Prescriptions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FileUploadWidget(
              files: _prescriptions.map((p) => p.fileUrl).toList(),
              type: 'prescriptions',
              onFileUploaded: (url) => _onFileUploaded(url, 'prescriptions'),
              onFileDeleted: (url) => _onFileDeleted(url, 'prescriptions'),
            ),
            const SizedBox(height: 24),
            Text(
              'Reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FileUploadWidget(
              files: _reports.map((r) => r.fileUrl).toList(),
              type: 'reports',
              onFileUploaded: (url) => _onFileUploaded(url, 'reports'),
              onFileDeleted: (url) => _onFileDeleted(url, 'reports'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveRecord,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.record != null ? 'Update Record' : 'Add Record'),
            ),
          ],
        ),
      ),
    );
  }
} 