import 'package:file_picker/file_picker.dart';
import 'package:fixify_admin/screens/auth/docuent_submitted_screen.dart';
import 'package:flutter/material.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  // store picked file names (or null if not picked)
  String? _aadhaarFile;
  String? _addressFile;
  String? _licenseFile;

  bool _isSubmitting = false;

  static const Color _green = Color(0xFF2F6F3E);
  static const Color _lightGreen = Color(0xFFE6F6E7);

  Future<void> _pickFileFor(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final fileName = result.files.single.name;

    setState(() {
      if (type == 'aadhaar') {
        _aadhaarFile = fileName;
      } else if (type == 'address') {
        _addressFile = fileName;
      } else if (type == 'license') {
        _licenseFile = fileName;
      }
    });
  }

  bool get _canSubmit =>
      _aadhaarFile != null && _addressFile != null; // license is optional

  Future<void> _submit() async {
    if (_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload Aadhaar Card and Address Proof before submitting.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // just for feel, no API
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentsSubmittedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: _lightGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Documents',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(height: 24, width: double.infinity, color: _lightGreen),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  _buildInstructionCard(),
                  const SizedBox(height: 20),
                  _buildDocumentSection(
                    title: 'Aadhaar Card',
                    hint: 'JPG, PNG, PDF',
                    selectedFile: _aadhaarFile,
                    onUpload: () => _pickFileFor('aadhaar'),
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentSection(
                    title: 'Address Proof',
                    hint: 'JPG, PNG, PDF',
                    selectedFile: _addressFile,
                    onUpload: () => _pickFileFor('address'),
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentSection(
                    title: 'Service License (if applicable)',
                    hint: 'JPG, PNG, PDF',
                    selectedFile: _licenseFile,
                    onUpload: () => _pickFileFor('license'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canSubmit ? _green : _green.withOpacity(0.5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Submit Documents'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instruction',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          _BulletText('Maximum file size: 25 MB per document'),
          SizedBox(height: 4),
          _BulletText('Supported formats: JPG, PNG, PDF'),
          SizedBox(height: 4),
          _BulletText('Make sure documents are clear and readable'),
          SizedBox(height: 4),
          _BulletText('Avoid blurry or low-resolution images'),
        ],
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required String hint,
    required String? selectedFile,
    required VoidCallback onUpload,
  }) {
    const Color fieldBg = Color(0xFFF7F8FA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 10, right: 10),
                  height: 44,
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedFile ?? hint,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          selectedFile == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                margin: const EdgeInsets.only(right: 10),
                height: 36,
                width: 86,
                child: ElevatedButton(
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Upload'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14, height: 1.4)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
