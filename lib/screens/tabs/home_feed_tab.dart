import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../pdf_viewer_screen.dart';
import '../utils/error_helper.dart';

class HomeFeedTab extends StatefulWidget {
  const HomeFeedTab({super.key});

  @override
  State<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<HomeFeedTab> {
  // ---- NEW BACKEND URL ----
  final String baseUrl = 'https://pdfbck-1.onrender.com';

  List<dynamic> pdfItems = [];
  bool isLoading = true;
  String? errorBanner; // holds detailed error text if something fails

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials() async {
    setState(() {
      isLoading = true;
      errorBanner = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/materials'))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pdfItems = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorBanner = "SERVER ERROR (HTTP ${response.statusCode})\n"
              "Body: ${response.body}\n"
              "→ Likely cause: backend endpoint /api/materials is throwing an error server-side.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorBanner = describeError(e);
      });
    }
  }

  Future<void> handleDownloadOrRead(String id, String title) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );

      final response = await http
          .get(Uri.parse('$baseUrl/api/download/$id'))
          .timeout(const Duration(seconds: 20));

      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String downloadUrl = data['downloadUrl'];

        // Open PDF Viewer with direct Telegram file link
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(pdfTitle: title, pdfUrl: downloadUrl),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not fetch file link (HTTP ${response.statusCode}): ${response.body}")),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeError(e)), duration: const Duration(seconds: 6)),
      );
    }
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
                    "Explore Materials",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
                    onPressed: fetchMaterials,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ---- Detailed error banner: shows exact error type + reason ----
              if (errorBanner != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F1D1D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    errorBanner!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                    : pdfItems.isEmpty
                        ? const Center(
                            child: Text(
                              "No materials uploaded yet.",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pdfItems.length,
                            itemBuilder: (context, index) {
                              final item = pdfItems[index];
                              final bool isPaid = item["isPaid"] ?? false;

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
                                            item["title"] ?? "Untitled",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "By ${item['author'] ?? 'Unknown'} | Size: ${item['fileSize'] ?? 'N/A'}",
                                            style: const TextStyle(
                                              color: Color(0xFF94A3B8),
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isPaid ? "Paid Content (${item['price']})" : "Free Material",
                                            style: TextStyle(
                                              color: isPaid ? const Color(0xFFFCA5A5) : const Color(0xFF34D399),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF6366F1),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => handleDownloadOrRead(item["_id"], item["title"]),
                                      child: const Text(
                                        "Read / Download",
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
