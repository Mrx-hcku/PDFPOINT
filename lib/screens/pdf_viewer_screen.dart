import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'utils/error_helper.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfTitle;
  final String? pdfUrl; // remote URL - will be downloaded first
  final String? localFilePath; // already on disk - renders directly, no download
  const PdfViewerScreen({super.key, required this.pdfTitle, this.pdfUrl, this.localFilePath})
      : assert(pdfUrl != null || localFilePath != null,
            'Either pdfUrl or localFilePath must be provided');

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final Dio _dio = Dio();

  // Loading / download state (for the initial fetch needed to render the PDF)
  bool _isLoading = true;
  double _progress = 0.0; // 0.0 to 1.0
  String? errorMessage;
  String? _localPath;

  // Viewer state
  PDFViewController? _pdfController;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _fetchAndPrepare();
  }

  Future<void> _fetchAndPrepare() async {
    // Already have a local file (e.g. opened from the Downloads tab) - skip network entirely.
    if (widget.localFilePath != null) {
      setState(() {
        _localPath = widget.localFilePath;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      errorMessage = null;
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safeName = widget.pdfTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_');
      final savePath = '${dir.path}/$safeName.pdf';

      await _dio.download(
        widget.pdfUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() => _progress = received / total);
          }
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      setState(() {
        _localPath = savePath;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        if (e.response != null) {
          errorMessage = "SERVER ERROR (HTTP ${e.response!.statusCode})\nCould not fetch the file.";
        } else {
          errorMessage = describeError(e.error ?? e);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        errorMessage = describeError(e);
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
        actions: [
          if (_isReady)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "${_currentPage + 1} / $_totalPages",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 56),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF334155),
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Loading PDF... ${(_progress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                onPressed: _fetchAndPrepare,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Retry", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // ---- Actual PDF rendering (native PDFium engine) ----
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
          _isReady = true;
        });
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = page ?? 0;
          _totalPages = total ?? _totalPages;
        });
      },
      onError: (error) {
        setState(() {
          errorMessage = "PDF RENDER ERROR\n$error";
        });
      },
      onViewCreated: (controller) {
        _pdfController = controller;
      },
    );
  }
}
