import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/medical_record.dart';
import '../widgets/medical_timeline.dart';
import '../widgets/medical_record_form.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/emergency_contacts_dialog.dart';
import '../widgets/medical_conditions_dialog.dart';
import '../services/user_profile_service.dart';
import '../services/medical_records_service.dart';

class HealthCardScreen extends StatefulWidget {
  const HealthCardScreen({super.key});

  @override
  State<HealthCardScreen> createState() => _HealthCardScreenState();
}

class _HealthCardScreenState extends State<HealthCardScreen> {
  late final UserProfileService _userProfileService;
  final _recordsService = MedicalRecordsService();
  Map<String, dynamic>? _userProfile;
  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  late Stream<Map<String, dynamic>?> _profileStream;
  late Stream<List<MedicalRecord>> _recordsStream;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _userProfileService = await UserProfileService.create();
    _profileStream = _userProfileService.getUserProfileStream();
    _recordsStream = _recordsService.getRecordsStream();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final profile = await _userProfileService.getUserProfile();
      final records = await _recordsService.getRecords();
      setState(() {
        _userProfile = profile;
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _exportToPDF() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();
      
      // Add a default font
      final font = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();
      
      // Cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Medical Health Card',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 28,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Confidential Medical Information',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  _userProfile?['name'] ?? 'N/A',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 24,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Profile Information
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Personal Information',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  children: _buildPdfTableRows(font),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Emergency Contacts',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._buildEmergencyContactsList(font),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Medical Conditions',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._buildMedicalConditionsList(font),
              ],
            );
          },
        ),
      );

      // Medical Records
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Medical History',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 20,
                  ),
                ),
                pw.SizedBox(height: 20),
                ..._buildMedicalRecordsList(font),
              ],
            );
          },
        ),
      );

      // Save and share PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/health_card_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'health_card.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<pw.TableRow> _buildPdfTableRows(pw.Font font) {
    return [
      _buildPdfTableRow('Name', _userProfile?['name'] ?? 'N/A', font),
      _buildPdfTableRow('Age', _userProfile?['age']?.toString() ?? 'N/A', font),
      _buildPdfTableRow('Gender', _userProfile?['gender'] ?? 'N/A', font),
      _buildPdfTableRow('Blood Group', _userProfile?['bloodGroup'] ?? 'N/A', font),
    ];
  }

  pw.TableRow _buildPdfTableRow(String label, String value, pw.Font font) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: font, fontSize: 12),
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _buildEmergencyContactsList(pw.Font font) {
    final contacts = _userProfile?['emergencyContacts'] as List? ?? [];
    if (contacts.isEmpty) {
      return [
        pw.Text(
          'No emergency contacts added',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
        ),
      ];
    }

    return contacts.map((contact) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              contact['name'] ?? 'N/A',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.Text(
              'Relationship: ${contact['relationship'] ?? 'N/A'}',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Phone: ${contact['phone'] ?? 'N/A'}',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<pw.Widget> _buildMedicalConditionsList(pw.Font font) {
    final conditions = _userProfile?['medicalConditions'] as List? ?? [];
    if (conditions.isEmpty) {
      return [
        pw.Text(
          'No medical conditions recorded',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
        ),
      ];
    }

    return conditions.map((condition) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Text(
          '• ${condition['condition'] ?? 'N/A'}',
          style: pw.TextStyle(font: font, fontSize: 12),
        ),
      );
    }).toList();
  }

  List<pw.Widget> _buildMedicalRecordsList(pw.Font font) {
    if (_records.isEmpty) {
      return [
        pw.Text(
          'No medical records available',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700),
        ),
      ];
    }

    return _records.map((record) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              record.title,
              style: pw.TextStyle(font: font, fontSize: 14),
            ),
            pw.Text(
              DateFormat('MMM dd, yyyy').format(record.date),
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Type: ${record.type}',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
            ),
            if (record.doctorName != null)
              pw.Text(
                'Doctor: ${record.doctorName}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
            if (record.hospitalName != null)
              pw.Text(
                'Hospital: ${record.hospitalName}',
                style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
              ),
            pw.SizedBox(height: 5),
            pw.Text(
              record.description,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showAddRecordDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MedicalRecordForm(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(userProfile: _userProfile!),
    ).then((_) => _loadInitialData());
  }

  void _showEmergencyContactsDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => EmergencyContactsDialog(
        contacts: List<Map<String, dynamic>>.from(
            _userProfile!['emergencyContacts'] ?? []),
      ),
    ).then((_) => _loadInitialData());
  }

  void _showMedicalConditionsDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => MedicalConditionsDialog(
        allergies: List<String>.from(_userProfile!['allergies'] ?? []),
        conditions: List<String>.from(_userProfile!['medicalConditions'] ?? []),
      ),
    ).then((_) => _loadInitialData());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final bloodGroup = _userProfile?['bloodGroup'] ?? 'Not Set';
    final allergies = List<String>.from(_userProfile?['allergies'] ?? []);
    final medicalConditions = List<String>.from(_userProfile?['medicalConditions'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?['name'] ?? 'N/A',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Age: ${_userProfile?['age'] ?? 'N/A'} • Blood Group: $bloodGroup',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _showEditProfileDialog,
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_hospital, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Emergency Contacts',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _showEmergencyContactsDialog,
                        tooltip: 'Manage Emergency Contacts',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_userProfile?['emergencyContacts'] == null ||
                      (_userProfile!['emergencyContacts'] as List).isEmpty)
                    Text(
                      'No emergency contacts set',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var contact
                            in _userProfile!['emergencyContacts'] as List)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact['name'] ?? '',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${contact['number'] ?? ''} • ${contact['relationship'] ?? ''}',
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_information, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Medical Conditions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _showMedicalConditionsDialog,
                        tooltip: 'Manage Medical Conditions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (allergies.isEmpty && medicalConditions.isEmpty)
                    Text(
                      'No medical conditions or allergies recorded',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allergies',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allergies.isEmpty
                              ? [
                                  Chip(
                                    label: const Text('None'),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.secondary,
                                    ),
                                  )
                                ]
                              : allergies.map<Widget>((allergy) {
                                  return Chip(
                                    label: Text(allergy),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Conditions',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: medicalConditions.isEmpty
                              ? [
                                  Chip(
                                    label: const Text('None'),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.secondary,
                                    ),
                                  )
                                ]
                              : medicalConditions.map<Widget>((condition) {
                                  return Chip(
                                    label: Text(condition),
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    labelStyle: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                }).toList(),
                        ),
                      ],
                    ),
                  if (_userProfile?['qrData'] != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Center(
                      child: QrImageView(
                        data: _userProfile!['qrData'],
                        version: QrVersions.auto,
                        size: 150.0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medical Timeline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showAddRecordDialog,
                tooltip: 'Add Medical Record',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MedicalTimeline(),
        ],
      ),
    );
  }
} 