import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/screens/auth/create_profile.dart';
import 'package:fixify_admin/screens/auth/phone_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';
import 'location_permission_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen>
    with TickerProviderStateMixin {
  late AnimationController _topAnimationController;
  late AnimationController _middleAnimationController;
  late AnimationController _bottomAnimationController;

  @override
  void initState() {
    super.initState();

    // Faster animation speeds
    _topAnimationController = AnimationController(
      duration: const Duration(seconds: 6), // faster
      vsync: this,
    );
    _middleAnimationController = AnimationController(
      duration: const Duration(seconds: 8), // medium
      vsync: this,
    );
    _bottomAnimationController = AnimationController(
      duration: const Duration(seconds: 6), // faster
      vsync: this,
    );

    _topAnimationController.repeat();
    _middleAnimationController.repeat();
    _bottomAnimationController.repeat();
  }

  @override
  void dispose() {
    _topAnimationController.dispose();
    _middleAnimationController.dispose();
    _bottomAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 188, 212, 198), // Lighter mint green at top
              Color(0xFFE8EDE9), // Very light gray-green in middle
              Color(0xFFF5F5F5), // Almost white at bottom
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🔹 Top Row (moves left to right)
              SizedBox(
                height: 150.h, // Fixed height to prevent cutting
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: AnimatedBuilder(
                    animation: _topAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          (_topAnimationController.value * 2 - 1) * 150,
                          0,
                        ),
                        child: Row(
                          children: _buildImageList([
                            'Group 19',
                            'Group 21',
                            'Group 22',
                            'Group 23',
                            'Group 25',
                            'Group 26',
                            'Group 30',
                            'Group 31',
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 🔹 Middle Row (moves left to right, slower)
              SizedBox(
                height: 150.h, // Fixed height to prevent cutting
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: AnimatedBuilder(
                    animation: _middleAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          (_middleAnimationController.value * 2 - 1) * 100,
                          0,
                        ),
                        child: Row(
                          children: _buildImageList([
                            'Group',
                            'Group 26',
                            'Group 27',
                            'Group 28',
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 🔹 Bottom Row (moves right to left)
              SizedBox(
                height: 150.h, // Fixed height to prevent cutting
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: AnimatedBuilder(
                    animation: _bottomAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          -(_bottomAnimationController.value * 2 - 1) * 120,
                          0,
                        ),
                        child: Row(
                          children: _buildImageList([
                            'Group 33',
                            'Group 34',
                            'Group 35',
                            'Group 29',
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 🔹 Text + Button Section
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'FIXIFY',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                    const SizedBox(height: 15),
                    const Text(
                          'Join our platform as a trusted service partner and grow your business with more bookings, easy management, and fast payments.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.fade,
                              duration: const Duration(milliseconds: 500),
                              child: const CreateAccountScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 200.ms, delay: 200.ms),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(width: 4.w),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.fade,
                                duration: const Duration(milliseconds: 500),
                                child: const PhoneVerificationScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Helper to build image cards dynamically
  List<Widget> _buildImageList(List<String> imageNames) {
    return imageNames.map((name) => _buildWorkerCard(name)).toList();
  }

  Widget _buildWorkerCard(String imageName) {
    return Container(
      width: 120.w,
      height: 120.h,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Image.asset('assets/images/$imageName.png', fit: BoxFit.contain),
      ),
    );
  }
}
