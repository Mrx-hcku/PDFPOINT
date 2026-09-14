import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../pdf_viewer_screen.dart';

class DownloadsTab extends StatefulWidget {
  const DownloadsTab({super.key});

  @override
  State<DownloadsTab> createState() => _DownloadsTabState();
}

class _DownloadsTabState extends State<DownloadsTab> {
  List<File> _files = [];
  bool _isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _isLoading = true;
      errorMessage = null;
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final entities = dir.listSync();
      final pdfFiles = entities
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList();

      // Most recently downloaded first
      pdfFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      setState(() {
        _files = pdfFiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        errorMessage = "Could not read downloads folder:\n$e";
      });
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadDownloads();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not delete file: $e")),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _titleFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    return name.replaceAll('.pdf', '').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Offline Downloads",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
                    onPressed: _loadDownloads,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "PDFs actually saved on this device",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 20),

              if (errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F1D1D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : _files.isEmpty
                        ? const Center(
                            child: Text(
                              "No PDFs downloaded yet.",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDownloads,
                            color: const Color(0xFF6366F1),
                            child: ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final file = _files[index];
                                final title = _titleFromPath(file.path);
                                int size = 0;
                                try {
                                  size = file.lengthSync();
                                } catch (_) {}

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF334155)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Size: ${_formatSize(size)} | Ready Offline",
                                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF6366F1),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PdfViewerScreen(
                                                    pdfTitle: title,
                                                    localFilePath: file.path,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text("Open", style: TextStyle(color: Colors.white, fontSize: 11)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                            onPressed: () => _deleteFile(file),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
