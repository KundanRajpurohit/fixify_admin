import 'package:fixify_admin/screens/auth/map_screen.dart';
import 'package:fixify_admin/screens/auth/set_password_screen.dart';
import 'package:fixify_admin/screens/dashboard/home_screen.dart';
import 'package:fixify_admin/screens/onboarding/location_permission_screen.dart';
import 'package:fixify_admin/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart' show userServiceProvider;
import '../dashboard/dashboard_screen.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final isCreateAccount;
  const OTPVerificationScreen({super.key, this.isCreateAccount = false});

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  Timer? _timer;
  Timer? _autoVerifyTimer;
  int _countdown = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Debug: Show received OTP
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authProvider);
      print('🔐 [OTPVerificationScreen] Screen initialized');
      print('📱 [OTPVerificationScreen] Phone: ${authState.phoneNumber}');
      print('🔢 [OTPVerificationScreen] Received OTP: ${authState.otp}');
      print('👤 [OTPVerificationScreen] User ID: ${authState.userId}');
      print('🆕 [OTPVerificationScreen] Is Create Account: ${widget.isCreateAccount}');

      // Pre-fill OTP if available
      if (authState.otp != null && authState.otp!.isNotEmpty) {
        print('✅ [OTPVerificationScreen] Pre-filling OTP: ${authState.otp}');
        _prefillOTP(authState.otp!);
      } else if (widget.isCreateAccount && authState.phoneNumber != null) {
        // Send OTP automatically for create account flow
        print('📤 [OTPVerificationScreen] Auto-sending OTP for create account flow');
        final userService = ref.read(userServiceProvider);
        final result = await userService.partnerSendOtp(
          mobile: authState.phoneNumber!,
        );
        result.fold(
          (failure) {
            print('❌ [OTPVerificationScreen] Failed to send OTP: ${failure.message}');
          },
          (data) {
            print('✅ [OTPVerificationScreen] OTP sent successfully');
            if (data['otp'] != null) {
              ref.read(authProvider.notifier).state = authState.copyWith(
                otp: data['otp'].toString(),
              );
              _prefillOTP(data['otp'].toString());
            }
          },
        );
      }
    });
  }

  void _prefillOTP(String otp) {
    print(
      '🔢 [OTPVerificationScreen] Pre-filling OTP: $otp (length: ${otp.length})',
    );
    if (otp.length == 4) {
      for (int i = 0; i < 4; i++) {
        _otpControllers[i].text = otp[i];
        print('📝 [OTPVerificationScreen] Filled field $i with: ${otp[i]}');
      }
      // Auto-verify after 1 second delay
      print(
        '⏰ [OTPVerificationScreen] OTP pre-filled, auto-verifying in 1 second...',
      );
      _autoVerifyTimer = Timer(const Duration(seconds: 1), () {
        if (mounted && !_isVerifying) {
          print(
            '🚀 [OTPVerificationScreen] Auto-verifying pre-filled OTP after delay',
          );
          _verifyOTP();
        }
      });
    } else {
      print('❌ [OTPVerificationScreen] OTP length is not 4, cannot pre-fill');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoVerifyTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendOTP() async {
    final authState = ref.read(authProvider);
    if (authState.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userService = ref.read(userServiceProvider);
    final phoneNumber = authState.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');

    if (widget.isCreateAccount) {
      // Use partner Send OTP API for registration flow
      print('📤 [OTPVerificationScreen] Resending OTP via partnerSendOtp (create account)');
      final result = await userService.partnerSendOtp(
        mobile: phoneNumber,
      );
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          // Update auth state with OTP if available
          if (data['otp'] != null) {
            ref.read(authProvider.notifier).state = authState.copyWith(
              otp: data['otp'].toString(),
            );
            // Pre-fill OTP if available
            _prefillOTP(data['otp'].toString());
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } else {
      // Use partner Login API for phone verification (login) flow
      print('📤 [OTPVerificationScreen] Resending OTP via partnerLogin (phone verification)');
      final result = await userService.partnerLogin(
        mobile: phoneNumber,
      );
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          final status = data['status'] as bool? ?? false;
          final message = data['message'] as String? ?? '';
          final accountStatus = data['Account_status'] as String?;

          if (status == true) {
            // OTP sent successfully
            if (data['otp'] != null) {
              ref.read(authProvider.notifier).state = authState.copyWith(
                otp: data['otp'].toString(),
              );
              // Pre-fill OTP if available
              _prefillOTP(data['otp'].toString());
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Handle different error scenarios
            String errorMessage = message;
            
            if (message.contains('not registered') || 
                message.toLowerCase().contains('mobile number not registered')) {
              errorMessage = 'Your account is in review. You will receive an update once verification completes.';
            } else if (accountStatus == 'pending' || 
                       message.toLowerCase().contains('not active')) {
              errorMessage = 'Your account is not active. Please contact support.';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    }
    
    _startTimer();
  }

  String _getFormattedPhoneNumber() {
    final authState = ref.read(authProvider);
    if (authState.phoneNumber != null && authState.countryCode != null) {
      final phone = authState.phoneNumber!;
      if (phone.length >= 10) {
        return '${authState.countryCode} ${phone.substring(0, 2)} ${phone.substring(2, 5)} ${phone.substring(5)}';
      }
    }
    return '';
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOTP();
      }
    }
  }

  void _onBackspacePressed(int index) {
    if (_otpControllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyOTP() {
    // Prevent duplicate verification calls
    if (_isVerifying) {
      print(
        '⚠️ [OTPVerificationScreen] Verification already in progress, skipping...',
      );
      return;
    }

    final otp = _otpControllers.map((controller) => controller.text).join();
    print('🔐 [OTPVerificationScreen] _verifyOTP called');
    print(
      '🔢 [OTPVerificationScreen] OTP entered: $otp, length: ${otp.length}',
    );

    // Check if OTP is 4 digits (as per API response)
    if (otp.length == 4) {
      print(
        '✅ [OTPVerificationScreen] OTP length is 4, showing verification dialog',
      );
      _isVerifying = true;
      _showVerificationDialog(otp);
    } else {
      print(
        '❌ [OTPVerificationScreen] OTP length is ${otp.length}, not valid (expected 4)',
      );
    }
  }

  void _showVerificationDialog(String otp) async {
    print(
      '🔐 [OTPVerificationScreen] _showVerificationDialog called with OTP: $otp',
    );

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF217043)),
            ),
          ),
    );

    print('⏳ [OTPVerificationScreen] Calling verifyOTP...');
    
    bool isSuccess = false;
    
    if (widget.isCreateAccount) {
      // Use partner OTP verification API
      final authState = ref.read(authProvider);
      if (authState.phoneNumber == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not found'),
            backgroundColor: Colors.red,
          ),
        );
        _isVerifying = false;
        return;
      }
      
      final userService = ref.read(userServiceProvider);
      final result = await userService.partnerVerifyOtp(
        mobile: authState.phoneNumber!,
        otp: otp,
      );
      
      result.fold(
        (failure) {
          isSuccess = false;
        },
        (data) {
          isSuccess = true;
          // Update auth state with token if available
          // The token is already saved to SharedPreferences by partnerVerifyOtp method
          if (data['token'] != null) {
            ref.read(authProvider.notifier).state = authState.copyWith(
              authToken: data['token'],
              isVerified: true,
            );
            print('✅ [OTPVerificationScreen] Token saved to state (already saved to SharedPreferences by service)');
          }
        },
      );
    } else {
      // Use regular user OTP verification
      isSuccess = await ref.read(authProvider.notifier).verifyOTP(otp);
    }
    
    print('📥 [OTPVerificationScreen] verifyOTP result: $isSuccess');

    // Close loading dialog
    Navigator.of(context).pop();

    // Reset verification flag
    _isVerifying = false;

    // Show result dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (isSuccess) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Image.asset("assets/images/5290058 1.png"),
                const SizedBox(height: 24),
                Text(
                  widget.isCreateAccount
                      ? 'Verified Successfully!'
                      : 'Login Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your mobile number has been verified successfully. You can now explore our services and book with ease.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          duration: const Duration(milliseconds: 500),
                          child:
                              widget.isCreateAccount
                                  // ? LocationPermissionScreen()
                                  ? MapScreen()
                                  : const HomePageScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF217043),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Image.asset("assets/images/lose_8586526.png"),
                const SizedBox(height: 24),
                const Text(
                  'Verification Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The OTP you entered is invalid or expired. Please try again.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Clear OTP fields
                      for (var controller in _otpControllers) {
                        controller.clear();
                      }
                      // Reset verification flag
                      _isVerifying = false;
                      _focusNodes[0].requestFocus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF217043),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const SizedBox(width: 24), // Balance the close button
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    'We\'ve sent a code via SMS to ${_getFormattedPhoneNumber()}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // OTP input fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                _otpControllers[index].text.isNotEmpty
                                    ? const Color(0xFF217043)
                                    : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                            hintText: '•',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 24,
                            ),
                          ),
                          onChanged: (value) => _onOTPChanged(index, value),
                          onSubmitted: (value) => _onOTPChanged(index, value),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 40),

                  // Resend timer/button
                  if (_canResend)
                    GestureDetector(
                      onTap: _resendOTP,
                      child: const Text(
                        'Resend via SMS',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF217043),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Resend via SMS in 00:${(_countdown % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                  const SizedBox(height: 40),

                  // Terms and conditions
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        TextSpan(
                          text:
                              'By verifying your phone number, you accept our ',
                        ),
                        TextSpan(
                          text: 'Term and Conditions',
                          style: TextStyle(
                            color: Color(0xFF217043),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    bool isSpecial = false,
    bool isBackspace = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isBackspace) {
          // Find the last filled OTP field and clear it
          for (int i = 3; i >= 0; i--) {
            if (_otpControllers[i].text.isNotEmpty) {
              _otpControllers[i].clear();
              _focusNodes[i].requestFocus();
              break;
            }
          }
        } else if (text != '*') {
          // Find the first empty OTP field and fill it
          for (int i = 0; i < 4; i++) {
            if (_otpControllers[i].text.isEmpty) {
              _otpControllers[i].text = text;
              if (i < 3) {
                _focusNodes[i + 1].requestFocus();
              } else {
                _focusNodes[i].unfocus();
                _verifyOTP();
              }
              break;
            }
          }
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child:
              isBackspace
                  ? const Icon(
                    Icons.backspace_outlined,
                    color: Colors.black87,
                    size: 24,
                  )
                  : Text(
                    text,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isSpecial ? Colors.grey : Colors.black87,
                    ),
                  ),
        ),
      ),
    );
  }
}
