import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/providers/language_provider.dart';
import 'package:fixify_admin/screens/auth/initial_language_selection_screen.dart';
import 'package:fixify_admin/screens/auth/phone_verification_screen.dart';
import 'package:fixify_admin/screens/dashboard/dashboard_screen.dart';
import 'package:fixify_admin/screens/onboarding/onboarding_screen.dart';
import 'package:fixify_admin/services/device_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Initialize device info (device token, platform, GA4 client ID)
    _initializeDeviceInfo();

    // Note: Notification permissions are already requested in main.dart
    // during NotificationService initialization
    // We don't need to request again here to avoid duplicate requests

    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _checkLanguageAndNavigate();
    });
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      print('🚀 [SplashScreen] Initializing device info...');
      await DeviceInfoService.initializeDeviceInfo();
      print('✅ [SplashScreen] Device info initialized successfully');
    } catch (e) {
      print('❌ [SplashScreen] Failed to initialize device info: $e');
    }
  }

  Future<void> _checkLanguageAndNavigate() async {
    // First check if language has been selected
    final languageNotifier = ref.read(languageProvider.notifier);
    final hasSelectedLanguage =
        await languageNotifier.hasLanguageBeenSelected();

    print(
      '🌐 [SplashScreen] Language selection check: hasSelectedLanguage = $hasSelectedLanguage',
    );

    // Only show language selection screen if language has NOT been selected
    if (!hasSelectedLanguage) {
      // Navigate to language selection screen only if no language is selected
      print(
        '🌐 [SplashScreen] No language selected - Navigating to InitialLanguageSelectionScreen',
      );
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          child: const InitialLanguageSelectionScreen(),
        ),
      );
      return;
    }

    // Language is already selected - skip language selection screen and proceed with auth-based navigation
    print(
      '🌐 [SplashScreen] Language already selected - Skipping language selection screen',
    );
    print('🌐 [SplashScreen] Proceeding with auth-based navigation');
    _navigateBasedOnAuthState();
  }

  void _navigateBasedOnAuthState() {
    final authState = ref.read(authProvider);

    print('🚀 [SplashScreen] Checking authentication state...');
    print('🔑 [SplashScreen] Auth token: ${authState.authToken}');
    print('👤 [SplashScreen] User token: ${authState.userToken}');
    print('📱 [SplashScreen] Phone number: ${authState.phoneNumber}');
    print('✅ [SplashScreen] Is verified: ${authState.isVerified}');

    // Case 1: Authorization token exists - User is fully authenticated
    if (authState.authToken != null && authState.authToken!.isNotEmpty) {
      print(
        '✅ [SplashScreen] Authorization token found - User is fully authenticated',
      );
      print('🎯 [SplashScreen] Navigating to MainAppScreen');

      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          child: const HomePageScreen(),
        ),
      );
    }
    // Case 2: Only user token exists - User saved location but didn't complete OTP verification
    else if (authState.userToken != null && authState.userToken!.isNotEmpty) {
      print(
        '📍 [SplashScreen] Only user token found - User saved location but needs OTP verification',
      );
      print('🎯 [SplashScreen] Navigating to PhoneVerificationScreen');

      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          child: const PhoneVerificationScreen(),
        ),
      );
    }
    // Case 3: No tokens exist - User needs to start from beginning
    else {
      print(
        '🆕 [SplashScreen] No tokens found - User needs to start from beginning',
      );
      print('🎯 [SplashScreen] Navigating to OnboardingScreen');

      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          child: const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/Splash Screen.png',
              fit: BoxFit.cover,
            ),
          ),

          // Semi-transparent gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x80C0D6CA), // semi-transparent green (50% opacity)
                    Color(0x80F3F4F6), // semi-transparent white (50% opacity)
                  ],
                ),
              ),
            ),
          ),

          // Animated logo in center
          Center(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _fadeAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Image.asset(
                      'assets/images/image 1 1.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
