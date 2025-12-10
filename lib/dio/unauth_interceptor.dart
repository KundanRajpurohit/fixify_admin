import 'package:dio/dio.dart';
import 'package:fixify_admin/screens/auth/phone_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedInterceptor extends Interceptor {
  final GlobalKey<NavigatorState>? navigatorKey;
  static bool _isHandling401 = false; // Prevent multiple simultaneous 401 handlers

  UnauthorizedInterceptor({this.navigatorKey});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isHandling401) {
      _isHandling401 = true;
      print('🔒 [UnauthorizedInterceptor] 401 Unauthenticated detected');
      
      // Clear all preferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('🧹 [UnauthorizedInterceptor] All preferences cleared');
      } catch (e) {
        print('❌ [UnauthorizedInterceptor] Error clearing preferences: $e');
      }

      // Navigate to login screen
      _navigateToLogin();
      
      // Reset flag after a delay
      Future.delayed(const Duration(seconds: 2), () {
        _isHandling401 = false;
      });
    }

    super.onError(err, handler);
  }

  void _navigateToLogin() {
    // Use post-frame callback to ensure navigation happens after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performNavigation();
    });
  }

  void _performNavigation() {
    // Try using navigator state first (most reliable)
    if (navigatorKey?.currentState != null) {
      try {
        navigatorKey!.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const PhoneVerificationScreen(),
          ),
          (route) => false,
        );
        print('✅ [UnauthorizedInterceptor] Navigated to PhoneVerificationScreen via currentState');
        return;
      } catch (e) {
        print('❌ [UnauthorizedInterceptor] Navigation via currentState error: $e');
      }
    }

    // Fallback: Use context if available
    if (navigatorKey?.currentContext != null) {
      try {
        Navigator.of(navigatorKey!.currentContext!).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const PhoneVerificationScreen(),
          ),
          (route) => false,
        );
        print('✅ [UnauthorizedInterceptor] Navigated to PhoneVerificationScreen via context');
        return;
      } catch (e) {
        print('❌ [UnauthorizedInterceptor] Navigation via context error: $e');
      }
    }

    // Last resort: Try again after a short delay
    print('⚠️ [UnauthorizedInterceptor] Navigator not ready, retrying in 500ms...');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isHandling401) return; // Don't retry if flag was reset
      _performNavigation();
    });
  }
}

