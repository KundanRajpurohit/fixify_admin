import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/screens/dashboard/dashboard_screen.dart';
import 'package:fixify_admin/services/device_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';

import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart' show userServiceProvider;
import 'country_picker_screen.dart';
import 'otp_verification_screen.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if token exists and navigate to dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingToken();
    });
  }

  Future<void> _checkExistingToken() async {
    final authState = ref.read(authProvider);
    if (authState.authToken != null && authState.authToken!.isNotEmpty) {
      print(
        '✅ [PhoneVerificationScreen] Token exists, navigating to dashboard',
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 500),
            child: const HomePageScreen(),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.length < 10) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final phoneNumber = _phoneController.text.trim().replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final selectedCountry = ref.read(selectedCountryProvider);

      // Get device info
      final deviceInfo = await DeviceInfoService.getCachedDeviceInfo();
      final deviceToken = deviceInfo['deviceToken'];
      final platform = deviceInfo['platform'];

      print('📱 [PhoneVerificationScreen] Calling partner login API');
      print('📝 [PhoneVerificationScreen] Phone: $phoneNumber');
      print(
        '📱 [PhoneVerificationScreen] Device Token: ${deviceToken != null ? "${deviceToken}..." : "null"}',
      );
      print('📱 [PhoneVerificationScreen] Platform: $platform');

      final result = await userService.partnerLogin(
        mobile: phoneNumber,
        deviceToken: deviceToken,
        platform: platform,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          setState(() {
            _isLoading = false;
          });

          print('📊 [PhoneVerificationScreen] Login response: $data');

          final status = data['status'] as bool? ?? false;
          final message = data['message'] as String? ?? '';
          final accountStatus = data['Account_status'] as String?;

          if (status == true) {
            // OTP sent successfully
            print('✅ [PhoneVerificationScreen] OTP sent successfully');

            // Update auth state with phone number and OTP
            final authState = ref.read(authProvider);
            ref.read(authProvider.notifier).state = authState.copyWith(
              phoneNumber: data['mobile']?.toString() ?? phoneNumber,
              countryCode: selectedCountry.dialCode,
              otp: data['otp']?.toString(),
            );

            // Navigate to OTP verification screen
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                duration: const Duration(milliseconds: 300),
                child: const OTPVerificationScreen(),
              ),
            );
          } else {
            // Handle different error scenarios
            String errorMessage = message;

            if (message.contains('not registered') ||
                message.toLowerCase().contains(
                  'mobile number not registered',
                )) {
              errorMessage = ref.t('auth.account_in_review');
            } else if (accountStatus == 'pending' ||
                message.toLowerCase().contains('not active')) {
              errorMessage = ref.t('auth.account_not_active');
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
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
    final selectedCountry = ref.watch(selectedCountryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ref.t('auth.your_phone_number'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: () {
                  //     // Skip to main app screen
                  //     Navigator.pushReplacement(
                  //       context,
                  //       PageTransition(
                  //         type: PageTransitionType.fade,
                  //         duration: const Duration(milliseconds: 100),
                  //         child: const HomePageScreen(),
                  //       ),
                  //     );
                  //   },
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //         vertical: 8,
                  //         horizontal: 20), // No padding for compact button
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       borderRadius: BorderRadius.circular(20),
                  //       border: Border.all(
                  //         color: const Color(0xFFD1D5DB),
                  //         width: 1,
                  //       ),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.black.withOpacity(0.1),
                  //           blurRadius: 4,
                  //           offset: const Offset(0, 2),
                  //         ),
                  //       ],
                  //     ),
                  //     child: const Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Text(
                  //           'Skip',
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             color: AppColors.textPrimary,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //         SizedBox(width: 4),
                  //         Icon(
                  //           Icons.arrow_forward,
                  //           color: AppColors.textPrimary,
                  //           size: 16,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ref.t('auth.create_account_to_save'),
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Phone input section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Phone input field
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Country selector
                        GestureDetector(
                          onTap: () async {
                            final selected = await Navigator.push<Country>(
                              context,
                              PageTransition(
                                type: PageTransitionType.bottomToTop,
                                duration: const Duration(milliseconds: 300),
                                child: const CountryPickerScreen(),
                              ),
                            );
                            if (selected != null) {
                              ref.read(selectedCountryProvider.notifier).state =
                                  selected;
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFE5E7EB),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Text(
                                    selectedCountry.flag,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedCountry.dialCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Divider
                        Container(
                          height: 24,
                          width: 1,
                          color: Colors.grey.shade300,
                        ),

                        // Phone number input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              hintText: ref.t('auth.type_phone_number'),
                              hintStyle: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),

                        // Clear button
                        if (_phoneController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _phoneController.clear();
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.close,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Verify button
                ],
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed:
                      _phoneController.text.length >= 10 && !_isLoading
                          ? _handleLogin
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _phoneController.text.length >= 10
                            ? AppColors.primary
                            : const Color(0xFFE0E0E0),
                    foregroundColor:
                        _phoneController.text.length >= 10
                            ? Colors.white
                            : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
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
                            ref.t('auth.verify'),
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
}
