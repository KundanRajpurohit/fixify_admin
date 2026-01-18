import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CancelJobScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const CancelJobScreen({super.key, required this.job});

  @override
  ConsumerState<CancelJobScreen> createState() => _CancelJobScreenState();
}

class _CancelJobScreenState extends ConsumerState<CancelJobScreen> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  List<String> get _cancellationReasons {
    return [
      ref.t('jobs.incorrect_address'),
      ref.t('jobs.unable_to_reach'),
      ref.t('jobs.service_not_possible'),
      ref.t('jobs.emergency_reason'),
      ref.t('jobs.other'),
    ];
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _showCancelSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ref.t('jobs.job_cancelled'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ref.t('jobs.job_cancelled_message'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to job details
                    Navigator.of(context).pop(); // Go back to My Jobs
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    ref.t('jobs.go_to_my_jobs'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSubmit() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(ref.t('jobs.select_reason')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedReason == ref.t('jobs.other') &&
        _otherReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(ref.t('jobs.provide_reason')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle cancellation logic here
    _showCancelSuccessDialog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: CustomAppBar(title: ref.t('jobs.cancel_job'), showbackButton: true),
      body: Column(
        children: [
          // Header

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.t('jobs.cancel_reason'),
                    style: const TextStyle(
                      fontSize: 17,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.t('jobs.reasons_for_cancellation'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children:
                                _cancellationReasons.map((reason) {
                                  final isSelected = _selectedReason == reason;
                                  final isOther = reason == ref.t('jobs.other');

                                  return Column(
                                    children: [
                                      RadioListTile<String>(
                                        title: Text(
                                          reason,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        value: reason,
                                        groupValue: _selectedReason,
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedReason = value;
                                          });
                                        },
                                        activeColor: AppColors.primary,
                                      ),
                                      if (isOther && isSelected)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            16,
                                          ),
                                          child: TextField(
                                            controller: _otherReasonController,
                                            decoration: InputDecoration(
                                              hintText: ref.t('jobs.write_reason'),
                                              hintStyle: TextStyle(
                                                color: Colors.grey.shade400,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey.shade50,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: AppColors.primary,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            maxLines: 3,
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(color: Colors.transparent),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Submit & Cancel Job',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit Button
        ],
      ),
    );
  }
}






