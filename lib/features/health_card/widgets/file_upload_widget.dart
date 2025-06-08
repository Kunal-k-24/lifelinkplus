import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/file_service.dart';
import 'file_viewer.dart';

class FileUploadWidget extends StatefulWidget {
  final List<String> files;
  final String type;
  final Function(String) onFileUploaded;
  final Function(String) onFileDeleted;

  const FileUploadWidget({
    super.key,
    required this.files,
    required this.type,
    required this.onFileUploaded,
    required this.onFileDeleted,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final FileService _fileService = FileService();
  bool _isUploading = false;

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        
        final file = File(result.files.single.path!);
        final url = await _fileService.uploadFile(file, widget.type);
        widget.onFileUploaded(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        
        final file = File(image.path);
        final url = await _fileService.uploadFile(file, widget.type);
        widget.onFileUploaded(url);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteFile(String fileUrl) async {
    try {
      await _fileService.deleteFile(fileUrl);
      widget.onFileDeleted(fileUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }

  Widget _buildFilePreview(String fileUrl) {
    final fileName = _fileService.getFileNameFromUrl(fileUrl);
    final isImage = _fileService.isImageFile(fileName);
    final isPdf = _fileService.isPdfFile(fileName);

    return FutureBuilder<Map<String, String>>(
      future: _fileService.getFileMetadata(fileUrl),
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        final uploadDate = metadata != null
            ? DateFormat.yMMMd().add_jm().format(
                DateTime.parse(metadata['timeCreated'] ?? ''),
              )
            : null;

        return Card(
          child: ListTile(
            leading: Icon(
              isImage ? Icons.image : (isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file),
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: uploadDate != null
                ? Text(
                    'Uploaded on $uploadDate',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteFile(fileUrl),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FileViewer(fileUrl: fileUrl),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isUploading)
          const LinearProgressIndicator()
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload File'),
              ),
              ElevatedButton.icon(
                onPressed: _pickAndUploadImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ],
          ),
        const SizedBox(height: 16),
        if (widget.files.isEmpty)
          Center(
            child: Text(
              'No files uploaded yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          )
        else
          ...widget.files.map(_buildFilePreview).toList(),
      ],
    );
  }
} 