import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medical_record.dart';
import '../services/medical_records_service.dart';
import 'medical_record_form.dart';
import 'medical_record_details.dart';

class MedicalTimeline extends StatefulWidget {
  const MedicalTimeline({super.key});

  @override
  State<MedicalTimeline> createState() => _MedicalTimelineState();
}

class _MedicalTimelineState extends State<MedicalTimeline> {
  final _recordsService = MedicalRecordsService();
  bool _isLoading = true;
  List<MedicalRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await _recordsService.getRecords();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medical records: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecord(MedicalRecord record) async {
    try {
      await _recordsService.deleteRecord(record.id);
      setState(() {
        _records.remove(record);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical record deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting medical record: $e')),
        );
      }
    }
  }

  void _showEditDialog(MedicalRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MedicalRecordDetails(record: record),
        fullscreenDialog: true,
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'surgery':
        return Colors.red;
      case 'diagnosis':
        return Colors.orange;
      case 'vaccination':
        return Colors.green;
      case 'medication':
        return Colors.blue;
      case 'test':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'surgery':
        return Icons.medical_services;
      case 'diagnosis':
        return Icons.medical_information;
      case 'vaccination':
        return Icons.vaccines;
      case 'medication':
        return Icons.medication;
      case 'test':
        return Icons.science;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.medical_information_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No medical records yet',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MedicalRecordForm(),
                    fullscreenDialog: true,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Record'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final isFirst = index == 0;
        final isLast = index == _records.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(record.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      DateFormat('dd').format(record.date),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      DateFormat('yyyy').format(record.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 2,
                    height: 24,
                    color: isFirst
                        ? Colors.transparent
                        : Theme.of(context).dividerColor,
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getTypeColor(record.type),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: isLast
                        ? Colors.transparent
                        : Theme.of(context).dividerColor,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: InkWell(
                    onTap: () => _showEditDialog(record),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getTypeIcon(record.type),
                                color: _getTypeColor(record.type),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                record.type,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: _getTypeColor(record.type),
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteRecord(record),
                                tooltip: 'Delete Record',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            record.title,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (record.doctorName != null ||
                              record.hospitalName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              [
                                if (record.doctorName != null)
                                  'Dr. ${record.doctorName}',
                                if (record.hospitalName != null)
                                  record.hospitalName,
                              ].join(' • '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (record.prescriptions.isNotEmpty ||
                              record.reports.isNotEmpty ||
                              record.attachments.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (record.prescriptions.isNotEmpty)
                                  Chip(
                                    avatar: const Icon(Icons.medication_outlined, size: 16),
                                    label: Text('${record.prescriptions.length} Prescriptions'),
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: Colors.blue),
                                  ),
                                if (record.reports.isNotEmpty)
                                  Chip(
                                    avatar: const Icon(Icons.description_outlined, size: 16),
                                    label: Text('${record.reports.length} Reports'),
                                    backgroundColor: Colors.green.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: Colors.green),
                                  ),
                                if (record.attachments.isNotEmpty)
                                  Chip(
                                    avatar: const Icon(Icons.attachment_outlined, size: 16),
                                    label: Text('${record.attachments.length} Attachments'),
                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                    labelStyle: const TextStyle(color: Colors.orange),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 