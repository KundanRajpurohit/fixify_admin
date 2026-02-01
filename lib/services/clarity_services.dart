import 'package:clarity_flutter/clarity_flutter.dart';

/// Helper service for Microsoft Clarity Analytics
///
/// Available methods in clarity_flutter:
/// - Clarity.setCustomUserId(String userId)
/// - Clarity.getCurrentSessionUrl()
/// - Clarity.sendCustomEvent(String eventName)
class ClarityService {
  /// Set custom user ID (call this after user login)
  static Future<void> setUserId(String userId) async {
    try {
      Clarity.setCustomUserId(userId);
      print('✅ Clarity user ID set: $userId');
    } catch (e) {
      print('❌ Failed to set Clarity user ID: $e');
    }
  }

  /// Send a custom event to Clarity
  static Future<void> sendEvent(String eventName) async {
    try {
      final success = Clarity.sendCustomEvent(eventName);
      if (success) {
        print('✅ Clarity event sent: $eventName');
      } else {
        print('⚠️ Clarity event failed: $eventName');
      }
    } catch (e) {
      print('❌ Failed to send Clarity event: $e');
    }
  }

  /// Get current session URL
  static String? getSessionUrl() {
    try {
      final url = Clarity.getCurrentSessionUrl();
      print('✅ Clarity session URL: $url');
      return url;
    } catch (e) {
      print('❌ Failed to get Clarity session URL: $e');
      return null;
    }
  }

  // Helper methods for common actions
  static Future<void> trackLogin(String userId, {String? userType}) async {
    await setUserId(userId);
    await sendEvent('user_login');
    if (userType != null) {
      await sendEvent('user_type_$userType');
    }
  }

  static Future<void> trackScreenView(String screenName) async {
    await sendEvent('screen_view_$screenName');
  }

  static Future<void> trackJobAccepted(String jobId) async {
    await sendEvent('job_accepted_$jobId');
  }

  static Future<void> trackOnlineStatus(bool isOnline) async {
    await sendEvent(isOnline ? 'partner_online' : 'partner_offline');
  }
}