import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<String> uploadFile(File file, String type) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    debugPrint('Starting file upload process...');
    debugPrint('User ID: $_userId');
    debugPrint('File type: $type');
    debugPrint('File path: ${file.path}');

    // Ensure type is sanitized for storage path
    final sanitizedType = type.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    
    // Create a unique filename with timestamp to avoid collisions
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String fileName = '${_uuid.v4()}_${timestamp}${path.extension(file.path)}';
    
    // Construct the storage path
    final String filePath = 'medical_records/$_userId/$sanitizedType/$fileName';
    debugPrint('Storage path: $filePath');

    try {
      debugPrint('Attempting to upload file to Supabase...');
      
      // Upload the file to Supabase Storage
      final response = await _supabase
          .storage
          .from('medical-files')
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(
              contentType: _getContentType(fileName),
              upsert: true,
            ),
          );

      debugPrint('Upload response: $response');

      // Get the public URL for the uploaded file
      final String publicUrl = _supabase
          .storage
          .from('medical-files')
          .getPublicUrl(filePath);

      debugPrint('Generated public URL: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint('Error in uploadFile: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (e is StorageException) {
        debugPrint('Storage error details:');
        debugPrint('Message: ${e.message}');
        debugPrint('Status Code: ${e.statusCode}');
        
        if (e.statusCode == '404') {
          throw Exception('Storage bucket not found. Please check Supabase Storage configuration.');
        } else if (e.statusCode == '403') {
          throw Exception('Permission denied. Please check storage policies.');
        }
      }
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
      debugPrint('Attempting to delete file: $fileUrl');
      
      // Extract the path from the URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index of 'medical-files' in the path
      final medicalFilesIndex = pathSegments.indexOf('medical-files');
      if (medicalFilesIndex == -1) {
        throw Exception('Invalid file URL structure');
      }
      
      // Get the path after 'medical-files'
      final filePath = pathSegments.sublist(medicalFilesIndex + 1).join('/');
      debugPrint('Extracted file path: $filePath');

      await _supabase
          .storage
          .from('medical-files')
          .remove([filePath]);
          
      debugPrint('File deleted successfully');
    } catch (e, stackTrace) {
      debugPrint('Error in deleteFile: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error deleting file: $e');
    }
  }

  Future<Map<String, String>> getFileMetadata(String fileUrl) async {
    if (_userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      debugPrint('Getting metadata for file: $fileUrl');
      
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      
      final metadata = {
        'name': fileName,
        'contentType': _getContentType(fileName),
        'size': 'Unknown', // Supabase doesn't provide size in metadata
        'timeCreated': DateTime.now().toIso8601String(), // Supabase doesn't provide creation time
      };
      
      debugPrint('Generated metadata: $metadata');
      return metadata;
    } catch (e, stackTrace) {
      debugPrint('Error in getFileMetadata: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error getting file metadata: $e');
    }
  }

  String getFileNameFromUrl(String fileUrl) {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      return pathSegments.last.split('?').first;
    } catch (e) {
      debugPrint('Error getting filename from URL: $e');
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