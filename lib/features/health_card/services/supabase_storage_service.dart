import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  SupabaseStorageService(this._supabase);

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<String> uploadFile(File file, String type) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    // Ensure type is sanitized for storage path
    final sanitizedType = type.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    
    // Create a unique filename with timestamp to avoid collisions
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String fileName = '${_uuid.v4()}_${timestamp}${path.extension(file.path)}';
    
    // Construct the storage path
    final String filePath = 'medical_records/$_userId/$sanitizedType/$fileName';

    try {
      // Upload the file to Supabase Storage
      final response = await _supabase
          .storage
          .from('medical-files')
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(
              contentType: _getContentType(fileName),
              upsert: false,
            ),
          );

      if (response.isEmpty) {
        throw Exception('File upload failed: Empty response');
      }

      // Get the public URL for the uploaded file
      final String publicUrl = _supabase
          .storage
          .from('medical-files')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error in uploadFile: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  String _getContentType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      // Extract the path from the URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments.sublist(pathSegments.indexOf('medical-files') + 1).join('/');

      await _supabase
          .storage
          .from('medical-files')
          .remove([filePath]);
    } catch (e) {
      throw Exception('Error deleting file: $e');
    }
  }

  Future<Map<String, String>> getFileMetadata(String fileUrl) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      
      return {
        'name': fileName,
        'contentType': _getContentType(fileName),
        'timeCreated': DateTime.now().toIso8601String(), // Supabase doesn't provide creation time
      };
    } catch (e) {
      throw Exception('Error getting file metadata: $e');
    }
  }

  String getFileNameFromUrl(String fileUrl) {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      return pathSegments.last.split('?').first;
    } catch (e) {
      return 'Unknown file';
    }
  }

  bool isImageFile(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  bool isPdfFile(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    return ext == '.pdf';
  }
} 