import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medical_record.dart';

class MedicalRecordsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _recordsCollection =>
      _firestore.collection('users').doc(_userId).collection('medical_records');

  Future<MedicalRecord> addFileToRecord(
    String recordId,
    String fileUrl,
    String type,
  ) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final recordRef = _recordsCollection.doc(recordId);
    final record = await recordRef.get();

    if (!record.exists) {
      throw Exception('Record not found');
    }

    final data = record.data()!;
    final List<dynamic> files = List.from(data[type] ?? []);
    files.add({
      'fileUrl': fileUrl,
      'uploadedAt': DateTime.now().toIso8601String(),
    });

    await recordRef.update({type: files});
    final updatedRecord = await recordRef.get();
    return MedicalRecord.fromFirestore(updatedRecord);
  }

  Future<MedicalRecord> removeFileFromRecord(
    String recordId,
    String fileUrl,
    String type,
  ) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final recordRef = _recordsCollection.doc(recordId);
    final record = await recordRef.get();

    if (!record.exists) {
      throw Exception('Record not found');
    }

    final data = record.data()!;
    final List<dynamic> files = List.from(data[type] ?? []);
    files.removeWhere((file) => file['fileUrl'] == fileUrl);

    await recordRef.update({type: files});
    final updatedRecord = await recordRef.get();
    return MedicalRecord.fromFirestore(updatedRecord);
  }

  CollectionReference<Map<String, dynamic>> _getRecordsRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medical_records');
  }

  Stream<List<MedicalRecord>> getRecordsStream() {
    return _getRecordsRef()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MedicalRecord.fromFirestore(doc))
            .toList());
  }

  Future<List<MedicalRecord>> getRecords() async {
    final snapshot = await _getRecordsRef()
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => MedicalRecord.fromFirestore(doc))
        .toList();
  }

  Future<void> addRecord(MedicalRecord record) async {
    await _getRecordsRef().add(record.toFirestore());
  }

  Future<void> updateRecord(MedicalRecord record) async {
    await _getRecordsRef().doc(record.id).update(record.toFirestore());
  }

  Future<void> deleteRecord(String recordId) async {
    await _getRecordsRef().doc(recordId).delete();
  }

  Future<void> reorderRecords(List<MedicalRecord> records) async {
    final batch = _firestore.batch();
    final recordsRef = _getRecordsRef();

    for (var i = 0; i < records.length; i++) {
      final record = records[i];
      batch.update(recordsRef.doc(record.id), {'order': i});
    }

    await batch.commit();
  }

  Future<void> addAttachment(String recordId, String attachmentUrl) async {
    await _getRecordsRef().doc(recordId).update({
      'attachments': FieldValue.arrayUnion([attachmentUrl]),
    });
  }

  Future<void> removeAttachment(String recordId, String attachmentUrl) async {
    await _getRecordsRef().doc(recordId).update({
      'attachments': FieldValue.arrayRemove([attachmentUrl]),
    });
  }

  Future<void> updateAdditionalInfo(
      String recordId, Map<String, dynamic> info) async {
    await _getRecordsRef().doc(recordId).update({
      'additionalInfo': info,
    });
  }
} 