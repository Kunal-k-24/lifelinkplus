import 'package:cloud_firestore/cloud_firestore.dart';

class FileData {
  final String fileUrl;
  final DateTime uploadedAt;

  FileData({
    required this.fileUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory FileData.fromMap(Map<String, dynamic> map) {
    return FileData(
      fileUrl: map['fileUrl'] as String,
      uploadedAt: DateTime.parse(map['uploadedAt'] as String),
    );
  }
}

class MedicalRecord {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // e.g., 'surgery', 'diagnosis', 'vaccination', etc.
  final String? doctorName;
  final String? hospitalName;
  final List<FileData> prescriptions;
  final List<FileData> reports;
  final List<String> attachments;
  final Map<String, dynamic>? additionalInfo;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.doctorName,
    this.hospitalName,
    List<FileData>? prescriptions,
    List<FileData>? reports,
    List<String>? attachments,
    this.additionalInfo,
  })  : prescriptions = prescriptions ?? [],
        reports = reports ?? [],
        attachments = attachments ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'prescriptions': prescriptions.map((p) => p.toMap()).toList(),
      'reports': reports.map((r) => r.toMap()).toList(),
      'attachments': attachments,
      'additionalInfo': additionalInfo,
    };
  }

  factory MedicalRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return MedicalRecord(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      date: DateTime.parse(data['date'] as String),
      type: data['type'] as String,
      doctorName: data['doctorName'] as String?,
      hospitalName: data['hospitalName'] as String?,
      prescriptions: (data['prescriptions'] as List<dynamic>?)
              ?.map((p) => FileData.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      reports: (data['reports'] as List<dynamic>?)
              ?.map((r) => FileData.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      attachments: List<String>.from(data['attachments'] ?? []),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  MedicalRecord copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? type,
    String? doctorName,
    String? hospitalName,
    List<FileData>? prescriptions,
    List<FileData>? reports,
    List<String>? attachments,
    Map<String, dynamic>? additionalInfo,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      prescriptions: prescriptions ?? this.prescriptions,
      reports: reports ?? this.reports,
      attachments: attachments ?? this.attachments,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

class Prescription {
  final String medication;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? instructions;
  final bool isActive;

  Prescription({
    required this.medication,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'medication': medication,
    'dosage': dosage,
    'frequency': frequency,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'instructions': instructions,
    'isActive': isActive,
  };

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      medication: map['medication'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      instructions: map['instructions'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}

class Report {
  final String title;
  final String type; // e.g., 'blood_test', 'x_ray', 'mri', etc.
  final DateTime date;
  final String? findings;
  final String? conclusion;
  final Map<String, dynamic>? parameters; // For test results with specific parameters
  final List<String> attachments; // URLs to report files

  Report({
    required this.title,
    required this.type,
    required this.date,
    this.findings,
    this.conclusion,
    this.parameters,
    this.attachments = const [],
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'type': type,
    'date': Timestamp.fromDate(date),
    'findings': findings,
    'conclusion': conclusion,
    'parameters': parameters,
    'attachments': attachments,
  };

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      title: map['title'] as String,
      type: map['type'] as String,
      date: (map['date'] as Timestamp).toDate(),
      findings: map['findings'] as String?,
      conclusion: map['conclusion'] as String?,
      parameters: map['parameters'] as Map<String, dynamic>?,
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }
} 