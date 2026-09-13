import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? statusMessage;
  bool isError = false;

  Future<void> _openOnline() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        setState(() {
          isError = true;
          statusMessage = "Could not open the PDF link. No app available to view it.";
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        statusMessage = describeError(e);
      });
    }
  }

  Future<void> _downloadToDevice() async {
    setState(() {
      _isDownloading = true;
      statusMessage = null;
    });
    try {
      final response = await http
          .get(Uri.parse(widget.pdfUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final safeName = widget.pdfTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
        final file = File('${dir.path}/$safeName.pdf');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _isDownloading = false;
          isError = false;
          statusMessage = "Downloaded successfully to app storage:\n${file.path}";
        });
      } else {
        setState(() {
          _isDownloading = false;
          isError = true;
          statusMessage = "SERVER ERROR (HTTP ${response.statusCode})\nCould not download the file.";
        });
      }
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

              // ---- Read online (opens in browser/PDF app) ----
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _openOnline,
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text("Read PDF", style: TextStyle(color: Colors.white)),
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
                  onPressed: _isDownloading ? null : _downloadToDevice,
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
