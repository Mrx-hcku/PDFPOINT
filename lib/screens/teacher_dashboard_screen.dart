import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'utils/error_helper.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  // ---- NEW BACKEND URL ----
  final String baseUrl = 'https://pdfbck-1.onrender.com';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isPaid = false;
  bool _followRequired = false;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? errorBanner; // holds detailed error text if something fails

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _uploadMaterial() async {
    if (_selectedFile == null || _titleController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select a PDF file")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      errorBanner = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload'),
      );

      request.fields['title'] = _titleController.text;
      request.fields['author'] = _authorController.text;
      request.fields['isPaid'] = _isPaid.toString();
      request.fields['price'] = _isPaid ? _priceController.text : 'Free';
      request.fields['followRequired'] = _followRequired.toString();

      request.files.add(
        http.MultipartFile.fromBytes(
          'pdf',
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      setState(() {
        _isUploading = false;
      });

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PDF uploaded successfully to Telegram & MongoDB!")),
        );
        Navigator.pop(context);
      } else {
        setState(() {
          errorBanner = "SERVER ERROR (HTTP ${response.statusCode})\n"
              "Body: ${response.body}\n"
              "→ Likely cause: backend /api/upload threw an error (check Telegram bot token / Mongo connection on server logs).";
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        errorBanner = describeError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Instructor Studio - Upload", style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ---- Detailed error banner: shows exact error type + reason ----
            if (errorBanner != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  errorBanner!,
                  style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
                ),
              ),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "PDF Title",
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Author / Instructor Name",
                labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text("Is Paid Content?", style: TextStyle(color: Colors.white)),
              value: _isPaid,
              onChanged: (val) => setState(() => _isPaid = val),
              activeColor: const Color(0xFF6366F1),
            ),
            if (_isPaid) ...[
              TextField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Price (e.g., Rs. 149)",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              title: const Text("Require Follow to Unlock", style: TextStyle(color: Colors.white)),
              value: _followRequired,
              onChanged: (val) => setState(() => _followRequired = val),
              activeColor: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155)),
              onPressed: _pickPDF,
              icon: const Icon(Icons.attach_file, color: Colors.white),
              label: Text(
                _selectedFile == null ? "Select PDF File" : "Selected: ${_selectedFile!.name}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isUploading ? null : _uploadMaterial,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Upload to Telegram Storage", style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
