import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixify_admin/main.dart';
import 'package:fixify_admin/screens/notifications/notifications_screen.dart';
import 'package:fixify_admin/screens/dashboard/job_details_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  StreamController<RemoteMessage>? _messageStreamController;
  Stream<RemoteMessage>? _messageStream;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ [NotificationService] Already initialized');
      return;
    }

    try {
      print('🚀 [NotificationService] Initializing notification service...');
      print('📱 [NotificationService] Platform: ${Platform.operatingSystem}');

      // Set up notification channel for Android (must be done FIRST)
      if (Platform.isAndroid) {
        print('📱 [NotificationService] Setting up Android notification channel...');
        await _createNotificationChannel();
      }

      // Initialize local notifications plugin
      print('📱 [NotificationService] Initializing local notifications plugin...');
      await _initializeLocalNotifications();
      print('✅ [NotificationService] Local notifications plugin initialized');

      // Request permissions
      print('📱 [NotificationService] Requesting notification permissions...');
      await _requestPermissions();

      // Set up message handlers
      print('📱 [NotificationService] Setting up message handlers...');
      await _setupMessageHandlers();

      // Note: Background message handler is set in main.dart BEFORE Firebase.initializeApp()
      // We don't set it here to avoid duplicate registration
      print('✅ [NotificationService] Background handler already registered in main.dart');

      // Get initial message (if app was opened from a notification)
      print('📱 [NotificationService] Checking for initial message...');
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('📱 [NotificationService] App opened from notification');
        _handleNotificationTap(initialMessage);
      } else {
        print('📱 [NotificationService] No initial message found');
      }

      _isInitialized = true;
      print('✅ [NotificationService] Notification service initialized successfully');
      print('📱 [NotificationService] Ready to receive notifications');
    } catch (e, stackTrace) {
      print('❌ [NotificationService] Error initializing: $e');
      print('📝 [NotificationService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 [NotificationService] iOS Permission Status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ [NotificationService] iOS notifications authorized');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ [NotificationService] iOS notifications provisionally authorized');
      } else {
        print('❌ [NotificationService] iOS notifications not authorized');
      }
    } else if (Platform.isAndroid) {
      // Android 13+ requires runtime permission
      final androidInfo = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidInfo != null) {
        final granted = await androidInfo.requestNotificationsPermission();
        print('📱 [NotificationService] Android Permission Granted: $granted');
      }
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'fixify_notifications', // id
      'Fixify Notifications', // name
      description: 'Notifications for Fixify Partner app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidInfo = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidInfo != null) {
      await androidInfo.createNotificationChannel(androidChannel);
      print('✅ [NotificationService] Android notification channel created');
    }
  }

  /// Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('🔄 [NotificationService] FCM Token refreshed: $newToken');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_token', newToken);
    });

    // Get and log current token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('📱 [NotificationService] FCM Token: ${token.substring(0, 20)}...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('device_token', token);
    }
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 [NotificationService] Foreground message received');
    print('📝 [NotificationService] Title: ${message.notification?.title}');
    print('📝 [NotificationService] Body: ${message.notification?.body}');
    print('📝 [NotificationService] Data: ${message.data}');

    // Show local notification when app is in foreground
    if (message.notification != null) {
      await _showLocalNotification(message);
    }

    // Emit to stream if available
    _messageStreamController?.add(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'fixify_notifications',
      'Fixify Notifications',
      channelDescription: 'Notifications for Fixify Partner app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 [NotificationService] Notification tapped');
    print('📝 [NotificationService] Data: ${message.data}');

    // Navigate based on notification data
    // You can use navigatorKey here to navigate to specific screens
    _navigateFromNotification(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 [NotificationService] Local notification tapped');
    print('📝 [NotificationService] Payload: ${response.payload}');
    
    // Parse payload and navigate
    if (response.payload != null) {
      // You can parse the payload and navigate accordingly
    }
  }

  /// Navigate based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      print('⚠️ [NotificationService] Navigator not available');
      return;
    }

    // Extract notification data
    final type = data['type'] as String?;
    final jobToken = data['job_token'] as String?;
    final jobId = data['job_id'] as String?;
    final notificationId = data['notification_id'] as String?;

    print('🧭 [NotificationService] Navigating from notification');
    print('   Type: $type');
    print('   Job Token: $jobToken');
    print('   Job ID: $jobId');
    print('   Notification ID: $notificationId');

    // Navigate based on notification type
    if (type == 'job' || jobToken != null || jobId != null) {
      // Navigate to job details screen
      final token = jobToken ?? jobId ?? '';
      if (token.isNotEmpty) {
        navigator.push(
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: JobDetailsScreen(
              token: token,
              isNewJob: type == 'new_job' || data['is_new_job'] == true,
            ),
          ),
        );
        print('✅ [NotificationService] Navigated to job details: $token');
      }
    } else if (type == 'notification' || notificationId != null) {
      // Navigate to notifications screen
      navigator.push(
        PageTransition(
          type: PageTransitionType.rightToLeft,
          duration: const Duration(milliseconds: 300),
          child: const NotificationsScreen(),
        ),
      );
      print('✅ [NotificationService] Navigated to notifications screen');
    } else {
      // Default: navigate to notifications screen
      navigator.push(
        PageTransition(
          type: PageTransitionType.rightToLeft,
          duration: const Duration(milliseconds: 300),
          child: const NotificationsScreen(),
        ),
      );
      print('✅ [NotificationService] Navigated to notifications screen (default)');
    }
  }

  /// Get message stream for listening to notifications
  Stream<RemoteMessage>? get messageStream => _messageStream;

  /// Create message stream
  void createMessageStream() {
    if (_messageStreamController != null) return;
    
    _messageStreamController = StreamController<RemoteMessage>.broadcast();
    _messageStream = _messageStreamController!.stream;
  }

  /// Dispose message stream
  void disposeMessageStream() {
    _messageStreamController?.close();
    _messageStreamController = null;
    _messageStream = null;
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      print('📱 [NotificationService] Getting FCM token...');
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('✅ [NotificationService] FCM Token retrieved: ${token.substring(0, 30)}...');
        print('📱 [NotificationService] Full token length: ${token.length}');
      } else {
        print('⚠️ [NotificationService] FCM Token is null');
      }
      return token;
    } catch (e, stackTrace) {
      print('❌ [NotificationService] Error getting token: $e');
      print('📝 [NotificationService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Print notification service status (for debugging)
  Future<void> printStatus() async {
    print('🔍 [NotificationService] === Notification Service Status ===');
    print('   Initialized: $_isInitialized');
    print('   Platform: ${Platform.operatingSystem}');
    
    try {
      final token = await getToken();
      print('   FCM Token: ${token != null ? "${token.substring(0, 30)}..." : "null"}');
    } catch (e) {
      print('   FCM Token: Error - $e');
    }
    
    if (Platform.isAndroid) {
      final androidInfo = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidInfo != null) {
        // Check if permissions are granted (Android 13+)
        final granted = await androidInfo.areNotificationsEnabled();
        print('   Notifications Enabled: $granted');
      }
    } else if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      print('   Authorization Status: ${settings.authorizationStatus}');
      print('   Alert Setting: ${settings.alert}');
      print('   Badge Setting: ${settings.badge}');
      print('   Sound Setting: ${settings.sound}');
    }
    
    print('🔍 [NotificationService] === End Status ===');
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ [NotificationService] Subscribed to topic: $topic');
    } catch (e) {
      print('❌ [NotificationService] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ [NotificationService] Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ [NotificationService] Error unsubscribing from topic: $e');
    }
  }

  /// Delete token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      print('✅ [NotificationService] FCM token deleted');
    } catch (e) {
      print('❌ [NotificationService] Error deleting token: $e');
    }
  }
}

