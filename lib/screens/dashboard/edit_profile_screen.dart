import 'dart:async';
import 'dart:io';

import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? profileData;

  const EditProfileScreen({super.key, this.profileData});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _profileImage;
  String? _imageUrl;
  bool _isLoading = false;
  bool _isLoadingProfile = false;
  Map<String, dynamic>? _profileData;

  // Phone number change state
  final TextEditingController _newPhoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    4,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
      4, (index) => FocusNode());
  Timer? _otpTimer;
  int _otpCountdown = 60;
  bool _canResendOTP = false;
  bool _isVerifyingOTP = false;
  bool _isUpdatingMobile = false;
  String? _newPhoneNumber;

  @override
  void initState() {
    super.initState();
    if (widget.profileData != null) {
      _profileData = widget.profileData;
      _initializeFields();
    } else {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getPartnerProfile();

      result.fold(
            (failure) {
          if (mounted) {
            setState(() {
              _isLoadingProfile = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
            (data) {
          if (mounted) {
            setState(() {
              _profileData = data['data'];
              _isLoadingProfile = false;
            });
            _initializeFields();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _initializeFields() {
    if (_profileData != null) {
      final name = _profileData!['name'] ?? '';
      final mobile = _profileData!['mobile'] ?? '';
      _imageUrl = _profileData!['image'];

      // Split name into first and last name
      final nameParts = name.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text =
      nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _phoneNumberController.text = mobile;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _newPhoneController.dispose();
    _otpTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (_profileImage != null || _imageUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _profileImage = null;
                      _imageUrl = null;
                    });
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
          AlertDialog(
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
                    Icons.check,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Profile Updated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your profile information has been updated successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Return to profile screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }


  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);

      // Update profile with image, name, and mobile
      final fullName =
      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
          .trim();
      final result = await userService.updatePartnerProfile(
        name: fullName,
        mobile: _phoneNumberController.text.trim(),
        image: _profileImage,
      );

      result.fold(
            (failure) {
          if (mounted) {
            _showErrorDialog(
              'Profile Update Failed',
              failure.message,
            );
          }
        },
            (data) {
          if (mounted) {
            _showSuccessDialog();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPhoneNumberDialog() {
    _newPhoneController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Change Phone Number',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your new phone number',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('🇮🇳 +91'),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isUpdatingMobile ? null : () async {
                final newPhone = _newPhoneController.text.trim();
                if (newPhone.isEmpty || newPhone.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid phone number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await _sendContactNumberOTP(newPhone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isUpdatingMobile
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _sendContactNumberOTP(String phoneNumber) async {
    setState(() {
      _isUpdatingMobile = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.updateMobile(mobile: phoneNumber);

      if (!mounted) return false;

      return result.fold(
            (failure) {
          setState(() {
            _isUpdatingMobile = false;
          });
          _showErrorDialog(
            'Update Failed',
            failure.message,
          );
          return false;
        },
            (data) {
          setState(() {
            _isUpdatingMobile = false;
            _newPhoneNumber = phoneNumber;
          });
          _showOTPVerificationBottomSheet();
          return true;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdatingMobile = false;
        });
        _showErrorDialog(
          'Update Failed',
          'Something went wrong. Please try again.',
        );
      }
      return false;
    }
  }

  void _startOTPTimer() {
    _otpTimer?.cancel();
    _otpCountdown = 60;
    _canResendOTP = false;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        setState(() {
          _otpCountdown--;
        });
      } else {
        setState(() {
          _canResendOTP = true;
        });
        timer.cancel();
      }
    });
  }

  void _showOTPVerificationBottomSheet() {
    // Clear OTP fields
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpCountdown = 60;
    _canResendOTP = false;
    _isVerifyingOTP = false;
    _startOTPTimer();

    final formattedPhone = _newPhoneNumber?.replaceAllMapped(
      RegExp(r'(\d{2})(\d{2})(\d{3})(\d+)'),
          (m) => '${m.group(1)} ${m.group(2)} ${m.group(3)} ${m.group(4)}',
    ) ??
        '';
    final fullPhoneNumber = '+91 $formattedPhone';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _otpTimer?.cancel();
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.black87,
                          size: 24,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Verification Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Instructions
                  Text(
                    'We\'ve sent a code via SMS to $fullPhoneNumber',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // OTP input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: 56,
                        height: 56,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          enabled: !_isVerifyingOTP,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF217043),
                                width: 2,
                              ),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && !_isVerifyingOTP) {
                              if (index < 3) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else {
                                _otpFocusNodes[index].unfocus();
                                // Auto-verify when all 4 digits are entered
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  _verifyContactNumberOTP();
                                });
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  if (_isVerifyingOTP) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(
                          0xFF217043)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verifying...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _canResendOTP
                            ? 'Didn\'t receive the code?'
                            : 'Resend via SMS in ${(_otpCountdown ~/ 60)
                            .toString()
                            .padLeft(2, '0')}:${(_otpCountdown % 60)
                            .toString()
                            .padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _canResendOTP ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      if (_canResendOTP)
                        TextButton(
                          onPressed: () async {
                            if (_newPhoneNumber != null) {
                              _startOTPTimer();
                              final otpSent = await _sendContactNumberOTP(
                                  _newPhoneNumber!);
                              if (!otpSent && mounted) {
                                // If OTP sending failed, close the bottom sheet
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Text(
                            'Resend',
                            style: TextStyle(
                              color: Color(0xFF217043),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Terms
                  const Text(
                    'By verifying your phone number, you accept our Terms and Conditions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // Clean up timer when bottom sheet is dismissed
      _otpTimer?.cancel();
    });
  }

  Future<void> _verifyContactNumberOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 4) {
      return;
    }

    setState(() {
      _isVerifyingOTP = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.verifyMobileOtp(otp: otp);

      if (!mounted) return;

      result.fold(
            (failure) {
          setState(() {
            _isVerifyingOTP = false;
          });
          // Clear OTP fields on error
          for (var controller in _otpControllers) {
            controller.clear();
          }
          _otpFocusNodes[0].requestFocus();
          _showErrorDialog(
            'Verification Failed',
            failure.message,
          );
        },
            (data) {
          setState(() {
            _isVerifyingOTP = false;
          });
          // Close bottom sheet
          Navigator.pop(context);
          // Show success dialog
          _showPhoneUpdateSuccessDialog();
          // Reload profile to get updated phone number
          _loadProfile();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingOTP = false;
        });
        _showErrorDialog(
          'Verification Failed',
          'Something went wrong. Please try again.',
        );
      }
    }
  }

  void _showPhoneUpdateSuccessDialog() {
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
              Image.asset(
                'assets/images/5290058 1.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact Number Updated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your contact number has been updated successfully.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF217043),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('View Profile'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/lose_8586526.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF217043),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Always refresh profile screen when going back
        Navigator.pop(context, true);
        return false; // Prevent default pop behavior since we're handling it
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        body: _isLoadingProfile
            ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        )
            : Column(
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
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Notification icon removed - using CustomAppBar instead
                  const SizedBox.shrink(),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
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
                              : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : (_imageUrl != null
                                ? NetworkImage(_imageUrl!)
                                : null)
                            as ImageProvider?,
                            child: _profileImage == null && _imageUrl == null
                                ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showImageOptions,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Personal Information Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                            // First Name
                            const Text(
                              'First Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                hintText: 'Enter first name',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value
                                    .trim()
                                    .isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Last Name
                            const Text(
                              'Last Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                hintText: 'Enter last name',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value
                                    .trim()
                                    .isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Information Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Contact Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    _showPhoneNumberDialog();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneNumberController,
                              decoration: InputDecoration(
                                hintText: 'Phone Number',
                                prefixIcon: Container(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '🇮🇳',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '+91',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                                suffixIcon: _phoneNumberController.text
                                    .isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _phoneNumberController.clear();
                                    });
                                  },
                                )
                                    : null,
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              enabled: false, // Disabled as per UI
                            ),
                            // if (_profileData?['email'] != null) ...[
                            //   const SizedBox(height: 20),
                            //   const Text(
                            //     'Email',
                            //     style: TextStyle(
                            //       fontSize: 16,
                            //       fontWeight: FontWeight.w500,
                            //       color: Colors.black87,
                            //     ),
                            //   ),
                            //   const SizedBox(height: 8),
                            //   TextFormField(
                            //     initialValue: _profileData!['email'] ?? '',
                            //     decoration: InputDecoration(
                            //       hintText: 'Email Address',
                            //       prefixIcon: const Icon(Icons.email_outlined),
                            //       filled: true,
                            //       fillColor: Colors.grey.shade50,
                            //       enabledBorder: OutlineInputBorder(
                            //         borderRadius: BorderRadius.circular(12),
                            //         borderSide: BorderSide(
                            //           color: Colors.grey.shade200,
                            //         ),
                            //       ),
                            //       border: OutlineInputBorder(
                            //         borderRadius: BorderRadius.circular(12),
                            //         borderSide: BorderSide(
                            //           color: Colors.grey.shade200,
                            //         ),
                            //       ),
                            //     ),
                            //     enabled: false,
                            //   ),
                            // ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}