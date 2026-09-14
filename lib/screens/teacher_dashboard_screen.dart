import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'utils/error_helper.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  // ---- Backend URL ----
  final String baseUrl = 'https://pdfbck-1.onrender.com';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  bool _isPaid = false;
  bool _followRequired = false;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0; // 0.0 to 1.0
  String? errorBanner;

  List<String> _existingCategories = [];
  String? _selectedCategory;
  bool _isAddingNewCategory = false;
  bool _isLoadingCategories = true;

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final response = await _dio
          .get('$baseUrl/api/categories')
          .timeout(const Duration(seconds: 15));
      final List<dynamic> data = response.data['data'] ?? [];
      setState(() {
        _existingCategories = data.map((e) => e.toString()).toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      // Non-fatal: user can still type a brand-new category even if this fails.
      setState(() => _isLoadingCategories = false);
    }
  }

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
    final String? finalCategory =
        _isAddingNewCategory ? _newCategoryController.text.trim() : _selectedCategory;

    if (_selectedFile == null ||
        _titleController.text.isEmpty ||
        _authorController.text.isEmpty ||
        finalCategory == null ||
        finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields, pick/type a category, and select a PDF file")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      errorBanner = null;
    });

    try {
      final formData = FormData.fromMap({
        'title': _titleController.text,
        'author': _authorController.text,
        'category': finalCategory,
        'isPaid': _isPaid.toString(),
        'price': _isPaid ? _priceController.text : 'Free',
        'followRequired': _followRequired.toString(),
        'pdf': await MultipartFile.fromBytes(
          _selectedFile!.bytes!,
          filename: _selectedFile!.name,
        ),
      });

      final response = await _dio.post(
        '$baseUrl/api/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
        options: Options(sendTimeout: const Duration(seconds: 120), receiveTimeout: const Duration(seconds: 60)),
      );

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
              "Body: ${response.data}\n"
              "→ Likely cause: backend /api/upload threw an error (check Telegram bot token / Mongo connection on server logs).";
        });
      }
    } on DioException catch (e) {
      setState(() {
        _isUploading = false;
        if (e.response != null) {
          errorBanner = "SERVER ERROR (HTTP ${e.response!.statusCode})\nBody: ${e.response!.data}";
        } else {
          errorBanner = describeError(e.error ?? e);
        }
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        errorBanner = describeError(e);
      });
    }
  }

  Widget _buildCategorySelector() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Category", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._existingCategories.map((cat) {
              final bool selected = !_isAddingNewCategory && _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = cat;
                    _isAddingNewCategory = false;
                  });
                },
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF1E293B),
                labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF94A3B8)),
              );
            }),
            ChoiceChip(
              label: const Text("+ New Category"),
              selected: _isAddingNewCategory,
              onSelected: (_) {
                setState(() {
                  _isAddingNewCategory = true;
                  _selectedCategory = null;
                });
              },
              selectedColor: const Color(0xFF6366F1),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(color: _isAddingNewCategory ? Colors.white : const Color(0xFF94A3B8)),
            ),
          ],
        ),
        if (_isAddingNewCategory) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _newCategoryController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "New category name",
              labelStyle: TextStyle(color: Color(0xFF94A3B8)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF334155))),
            ),
          ),
        ],
      ],
    );
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
            _buildCategorySelector(),
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

            // ---- Upload progress bar ----
            if (_isUploading) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFF334155),
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${(_uploadProgress * 100).toStringAsFixed(0)}% uploaded",
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isUploading ? null : _uploadMaterial,
              child: _isUploading
                  ? const Text("Uploading...", style: TextStyle(color: Colors.white, fontSize: 15))
                  : const Text("Upload to Telegram Storage", style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
