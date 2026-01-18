import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/dashboard/cancel_job_screen.dart';
import 'package:fixify_admin/screens/dashboard/complete_job_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final String token;
  final bool isNewJob;

  const JobDetailsScreen({
    super.key,
    required this.token,
    required this.isNewJob,
  });

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  String _jobStatus = 'Upcoming'; // Upcoming, Ongoing, Completed
  bool _isTimerRunning = false;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  Map<String, dynamic>? jobDetails;
  bool _loading = true;

  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case "upcoming":
        return {
          "label": ref.t('dashboard.upcoming'),
          "bg": Color(0xffF2F6FB),
          "text": Color(0xFF214370),
          "border": Color(0xFFC2DAF0),
        };

      case "ongoing":
        return {
          "label": ref.t('dashboard.ongoing'),
          "bg": Color(0xffFBF6F2),
          "text": Color(0xFF704B21),
          "border": Color(0xFFF0E4C2),
        };

      case "past":
        return {
          "label": ref.t('dashboard.past'),
          "bg": Color(0xffF2FBF2),
          "text": Color(0xFF257021),
          "border": Color(0xFFC2F0C7),
        };

      case "cancelled":
        return {
          "label": ref.t('dashboard.cancelled'),
          "bg": Color(0xffF5F5F5),
          "text": Color(0xFF434343),
          "border": Color(0xFFDFDFDF),
        };

      default:
        return {
          "label": ref.t('common.unknown'),
          "bg": Color(0xffF5F5F5),
          "text": Color(0xFF434343),
          "border": Color(0xFFDFDFDF),
        };
    }
  }

  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.t('dashboard.unable_to_make_phone_call')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptJob() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(userServiceProvider);

      // Step 1: Accept job
      final acceptResult = await service.acceptJob(widget.token);

      acceptResult.fold(
        (failure) {
          Navigator.of(context).pop(); // Close loading
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (acceptData) async {
          // Step 2: Assign job
          final assignResult = await service.assignJob(widget.token);

          assignResult.fold(
            (failure) {
              Navigator.of(context).pop(); // Close loading
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(failure.message),
                  backgroundColor: Colors.red,
                ),
              );
            },
            (assignData) {
              Navigator.of(context).pop(); // Close loading
              if (!mounted) return;

              // Show success dialog
              _showAcceptJobDialog();
            },
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAcceptJobDialog() {
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
              const Text(
                'Job Accepted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You\'ve successfully accepted the request. Get ready to start the service.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                    Navigator.of(context).pop(true); // Go back to My Jobs
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go to My Jobs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
    _jobStatus = jobDetails?['status'] ?? 'upcoming';
    if (_jobStatus == 'Ongoing') {
      _isTimerRunning = true;
      _startTimer();
    }
  }

  Future<void> _fetchJobDetails() async {
    setState(() => _loading = true);
    print("fetch job details for token: ${widget.token}");

    final service = ref.read(userServiceProvider);
    final result = await service.getJobDetails(widget.token);

    result.fold(
      (failure) {
        if (!mounted) return;

        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (data) {
        if (!mounted) return;

        setState(() {
          jobDetails = data["data"];
          _jobStatus = (jobDetails?["work_status"] ?? "upcoming").toString();

          _loading = false;

          if (_jobStatus == "ongoing") {
            _isTimerRunning = true;
            _startTimer();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isTimerRunning) {
        setState(() {
          _elapsedTime = _elapsedTime + const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _timer?.cancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(hours)}h:${twoDigits(minutes)}m:${twoDigits(seconds)}s';
  }

  bool get _isHourlyService {
    final serviceType =
        jobDetails?['serviceType']?.toString().toLowerCase() ??
        jobDetails?['jobType']?.toString().toLowerCase() ??
        '';
    return serviceType == 'hourly' ||
        serviceType.contains('hourly') ||
        serviceType.contains('hour');
  }

  Future<void> _handleStartJob() async {
    // Step 1: Call assign-job API
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(userServiceProvider);
      final assignResult = await service.assignJob(widget.token);

      assignResult.fold(
        (failure) {
          Navigator.of(context).pop(); // Close loading
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          Navigator.of(context).pop(); // Close loading
          if (!mounted) return;

          // Step 2: Show OTP bottom sheet
          _showOTPBottomSheet(
            data['data']?['mobile'] ?? jobDetails?['UserMobile'] ?? '',
          );
        },
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOTPBottomSheet(String mobile) {
    // Clear previous OTP inputs
    for (var controller in _otpControllers) {
      controller.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enter Customer OTP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ask the customer to show the OTP and enter it below to start the job.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xff4B5563),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              _otpFocusNodes[index + 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Resend via SMS in 00:57',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final otp = _otpControllers.map((c) => c.text).join();
                        if (otp.length == 4) {
                          Navigator.pop(context); // Close bottom sheet
                          await _handleVerifyOtp(otp, mobile);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter complete OTP'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Verify & Start Job',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleVerifyOtp(String otp, String mobile) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final service = ref.read(userServiceProvider);
      final result = await service.verifyJobOtp(
        jobToken: widget.token,
        mobile: mobile,
        otp: otp,
      );

      result.fold(
        (failure) {
          Navigator.of(context).pop(); // Close loading
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          Navigator.of(context).pop(); // Close loading
          if (!mounted) return;

          // Update job status to ongoing
          setState(() {
            _jobStatus = 'ongoing';
            _isTimerRunning = true;
            _elapsedTime = Duration.zero;
            if (jobDetails != null) {
              jobDetails!['work_status'] = 'ongoing';
            }
          });

          // Start timer
          _startTimer();

          // Show success dialog
          _showJobStartedDialog();

          // Refresh job details after a delay to get updated status
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _fetchJobDetails();
            }
          });
        },
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showJobStartedDialog() {
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
              const Text(
                'Job Started Successfully',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ref.t('dashboard.otp_verified_timer_started'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              if (_isHourlyService) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        ref.t('dashboard.running_timer'),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF6E5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatDuration(_elapsedTime),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF704B21),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isTimerRunning,
                        onChanged: (value) {
                          setState(() {
                            _isTimerRunning = value;
                            if (value) {
                              _startTimer();
                            } else {
                              _stopTimer();
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    // Refresh job details to show updated status
                    _fetchJobDetails();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Go to Job Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCompleteJob() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
        child: CompleteJobScreen(job: jobDetails!),
      ),
    );
  }

  void _handleNotInterested() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
        child: CancelJobScreen(job: jobDetails!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final status = getStatusStyle(jobDetails?['work_status']);

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        body: Column(
          children: [
            CustomAppBar(title: ref.t('dashboard.job_details'), showbackButton: true),

            // Timer (only for hourly services when job is ongoing)
            if (_jobStatus == 'ongoing' && _isHourlyService)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    Text(
                      ref.t('dashboard.running_timer'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6E5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _formatDuration(_elapsedTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF704B21),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isTimerRunning,
                      onChanged: (value) {
                        setState(() {
                          _isTimerRunning = value;
                          if (value) {
                            _startTimer();
                          } else {
                            _stopTimer();
                          }
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildServiceDetailsCard(),
                    const SizedBox(height: 12),
                    _buildCustomerDetailsCard(),
                    const SizedBox(height: 12),
                    _buildJobNotesCard(),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (widget.isNewJob)
              // New Job Request - Show Accept Job button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
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
                    onPressed: _handleAcceptJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      ref.t('dashboard.accept_job'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            else if (!widget.isNewJob)
              // Assigned Job - Show buttons based on status
              Builder(
                builder: (context) {
                  final status = _jobStatus.toLowerCase();

                  // Past or Cancelled - No button
                  if (status == 'past' || status == 'cancelled') {
                    return const SizedBox.shrink(); // No button
                  }

                  // Ongoing - Show Complete Job button
                  if (status == 'ongoing') {
                    return Container(
                      padding: const EdgeInsets.all(16),
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
                          onPressed: _handleCompleteJob,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            ref.t('dashboard.complete_job'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Upcoming - Show Start Job button
                  if (status == 'upcoming') {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xffF2F6FB),
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
                          onPressed: _handleStartJob,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                          ),
                          child: Text(
                            ref.t('dashboard.start_job'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // Default - No button
                  return const SizedBox.shrink();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsCard() {
    final status = getStatusStyle(jobDetails?['work_status']);
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.t('dashboard.service_details'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: status["bg"],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: status["border"], width: 1.5),
                ),
                child: Text(
                  '${status["label"]}',
                  style: TextStyle(
                    fontSize: 13,
                    color: status["text"],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: 'assets/images/serviceId.png',
            label: ref.t('dashboard.service_id'),
            value: jobDetails?['ServiceID'] ?? "service",
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: 'assets/images/serviceType.png',
            label: ref.t('dashboard.service_type'),
            value:
                jobDetails?['ServiceType'] ??
                jobDetails?['jobType'] ??
                "service",
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: 'assets/images/calendar 2.png',
            label: ref.t('dashboard.time_date'),
            value: jobDetails?['date_time'],
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: 'assets/images/payment.png',
            label: ref.t('dashboard.payment'),
            value: (jobDetails?['price'] ?? 0).toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.t('dashboard.customer_information'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: 'assets/images/person.png',
            label: ref.t('dashboard.name'),
            value: jobDetails?['UserName'] ?? "Customer Name",
          ),
          const Divider(height: 24),
          _buildDetailRowWithAction(
            icon: Icons.phone,
            label: ref.t('dashboard.contact_number'),
            value: jobDetails?['UserMobile'] ?? "Not Available",
            actionText: ref.t('dashboard.call_now'),
            onAction: () => _makePhoneCall('+918535544156'),
          ),
          const Divider(height: 24),
          _buildDetailRowWithAction(
            icon: Icons.location_on,
            label: ref.t('dashboard.address'),
            value: jobDetails?['UserAddress'],
            actionText: ref.t('dashboard.view_map'),
            onAction: () {
              // Handle view map
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobNotesCard() {
    final message = jobDetails?['message'];

    // Only show job notes if message is not null and not empty
    if (message == null || message.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message.toString(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithAction({
    required IconData icon,
    required String label,
    required String value,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff6B7280),
                ),
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,

          children: [
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
