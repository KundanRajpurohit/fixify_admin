import 'package:fixify_admin/components/curved_TopClipper.dart';
import 'package:fixify_admin/components/segmented_rings.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:page_transition/page_transition.dart';
import 'get_started_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> get _pages => [
    OnboardingPage(
      title: ref.t('onboarding.manage_work_easily'),
      description: ref.t('onboarding.manage_work_description'),
      illustration:  _BookingServicesIllustration(),
    ),
    OnboardingPage(
      title: ref.t('onboarding.secure_instant_earnings'),
      description: ref.t('onboarding.secure_earnings_description'),
      illustration:  _SkilledProfessionalsIllustration(),
    ),
    OnboardingPage(
      title: ref.t('onboarding.get_help_whenever'),
      description: ref.t('onboarding.get_help_description'),
      illustration:  _PaymentIllustration(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Navigate to main app
                      _navigateToMainApp();
                    },
                    child: Text(
                      ref.t('onboarding.skip'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index];
                },
              ),
            ),

            // Bottom section with navigation - Green Card with more rounded corners
            SafeArea(
              child: ClipPath(
                clipper: CurvedTopClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.43,
                  decoration: const BoxDecoration(color: AppColors.primary),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title + description
                        Column(
                          children: [
                            const SizedBox(height: 40),
                            Text(
                                  _pages[_currentPage].title,
                                  style:  TextStyle(
                                    color: Colors.white,
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideY(begin: 0.2),
                            const SizedBox(height: 20),
                            Text(
                                  _pages[_currentPage].description,
                                  style:  TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                                .animate()
                                .fadeIn(duration: 300.ms, delay: 100.ms)
                                .slideY(begin: 0.2),
                          ],
                        ),
              
                        // Navigation button with segmented ring
                        GestureDetector(
                          onTap: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _navigateToMainApp();
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Segmented ring
                              CustomPaint(
                                size: Size(70.h, 70.h),
                                painter: SegmentedRingPainter(
                                  totalSegments: 3,
                                  currentSegment: _currentPage + 1,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              // Inner white circle button
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Color(0xFF217043),
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ).animate().scale(duration: 300.ms, delay: 200.ms),
                      ],
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

  void _navigateToMainApp() {
    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 500),
        child: const GetStartedScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final Widget illustration;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Expanded(child: Center(child: illustration))],
      ),
    );
  }
}

// Illustration for Booking Services
class _BookingServicesIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: Image.asset('assets/images/onboarding1.png', fit: BoxFit.contain),
    );
  }
}

// Illustration for Skilled Professionals
class _SkilledProfessionalsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: Image.asset('assets/images/onboarding2.png', fit: BoxFit.contain),
    );
  }
}

// Illustration for Payments
class _PaymentIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: Image.asset('assets/images/onboarding3.png', fit: BoxFit.contain),
    );
  }
}
