import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
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
          "label": "Upcoming",
          "bg": Color(0xffF2F6FB),
          "text": Color(0xFF214370),
          "border": Color(0xFFC2DAF0),
        };

      case "ongoing":
        return {
          "label": "Ongoing",
          "bg": Color(0xffFBF6F2),
          "text": Color(0xFF704B21),
          "border": Color(0xFFF0E4C2),
        };

      case "past":
        return {
          "label": "Past",
          "bg": Color(0xffF2FBF2),
          "text": Color(0xFF257021),
          "border": Color(0xFFC2F0C7),
        };

      case "cancelled":
        return {
          "label": "Cancelled",
          "bg": Color(0xffF5F5F5),
          "text": Color(0xFF434343),
          "border": Color(0xFFDFDFDF),
        };

      default:
        return {
          "label": "Unknown",
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
          const SnackBar(
            content: Text('Unable to make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    Navigator.of(context).pop(); // Go back to My Jobs
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

  void _showOTPDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Enter Customer OTP',
                          style: TextStyle(
                            fontSize: 20,
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
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 50,
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
                    Text(
                      'Resend via SMS in 00:57',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final otp = _otpControllers.map((c) => c.text).join();
                          if (otp.length == 4) {
                            Navigator.pop(context);
                            _handleStartJob();
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
                            borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleStartJob() {
    setState(() {
      _jobStatus = 'Ongoing';
      _isTimerRunning = true;
      _elapsedTime = Duration.zero;
    });
    if (_isHourlyService) {
      _startTimer();
    }
    _showJobStartedDialog();
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
              const Text(
                'OTP verified successfully. The timer has started and now you can begin work.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                        'Running Timer',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      // const Spacer(),
                      SizedBox(width: 10.w),
                      Flexible(
                        child: Text(
                          _formatDuration(_elapsedTime),
                          style: TextStyle(
                            fontSize: 10.sp,
                            // fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
            CustomAppBar(title: 'Job Details', showbackButton: true),

            // Timer (only for hourly services when job is ongoing)
            if (_jobStatus == 'ongoing' && _isHourlyService)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Running Timer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatDuration(_elapsedTime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
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
              Container(
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleNotInterested,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Not Interested',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showAcceptJobDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Accept Job',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_jobStatus == 'Ongoing')
              Container(
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Complete Job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else if (_jobStatus == 'Upcoming')
              Container(
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
                    onPressed: _showOTPDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: const Text(
                      'Start Job',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 8),
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
              const Text(
                'Service Details',
                style: TextStyle(
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
            label: 'Service Id',
            value: jobDetails?['ServiceID'] ?? "service",
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: 'assets/images/serviceType.png',
            label: 'Service Type',
            value: jobDetails?['jobType'] ?? "service",
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: 'assets/images/calendar 2.png',
            label: 'Time & Date',
            value: jobDetails?['date_time'],
          ),
          const Divider(height: 24),
          _buildDetailRow(
            icon: 'assets/images/payment.png',
            label: 'Payment',
            value: jobDetails?['price'] ?? "0",
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
          const Text(
            'Customer Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: 'assets/images/person.png',
            label: 'Name',
            value: jobDetails?['UserName'] ?? "Customer Name",
          ),
          const Divider(height: 24),
          _buildDetailRowWithAction(
            icon: Icons.phone,
            label: 'Contact Number',
            value: jobDetails?['UserMobile'],
            actionText: 'Call Now',
            onAction: () => _makePhoneCall('+918535544156'),
          ),
          const Divider(height: 24),
          _buildDetailRowWithAction(
            icon: Icons.location_on,
            label: 'Address',
            value: jobDetails?['UserAddress'],
            actionText: 'View Map',
            onAction: () {
              // Handle view map
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJobNotesCard() {
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
          const Text(
            'Job Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'My home number is 203 — please ring the bell at the door.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
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
