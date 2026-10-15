import 'dart:io';

import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/screens/auth/docuent_submitted_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/location_provider.dart';

class UploadDocumentsScreen extends ConsumerStatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  ConsumerState<UploadDocumentsScreen> createState() =>
      _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends ConsumerState<UploadDocumentsScreen> {
  // store picked file paths (or null if not picked)
  File? _aadhaarFile;
  File? _addressFile;
  File? _licenseFile;

  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();

  static const Color _green = Color(0xFF2F6F3E);
  static const Color _lightGreen = Color(0xFFE6F6E7);

  Future<void> _showUploadOptions(String type) async {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Upload document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(ref.t('auth.choose_from_gallery')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFor(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(ref.t('auth.take_a_photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImageFor(type, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFor(String type, ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null) return;

    _setDocumentFile(type, File(image.path));
  }

  void _setDocumentFile(String type, File file) {
    setState(() {
      if (type == 'aadhaar') {
        _aadhaarFile = file;
      } else if (type == 'address') {
        _addressFile = file;
      } else if (type == 'license') {
        _licenseFile = file;
      }
    });
  }

  bool get _canSubmit =>
      _aadhaarFile != null && _addressFile != null; // license is optional

  Future<void> _submit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.t('auth.upload_aadhaar')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userService = ref.read(userServiceProvider);

      print('📄 [UploadDocuments] Uploading documents:');
      print('   - national_id: ${_aadhaarFile?.path}');
      print('   - proof_national_id: ${_addressFile?.path}');
      print('   - services_license: ${_licenseFile?.path}');

      final result = await userService.partnerUploadDocuments(
        nationalId: _aadhaarFile,
        proofNationalId: _addressFile,
        servicesLicense: _licenseFile,
      );

      if (!mounted) return;

      await result.fold(
        (failure) async {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) async {
          setState(() => _isSubmitting = false);

          print('✅ [UploadDocuments] Documents uploaded successfully');
          print('📊 [UploadDocuments] Response: $data');

          await ref.read(authProvider.notifier).markDocumentsSubmitted();
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DocumentsSubmittedScreen()),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        title: Text(
          ref.t('auth.upload_documents'),
          style: const TextStyle(
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
                    title: ref.t('auth.aadhaar_card'),
                    hint: 'JPG, PNG',
                    selectedFile: _aadhaarFile?.path.split('/').last,
                    onUpload: () => _showUploadOptions('aadhaar'),
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentSection(
                    title: ref.t('auth.address_proof'),
                    hint: 'JPG, PNG',
                    selectedFile: _addressFile?.path.split('/').last,
                    onUpload: () => _showUploadOptions('address'),
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentSection(
                    title: ref.t('auth.service_license_if_applicable'),
                    hint: 'JPG, PNG',
                    selectedFile: _licenseFile?.path.split('/').last,
                    onUpload: () => _showUploadOptions('license'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canSubmit ? _green : _green.withValues(alpha: 0.5),
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
                              : Text(ref.t('auth.submit_documents')),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.t('auth.instruction'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          _BulletText(ref.t('auth.maximum_file_size')),
          SizedBox(height: 4),
          _BulletText(ref.t('auth.supported_formats')),
          SizedBox(height: 4),
          _BulletText(ref.t('auth.make_sure_documents')),
          SizedBox(height: 4),
          _BulletText(ref.t('auth.avoid_blurry')),
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
                color: Colors.black.withValues(alpha: 0.03),
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
                  child: Text(ref.t('auth.upload')),
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
