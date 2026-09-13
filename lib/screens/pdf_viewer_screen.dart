import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import '../utils/error_helper.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfTitle;
  final String pdfUrl;
  const PdfViewerScreen({super.key, required this.pdfTitle, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? statusMessage;
  bool isError = false;

  final Dio _dio = Dio();

  // Helper to get local file path if already downloaded
  Future<String?> _getLocalFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = widget.pdfTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
    final savePath = '${dir.path}/$safeName.pdf';
    if (await File(savePath).exists()) {
      return savePath;
    }
    return null;
  }

  // Open inside app using flutter_pdfview
  Future<void> _openInAppViewer() async {
    String? localPath = await _getLocalFilePath();

    if (localPath == null) {
      // If not downloaded yet, download it first temporarily or prompt download
      await _downloadToDevice(openAfterDownload: true);
    } else {
      _navigateToViewer(localPath);
    }
  }

  void _navigateToViewer(String localPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalPdfScreen(pdfPath: localPath, pdfTitle: widget.pdfTitle),
      ),
    );
  }

  Future<void> _downloadToDevice({bool openAfterDownload = false}) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      statusMessage = null;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.pdfTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
      final savePath = '${dir.path}/$safeName.pdf';

      await _dio.download(
        widget.pdfUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      setState(() {
        _isDownloading = false;
        isError = false;
        statusMessage = "Downloaded successfully to app storage:\n$savePath";
      });

      if (openAfterDownload) {
        _navigateToViewer(savePath);
      }
    } on DioException catch (e) {
      setState(() {
        _isDownloading = false;
        isError = true;
        if (e.response != null) {
          statusMessage = "SERVER ERROR (HTTP ${e.response!.statusCode})\nCould not download the file.";
        } else {
          statusMessage = describeError(e.error ?? e);
        }
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
        isError = true;
        statusMessage = describeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(widget.pdfTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 64),
              const SizedBox(height: 16),
              Text(
                widget.pdfTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // ---- Read In-App using flutter_pdfview ----
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isDownloading ? null : _openInAppViewer,
                  icon: const Icon(Icons.menu_book, color: Colors.white),
                  label: const Text("Read PDF In-App", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),

              // ---- Download to device storage ----
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isDownloading ? null : () => _downloadToDevice(openAfterDownload: false),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.download, color: Colors.white),
                  label: Text(
                    _isDownloading ? "Downloading..." : "Download PDF",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              // ---- Download progress bar ----
              if (_isDownloading) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _downloadProgress > 0 ? _downloadProgress : null,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF334155),
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${(_downloadProgress * 100).toStringAsFixed(0)}% downloaded",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],

              if (statusMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isError ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    statusMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- Separate Screen to Render PDF Locally ---
class LocalPdfScreen extends StatefulWidget {
  final String pdfPath;
  final String pdfTitle;
  const LocalPdfScreen({super.key, required this.pdfPath, required this.pdfTitle});

  @override
  State<LocalPdfScreen> createState() => _LocalPdfScreenState();
}

class _LocalPdfScreenState extends State<LocalPdfScreen> {
  int? _totalPages = 0;
  int? _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(widget.pdfTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_totalPages != null && _isReady)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "${(_currentPage ?? 0) + 1} / $_totalPages",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            onRender: (pages) {
              setState(() {
                _totalPages = pages;
                _isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                _errorMessage = '$page: ${error.toString()}';
              });
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page;
              });
            },
          ),
          if (!_isReady && _errorMessage.isEmpty)
            const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Error loading PDF:\n$_errorMessage",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
