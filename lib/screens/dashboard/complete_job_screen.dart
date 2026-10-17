import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/dio/resulr.dart';
import 'package:fixify_admin/helpers/payment_display.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/dashboard/rate_customer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CompleteJobScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const CompleteJobScreen({super.key, required this.job});

  @override
  ConsumerState<CompleteJobScreen> createState() => _CompleteJobScreenState();
}

class _CompleteJobScreenState extends ConsumerState<CompleteJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isReportSubmitted = false;

  String get _groupToken {
    final groupToken = widget.job['group_token'] ?? widget.job['groupToken'];
    return (groupToken ?? widget.job['token'] ?? '').toString();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPhotoSourceOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(ref.t('auth.take_a_photo')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(ref.t('auth.choose_from_gallery')),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImagesFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.t('dashboard.please_upload_at_least_one_photo')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      if (!_isReportSubmitted) {
        final reportResult = await userService.submitJobReport(
          jobToken: widget.job['token'],
          prNotes: _notesController.text.trim(),
          prWorkImgs: _selectedImages,
        );

        if (!mounted) return;

        await reportResult.fold((failure) async => throw failure, (_) async {
          _isReportSubmitted = true;
        });
      }

      if (!mounted) return;
      await _showPaymentOptions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiFailure ? e.message : ref.t('common.try_again'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showPaymentOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        var isLoading = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> runPaymentAction(
              Future<void> Function() action,
            ) async {
              setSheetState(() => isLoading = true);
              try {
                await action();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e is ApiFailure ? e.message : ref.t('common.try_again'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (context.mounted) {
                  setSheetState(() => isLoading = false);
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      ref.t('dashboard.collect_payment'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ref.t('dashboard.collect_payment_before_complete'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildPaymentActionTile(
                      icon: Icons.qr_code_2,
                      title: ref.t('dashboard.generate_qr_code_for_payment'),
                      subtitle: ref.t('dashboard.generate_qr_code_subtitle'),
                      enabled: !isLoading,
                      onTap:
                          () =>
                              runPaymentAction(() => _handleQrPayment(context)),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentActionTile(
                      icon: Icons.payments_outlined,
                      title: ref.t('dashboard.i_have_received_cash'),
                      subtitle: ref.t('dashboard.cash_received_subtitle'),
                      enabled: !isLoading,
                      onTap:
                          () => runPaymentAction(
                            () => _handleCashPayment(context),
                          ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: enabled ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQrPayment(BuildContext sheetContext) async {
    final userService = ref.read(userServiceProvider);
    final qrResult = await userService.generatePaymentQrCode(
      groupToken: _groupToken,
    );

    final qrData = await qrResult.fold(
      (failure) async => throw failure,
      (data) async => data,
    );

    if (!mounted || !sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();
    await _showQrCodeDialog(qrData);
  }

  Future<void> _handleCashPayment(BuildContext sheetContext) async {
    final userService = ref.read(userServiceProvider);
    final cashResult = await userService.confirmCashPayment(
      groupToken: _groupToken,
    );

    await cashResult.fold((failure) async => throw failure, (_) async {});
    if (!mounted || !sheetContext.mounted) return;
    Navigator.of(sheetContext).pop();
    await _completeJobAfterPayment();
  }

  Future<void> _showQrCodeDialog(Map<String, dynamic> qrData) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        var isChecking = false;
        final qrValue = paymentQrImageValue(qrData);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> checkStatus() async {
              setDialogState(() => isChecking = true);
              try {
                final userService = ref.read(userServiceProvider);
                final statusResult = await userService.checkPaymentQrStatus(
                  groupToken: _groupToken,
                );

                final statusData = await statusResult.fold(
                  (failure) async => throw failure,
                  (data) async => data,
                );

                if (!_isPaymentConfirmed(statusData)) {
                  throw ServerFailure(
                    ref.t('dashboard.payment_not_received_yet'),
                    200,
                  );
                }

                if (!mounted || !dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                await _completeJobAfterPayment();
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e is ApiFailure ? e.message : ref.t('common.try_again'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => isChecking = false);
                }
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(ref.t('dashboard.scan_to_pay')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQrPreview(qrValue),
                    const SizedBox(height: 12),
                    Text(
                      ref.t('dashboard.ask_customer_to_scan'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isChecking ? null : () => Navigator.of(context).pop(),
                  child: Text(ref.t('common.close')),
                ),
                ElevatedButton.icon(
                  onPressed: isChecking ? null : checkStatus,
                  icon:
                      isChecking
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.verified_outlined),
                  label: Text(ref.t('dashboard.check_payment_status')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQrPreview(String? qrValue) {
    if (qrValue == null || qrValue.isEmpty) {
      return Text(
        ref.t('dashboard.qr_code_unavailable'),
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
    }

    final uri = Uri.tryParse(qrValue);
    if (uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty) {
      return Image.network(
        qrValue,
        height: 220,
        width: 220,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 220,
            width: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder:
            (_, __, ___) => Text(
              ref.t('dashboard.qr_code_unavailable'),
              textAlign: TextAlign.center,
            ),
      );
    }

    final imageBytes = _decodeBase64Image(qrValue);
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        height: 220,
        width: 220,
        fit: BoxFit.contain,
        errorBuilder:
            (_, __, ___) => Text(
              ref.t('dashboard.qr_code_unavailable'),
              textAlign: TextAlign.center,
            ),
      );
    }

    return Text(
      ref.t('dashboard.qr_code_unavailable'),
      textAlign: TextAlign.center,
    );
  }

  Uint8List? _decodeBase64Image(String value) {
    try {
      final normalized =
          value.contains(',') ? value.split(',').last.trim() : value.trim();
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  bool _isPaymentConfirmed(Map<String, dynamic> data) {
    final statusValues =
        _findValuesByKeys(data, {
          'status',
          'payment_status',
          'paymentStatus',
          'paid',
          'success',
          'is_paid',
          'isPaid',
        }).map((value) => value.toString().toLowerCase()).toList();

    if (statusValues.any(_isNegativePaymentValue)) return false;
    if (statusValues.any(_isPositivePaymentValue)) return true;

    final values =
        _flattenValues(data).map((value) => value.toLowerCase()).toList();
    if (values.any(
      (value) =>
          value.contains('pending') ||
          value.contains('unpaid') ||
          value.contains('failed'),
    )) {
      return false;
    }

    return values.any(_isPositivePaymentValue);
  }

  bool _isPositivePaymentValue(String value) {
    return value == 'true' ||
        value.contains('paid') ||
        value.contains('success') ||
        value.contains('completed') ||
        value.contains('received');
  }

  bool _isNegativePaymentValue(String value) {
    return value == 'false' ||
        value.contains('pending') ||
        value.contains('unpaid') ||
        value.contains('failed');
  }

  Iterable<Object?> _findValuesByKeys(Object? value, Set<String> keys) sync* {
    if (value is Map) {
      for (final entry in value.entries) {
        if (keys.contains(entry.key.toString())) {
          yield entry.value;
        }
        yield* _findValuesByKeys(entry.value, keys);
      }
    } else if (value is List) {
      for (final item in value) {
        yield* _findValuesByKeys(item, keys);
      }
    }
  }

  Iterable<String> _flattenValues(Object? value) sync* {
    if (value is Map) {
      for (final nestedValue in value.values) {
        yield* _flattenValues(nestedValue);
      }
    } else if (value is List) {
      for (final nestedValue in value) {
        yield* _flattenValues(nestedValue);
      }
    } else if (value != null) {
      yield value.toString();
    }
  }

  Future<void> _completeJobAfterPayment() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final completeResult = await userService.jobCompleted(
        widget.job['token'],
      );

      await completeResult.fold((failure) async => throw failure, (_) async {});

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RateCustomerScreen(job: widget.job)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiFailure ? e.message : ref.t('common.try_again'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        body: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.4),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      ref.t('dashboard.complete_job'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Color(0xFF217043),
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions Card
                      _buildInstructionsCard(),
                      const SizedBox(height: 16),
                      // Upload Photos Card
                      _buildUploadPhotosCard(),
                      const SizedBox(height: 16),
                      // Notes Card
                      _buildNotesCard(),
                    ],
                  ),
                ),
              ),
            ),

            // Submit Button
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            _isReportSubmitted
                                ? ref.t('dashboard.continue_to_payment')
                                : ref.t('common.submit'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.t('auth.instruction'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInstructionItem(ref.t('auth.maximum_file_size')),
          _buildInstructionItem(ref.t('auth.supported_formats')),
          _buildInstructionItem(ref.t('auth.make_sure_documents')),
          _buildInstructionItem(ref.t('auth.avoid_blurry')),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadPhotosCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.t('dashboard.upload_job_photos'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ref.t('dashboard.add_clear_photos'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          // Selected Images Grid
          if (_selectedImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          // Add Photo Button
          GestureDetector(
            onTap: _showPhotoSourceOptions,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      ref.t('dashboard.add_photo'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.t('dashboard.notes'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: ref.t('dashboard.write_notes'),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
