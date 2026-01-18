
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/map_screen.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends ConsumerState<LocationPermissionScreen> {
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
            // Top section with illustration
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Image.asset(
                    'assets/images/Group 2.png',
                    fit: BoxFit.contain,
                    height: 300,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            // Bottom section with permission request
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(30),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      ref.t('onboarding.allow_location'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),
                    const SizedBox(height: 15),
                    Text(
                      ref.t('onboarding.location_description'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
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
                        onPressed: () async {
                          await _requestLocationPermission();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          ref.t('onboarding.allow_location'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 600.ms, delay: 400.ms),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            duration: const Duration(milliseconds: 500),
                            child: const MapScreen(),
                          ),
                        );
                      },
                      child: Text(
                        ref.t('onboarding.select_location_manually'),
                        style: const TextStyle(
                          color: Color(0xFF217043),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      // Permission granted, navigate to map screen
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          child: const MapScreen(),
        ),
      );
    } else if (status.isDenied) {
      // Permission denied, show dialog
      _showPermissionDeniedDialog();
    } else if (status.isPermanentlyDenied) {
      // Permission permanently denied, open app settings
      await openAppSettings();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(ref.t('onboarding.location_permission_required')),
          content: Text(ref.t('onboarding.location_permission_needed_message')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(ref.t('common.cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 500),
                    child: const MapScreen(),
                  ),
                );
              },
              child: Text(ref.t('onboarding.select_manually')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(ref.t('auth.open_settings')),
            ),
          ],
        );
      },
    );
  }
}
