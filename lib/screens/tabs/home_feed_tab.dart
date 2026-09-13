import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../pdf_viewer_screen.dart';
import '../utils/error_helper.dart';

class HomeFeedTab extends StatefulWidget {
  const HomeFeedTab({super.key});

  @override
  State<HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<HomeFeedTab> {
  final String baseUrl = 'https://pdfbck-1.onrender.com';

  List<dynamic> pdfItems = [];
  List<String> teachers = [];
  String? selectedTeacher; // null = "All" (full feed)
  bool isLoading = true;
  bool isLoadingTeachers = true;
  String? errorBanner;

  @override
  void initState() {
    super.initState();
    fetchTeachers();
    fetchMaterials();
  }

  Future<void> fetchTeachers() async {
    setState(() => isLoadingTeachers = true);
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/teachers'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          teachers = List<String>.from(data['data'] ?? []);
          isLoadingTeachers = false;
        });
      } else {
        setState(() => isLoadingTeachers = false);
      }
    } catch (e) {
      // Non-fatal: feed can still work without the suggestions row.
      setState(() => isLoadingTeachers = false);
    }
  }

  Future<void> fetchMaterials({String? author}) async {
    setState(() {
      isLoading = true;
      errorBanner = null;
    });
    try {
      final uri = author == null
          ? Uri.parse('$baseUrl/api/materials')
          : Uri.parse('$baseUrl/api/materials?author=${Uri.encodeComponent(author)}');

      final response = await http.get(uri).timeout(const Duration(seconds: 20));

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
              "Body: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorBanner = describeError(e);
      });
    }
  }

  void _selectTeacher(String? teacher) {
    setState(() => selectedTeacher = teacher);
    fetchMaterials(author: teacher);
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

  Color _avatarColor(String seed) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
    ];
    final index = seed.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[index];
  }

  Widget _buildSuggestedTeachersRow() {
    if (isLoadingTeachers) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2)),
      );
    }
    if (teachers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _teacherChip(null, "All"),
          ...teachers.map((t) => _teacherChip(t, t)),
        ],
      ),
    );
  }

  Widget _teacherChip(String? teacherKey, String label) {
    final bool selected = selectedTeacher == teacherKey;
    return GestureDetector(
      onTap: () => _selectTeacher(teacherKey),
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: selected ? const Color(0xFF6366F1) : _avatarColor(label),
              child: Text(
                label.isNotEmpty ? label[0].toUpperCase() : "?",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedPost(dynamic item) {
    final bool isPaid = item["isPaid"] ?? false;
    final String author = item['author'] ?? 'Unknown';
    final String category = item['category'] ?? 'General';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Post header: teacher avatar + name (Facebook-style) ----
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _avatarColor(author),
                  child: Text(
                    author.isNotEmpty ? author[0].toUpperCase() : "?",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        "shared new material in $category",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF334155)),

          // ---- Post body ----
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["title"] ?? "Untitled",
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Size: ${item['fileSize'] ?? 'N/A'}",
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => handleDownloadOrRead(item["_id"], item["title"]),
                  child: const Text("Read / Download", style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      fetchTeachers();
                      fetchMaterials(author: selectedTeacher);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ---- Suggested Teachers row ----
              const Text(
                "Suggested Teachers",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              _buildSuggestedTeachersRow(),
              const SizedBox(height: 8),

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

              // ---- Feed ----
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
                        : RefreshIndicator(
                            onRefresh: () => fetchMaterials(author: selectedTeacher),
                            color: const Color(0xFF6366F1),
                            child: ListView.builder(
                              itemCount: pdfItems.length,
                              itemBuilder: (context, index) => _buildFeedPost(pdfItems[index]),
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
