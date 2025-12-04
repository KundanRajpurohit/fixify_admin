
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCountry = ref.watch(selectedCountryProvider);
    final authState = ref.watch(authProvider);

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
                  const Text(
                    'Your phone number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Skip to main app screen
                      Navigator.pushReplacement(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          duration: const Duration(milliseconds: 100),
                          child: const HomeDashboardScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 20), // No padding for compact button
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD1D5DB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.textPrimary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'create your account to save details! (From profile menu)',
                  style: TextStyle(
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
                                horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white),
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
                            decoration: const InputDecoration(
                              hintText: 'Type phone number',
                              hintStyle:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 12),
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
                      _phoneController.text.length >= 10 && !authState.isLoading
                          ? () async {
                              print(
                                  '📱 [PhoneVerificationScreen] Verify button pressed');
                              print(
                                  '📝 [PhoneVerificationScreen] Phone: ${_phoneController.text.trim()}');
                              print(
                                  '🌍 [PhoneVerificationScreen] Country: ${selectedCountry.dialCode}');
                              print(
                                  '⏳ [PhoneVerificationScreen] Current loading state: ${authState.isLoading}');

                              await ref.read(authProvider.notifier).sendOTP(
                                    _phoneController.text.trim(),
                                    selectedCountry.dialCode,
                                  );

                              // Check auth state after OTP is sent
                              final updatedAuthState = ref.read(authProvider);
                              print(
                                  '📊 [PhoneVerificationScreen] Auth state after sendOTP:');
                              print(
                                  '   - isLoading: ${updatedAuthState.isLoading}');
                              print('   - error: ${updatedAuthState.error}');
                              print(
                                  '   - phoneNumber: ${updatedAuthState.phoneNumber}');
                              print('   - otp: ${updatedAuthState.otp}');
                              print('   - userId: ${updatedAuthState.userId}');

                              if (updatedAuthState.error == null &&
                                  updatedAuthState.phoneNumber != null) {
                                print(
                                    '✅ [PhoneVerificationScreen] OTP sent successfully, navigating to OTP screen');
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    duration: const Duration(milliseconds: 300),
                                    child: const OTPVerificationScreen(),
                                  ),
                                );
                              } else {
                                print(
                                    '❌ [PhoneVerificationScreen] OTP send failed or error occurred');
                                print(
                                    '❌ [PhoneVerificationScreen] Error: ${updatedAuthState.error}');
                              }
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _phoneController.text.length >= 10
                        ? AppColors.primary
                        : const Color(0xFFE0E0E0),
                    foregroundColor: _phoneController.text.length >= 10
                        ? Colors.white
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                    elevation: 0,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
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
