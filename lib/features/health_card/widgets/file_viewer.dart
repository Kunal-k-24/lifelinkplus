import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/file_service.dart';

class FileViewer extends StatefulWidget {
  final String fileUrl;

  const FileViewer({
    super.key,
    required this.fileUrl,
  });

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  final FileService _fileService = FileService();
  String? _localPdfPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_fileService.isPdfFile(_fileService.getFileNameFromUrl(widget.fileUrl))) {
      _downloadPdf();
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      final dir = await getTemporaryDirectory();
      final fileName = _fileService.getFileNameFromUrl(widget.fileUrl);
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      setState(() {
        _localPdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _fileService.getFileNameFromUrl(widget.fileUrl);
    final isImage = _fileService.isImageFile(fileName);
    final isPdf = _fileService.isPdfFile(fileName);

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement file download
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement file sharing
            },
          ),
        ],
      ),
      body: isImage
          ? PhotoView(
              imageProvider: NetworkImage(widget.fileUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            )
          : isPdf
              ? _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _localPdfPath == null
                      ? const Center(child: Text('Failed to load PDF'))
                      : PDFView(
                          filePath: _localPdfPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          pageSnap: true,
                          fitPolicy: FitPolicy.BOTH,
                          onError: (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $error')),
                            );
                          },
                        )
              : const Center(
                  child: Text(
                    'Unsupported file type',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
    );
  }
} 