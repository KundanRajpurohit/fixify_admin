import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceInfoService {
  static const String _deviceTokenKey = 'device_token';
  static const String _platformKey = 'platform';
  static const String _ga4ClientIdKey = 'ga4_client_id';

  // Get device token (FCM token)
  static Future<String?> getDeviceToken() async {
    try {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_deviceTokenKey);
      
      if (cachedToken != null && cachedToken.isNotEmpty) {
        print('📱 [DeviceInfoService] Using cached device token');
        return cachedToken;
      }

      // Request FCM token
      print('📱 [DeviceInfoService] Requesting FCM token...');
      final messaging = FirebaseMessaging.instance;
      
      // Request permission for iOS
      if (Platform.isIOS) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          print('⚠️ [DeviceInfoService] Notification permission not granted');
          return null;
        }
      }

      final token = await messaging.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Cache the token
        await prefs.setString(_deviceTokenKey, token);
        print('✅ [DeviceInfoService] Device token obtained: ${token.substring(0, 20)}...');
        
        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) async {
          await prefs.setString(_deviceTokenKey, newToken);
          print('🔄 [DeviceInfoService] Device token refreshed');
        });
        
        return token;
      } else {
        print('❌ [DeviceInfoService] Failed to get device token');
        return null;
      }
    } catch (e) {
      print('❌ [DeviceInfoService] Error getting device token: $e');
      return null;
    }
  }

  // Get platform (Android/iOS)
  static String getPlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else {
      return 'Unknown';
    }
  }

  // Get GA4 Client ID
  static Future<String?> getGA4ClientId() async {
    try {
      // Try to get from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedClientId = prefs.getString(_ga4ClientIdKey);
      
      if (cachedClientId != null && cachedClientId.isNotEmpty) {
        print('📊 [DeviceInfoService] Using cached GA4 client ID');
        return cachedClientId;
      }

      // Get GA4 client ID from Firebase Analytics
      print('📊 [DeviceInfoService] Getting GA4 client ID...');
      final analytics = FirebaseAnalytics.instance;
      
      // Get app instance ID (which is used as client ID in GA4)
      final appInstanceId = await analytics.appInstanceId;
      
      if (appInstanceId != null && appInstanceId.isNotEmpty) {
        // Cache the client ID
        await prefs.setString(_ga4ClientIdKey, appInstanceId);
        print('✅ [DeviceInfoService] GA4 client ID obtained: ${appInstanceId.substring(0, 20)}...');
        return appInstanceId;
      } else {
        // Generate a fallback client ID using device info
        final deviceInfo = DeviceInfoPlugin();
        String fallbackId;
        
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          fallbackId = '${androidInfo.id}_${DateTime.now().millisecondsSinceEpoch}';
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          fallbackId = '${iosInfo.identifierForVendor ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          fallbackId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        await prefs.setString(_ga4ClientIdKey, fallbackId);
        print('⚠️ [DeviceInfoService] Using fallback GA4 client ID');
        return fallbackId;
      }
    } catch (e) {
      print('❌ [DeviceInfoService] Error getting GA4 client ID: $e');
      // Return a fallback ID
      final fallbackId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_ga4ClientIdKey, fallbackId);
      } catch (_) {}
      return fallbackId;
    }
  }

  // Initialize device info (call this in splash screen)
  static Future<Map<String, String?>> initializeDeviceInfo() async {
    print('🚀 [DeviceInfoService] Initializing device info...');
    
    final deviceToken = await getDeviceToken();
    final platform = getPlatform();
    final ga4ClientId = await getGA4ClientId();
    
    // Cache platform
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_platformKey, platform);
    
    print('📱 [DeviceInfoService] Device info initialized:');
    print('   - Platform: $platform');
    print('   - Device Token: ${deviceToken != null ? "${deviceToken}" : "null"}');
    print('   - GA4 Client ID: ${ga4ClientId != null ? "${ga4ClientId.substring(0, 20)}..." : "null"}');
    
    return {
      'deviceToken': deviceToken,
      'platform': platform,
      'ga4ClientId': ga4ClientId,
    };
  }

  // Get cached device info
  static Future<Map<String, String?>> getCachedDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'deviceToken': prefs.getString(_deviceTokenKey),
      'platform': prefs.getString(_platformKey) ?? getPlatform(),
      'ga4ClientId': prefs.getString(_ga4ClientIdKey),
    };
  }
}




