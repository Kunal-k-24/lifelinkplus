import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medical_record.dart';
import '../services/medical_records_service.dart';
import 'file_upload_widget.dart';

class MedicalRecordDetails extends StatefulWidget {
  final MedicalRecord record;

  const MedicalRecordDetails({
    super.key,
    required this.record,
  });

  @override
  State<MedicalRecordDetails> createState() => _MedicalRecordDetailsState();
}

class _MedicalRecordDetailsState extends State<MedicalRecordDetails> {
  final MedicalRecordsService _recordsService = MedicalRecordsService();
  late MedicalRecord _record;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
  }

  Future<void> _onFileUploaded(String url, String type) async {
    setState(() => _isLoading = true);
    try {
      final updatedRecord = await _recordsService.addFileToRecord(
        _record.id,
        url,
        type,
      );
      setState(() => _record = updatedRecord);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding file: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onFileDeleted(String url, String type) async {
    setState(() => _isLoading = true);
    try {
      final updatedRecord = await _recordsService.removeFileFromRecord(
        _record.id,
        url,
        type,
      );
      setState(() => _record = updatedRecord);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing file: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_record.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Prescriptions'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildDetailsTab(),
                _buildPrescriptionsTab(),
                _buildReportsTab(),
              ],
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            _record.type,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Date',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            DateFormat.yMMMd().format(_record.date),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Description',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            _record.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (_record.doctorName != null) ...[
            const SizedBox(height: 16),
            Text(
              'Doctor',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              _record.doctorName!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
          if (_record.hospitalName != null) ...[
            const SizedBox(height: 16),
            Text(
              'Hospital',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              _record.hospitalName!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FileUploadWidget(
            files: _record.prescriptions.map((p) => p.fileUrl).toList(),
            type: 'prescriptions',
            onFileUploaded: (url) => _onFileUploaded(url, 'prescriptions'),
            onFileDeleted: (url) => _onFileDeleted(url, 'prescriptions'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FileUploadWidget(
            files: _record.reports.map((r) => r.fileUrl).toList(),
            type: 'reports',
            onFileUploaded: (url) => _onFileUploaded(url, 'reports'),
            onFileDeleted: (url) => _onFileDeleted(url, 'reports'),
          ),
        ],
      ),
    );
  }
}

class PrescriptionDialog extends StatefulWidget {
  const PrescriptionDialog({super.key});

  @override
  State<PrescriptionDialog> createState() => _PrescriptionDialogState();
}

class _PrescriptionDialogState extends State<PrescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _medicationController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _instructionsController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;

  @override
  void dispose() {
    _medicationController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _savePrescription() {
    if (!_formKey.currentState!.validate()) return;

    final prescription = Prescription(
      medication: _medicationController.text,
      dosage: _dosageController.text,
      frequency: _frequencyController.text,
      startDate: _startDate,
      endDate: _endDate,
      instructions: _instructionsController.text.isEmpty
          ? null
          : _instructionsController.text,
      isActive: _isActive,
    );

    Navigator.of(context).pop(prescription);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Prescription'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the medication name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the dosage';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the frequency';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
              ),
              ListTile(
                title: const Text('End Date (Optional)'),
                subtitle: _endDate != null
                    ? Text(DateFormat('MMM dd, yyyy').format(_endDate!))
                    : const Text('Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndDate,
              ),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _savePrescription,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _findingsController = TextEditingController();
  final _conclusionController = TextEditingController();
  String _selectedType = 'blood_test';
  DateTime _date = DateTime.now();
  final Map<String, dynamic> _parameters = {};
  final List<String> _attachments = [];

  final List<String> _reportTypes = [
    'blood_test',
    'x_ray',
    'mri',
    'ct_scan',
    'ultrasound',
    'ecg',
    'other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _findingsController.dispose();
    _conclusionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _addParameter() {
    showDialog(
      context: context,
      builder: (context) => _ParameterDialog(
        onAdd: (name, value) {
          setState(() => _parameters[name] = value);
        },
      ),
    );
  }

  void _removeParameter(String name) {
    setState(() => _parameters.remove(name));
  }

  void _saveReport() {
    if (!_formKey.currentState!.validate()) return;

    final report = Report(
      title: _titleController.text,
      type: _selectedType,
      date: _date,
      findings: _findingsController.text.isEmpty
          ? null
          : _findingsController.text,
      conclusion: _conclusionController.text.isEmpty
          ? null
          : _conclusionController.text,
      parameters: _parameters.isEmpty ? null : _parameters,
      attachments: _attachments,
    );

    Navigator.of(context).pop(report);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Report'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the report title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _findingsController,
                decoration: const InputDecoration(
                  labelText: 'Findings (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conclusionController,
                decoration: const InputDecoration(
                  labelText: 'Conclusion (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Parameters'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addParameter,
                  ),
                ],
              ),
              if (_parameters.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...(_parameters.entries.map((e) {
                  return ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value.toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeParameter(e.key),
                    ),
                  );
                })),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveReport,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ParameterDialog extends StatefulWidget {
  final void Function(String name, dynamic value) onAdd;

  const _ParameterDialog({required this.onAdd});

  @override
  State<_ParameterDialog> createState() => _ParameterDialogState();
}

class _ParameterDialogState extends State<_ParameterDialog> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addParameter() {
    if (_nameController.text.isEmpty || _valueController.text.isEmpty) return;

    widget.onAdd(_nameController.text, _valueController.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Parameter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Parameter Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(
              labelText: 'Value',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addParameter,
          child: const Text('Add'),
        ),
      ],
    );
  }
} 