import 'package:dio/dio.dart';
import 'package:fixify_admin/dio/token_interceptor.dart';
import 'package:fixify_admin/screens/auth/phone_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedInterceptor extends QueuedInterceptor {
  final GlobalKey<NavigatorState>? navigatorKey;
  static bool _isHandling401 = false; // Prevent multiple simultaneous 401 handlers

  UnauthorizedInterceptor({this.navigatorKey});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('🔒 [UnauthorizedInterceptor] onError - Status: ${err.response?.statusCode}');
    
    // Only handle 401 status code
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }
    
    // Check if TokenInterceptor has already handled this (successful refresh means we won't reach here)
    // We only get here if:
    // 1. TokenInterceptor's refresh failed (refreshFailed = true)
    // 2. OR there was no refresh token to begin with
    // 3. OR the request was already a retry that failed
    
    final isRetry = err.requestOptions.extra['isRetry'] == true;
    final refreshMarkedFailed = err.requestOptions.extra['refreshFailed'] == true;
    
    print('🔒 [UnauthorizedInterceptor] isRetry: $isRetry, refreshMarkedFailed: $refreshMarkedFailed');
    print('🔒 [UnauthorizedInterceptor] TokenInterceptor.refreshFailed: ${TokenInterceptor.refreshFailed}');
    
    // Only proceed with logout if:
    // 1. Token refresh has actually failed (static flag or request extra)
    // 2. OR this is a retry that still got 401 (refresh didn't help)
    final shouldLogout = TokenInterceptor.refreshFailed || 
                         refreshMarkedFailed || 
                         isRetry;
    
    if (!shouldLogout) {
      print('🔒 [UnauthorizedInterceptor] Not logging out - refresh might still be in progress');
      return handler.next(err);
    }
    
    if (_isHandling401) {
      print('🔒 [UnauthorizedInterceptor] Already handling 401, skipping');
      return handler.next(err);
    }
    
    _isHandling401 = true;
    print('🔒 [UnauthorizedInterceptor] Token refresh failed, proceeding with logout');
    print('🔒 [UnauthorizedInterceptor] Response: ${err.response?.data}');
    
    // Clear all preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('🧹 [UnauthorizedInterceptor] All preferences cleared');
    } catch (e) {
      print('❌ [UnauthorizedInterceptor] Error clearing preferences: $e');
    }
    
    // Reset the static flag
    TokenInterceptor.refreshFailed = false;

    // Navigate to phone verification screen
    _navigateToPhoneVerification();
    
    // Reset flag after a delay
    Future.delayed(const Duration(seconds: 3), () {
      _isHandling401 = false;
    });

    handler.next(err);
  }

  void _navigateToPhoneVerification() {
    // Use post-frame callback to ensure navigation happens after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performNavigation();
    });
  }

  void _performNavigation() {
    try {
      // Try using navigator state first (most reliable)
      if (navigatorKey?.currentState != null) {
        final navigator = navigatorKey!.currentState!;
        
        // Check if we're already on the phone verification screen
        final currentRoute = ModalRoute.of(navigator.context);
        if (currentRoute?.settings.name?.contains('PhoneVerification') == true) {
          print('⚠️ [UnauthorizedInterceptor] Already on PhoneVerificationScreen, skipping navigation');
          return;
        }
        
        navigator.pushAndRemoveUntil(
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 300),
            child: const PhoneVerificationScreen(),
          ),
          (route) => false,
        );
        print('✅ [UnauthorizedInterceptor] Navigated to PhoneVerificationScreen via currentState');
        return;
      }

      // Fallback: Use context if available
      if (navigatorKey?.currentContext != null) {
        final context = navigatorKey!.currentContext!;
        
        // Check if we're already on the phone verification screen
        final currentRoute = ModalRoute.of(context);
        if (currentRoute?.settings.name?.contains('PhoneVerification') == true) {
          print('⚠️ [UnauthorizedInterceptor] Already on PhoneVerificationScreen, skipping navigation');
          return;
        }
        
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 300),
            child: const PhoneVerificationScreen(),
          ),
          (route) => false,
        );
        print('✅ [UnauthorizedInterceptor] Navigated to PhoneVerificationScreen via context');
        return;
      }

      // Last resort: Try again after a short delay
      print('⚠️ [UnauthorizedInterceptor] Navigator not ready, retrying in 500ms...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isHandling401) return; // Don't retry if flag was reset
        _performNavigation();
      });
    } catch (e) {
      print('❌ [UnauthorizedInterceptor] Navigation error: $e');
      // Retry after delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!_isHandling401) return;
        _performNavigation();
      });
    }
  }
}
