import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import 'get_started_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Manage Your Work Easily",
      description:
          "Find trusted carpenters, plumbers, and handymen near you. Schedule your service with just a few taps.",
      illustration: _BookingServicesIllustration(),
    ),
    OnboardingPage(
      title: "Skilled & Verified Professionals",
      description:
          "Get high-quality work from certified experts, ensuring safety, reliability, and satisfaction.",
      illustration: _SkilledProfessionalsIllustration(),
    ),
    OnboardingPage(
      title: "Hassle-Free Payments",
      description:
          "Make secure online payments with clear, upfront pricing—no surprises or hidden costs.",
      illustration: _PaymentIllustration(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Color(0xFF666666),
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

            // Bottom section with navigation
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              decoration: const BoxDecoration(
                color: Color(0xFF217043),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and description
                    Column(
                      children: [
                        Text(
                          _pages[_currentPage].title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: 20),
                        Text(
                              _pages[_currentPage].description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: 100.ms)
                            .slideY(begin: 0.2),
                      ],
                    ),

                    // Step indicators and navigation
                    Column(
                      children: [
                        // Step indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentPage == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    _currentPage == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Navigation button
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
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF217043),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF217043),
                              size: 24,
                            ),
                          ),
                        ).animate().scale(duration: 300.ms, delay: 200.ms),
                      ],
                    ),
                  ],
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
      child: Image.asset(
        'assets/images/make-your-app-.png',
        fit: BoxFit.contain,
      ),
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
      child: Image.asset(
        'assets/images/flat-design-household-renovation-professions-concept_23-2148655549.jpg',
        fit: BoxFit.contain,
      ),
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
      child: Image.asset('assets/images/upi-autopay.png', fit: BoxFit.contain),
    );
  }
}
