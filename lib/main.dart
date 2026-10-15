import 'package:clarity_flutter/clarity_flutter.dart'; // 🆕 Add Clarity import
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fixify_admin/config/api_config.dart';
import 'package:fixify_admin/dio/auth_interceptor.dart';
import 'package:fixify_admin/dio/token_interceptor.dart';
import 'package:fixify_admin/dio/token_manager.dart';
import 'package:fixify_admin/dio/unauth_interceptor.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/providers/language_provider.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/auth/splash_screen.dart';
import 'package:fixify_admin/services/notification_service.dart';
import 'package:fixify_admin/services/translation_service.dart';
import 'package:fixify_admin/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for handling 401 redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Top-level function for handling background messages
/// This must be a top-level function, not a class method
/// MUST be registered BEFORE Firebase.initializeApp()
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [Background] Background message received: ${message.messageId}');
  print('📝 [Background] Title: ${message.notification?.title}');
  print('📝 [Background] Body: ${message.notification?.body}');
  print('📝 [Background] Data: ${message.data}');

  final notificationService = NotificationService();
  await notificationService.showBackgroundNotification(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Set background message handler BEFORE Firebase.initializeApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  print('✅ Background message handler registered');

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Initialize notification service AFTER Firebase is initialized
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      print('✅ Notification service initialized successfully');

      // Print notification service status for debugging
      await notificationService.printStatus();
    } catch (e, stackTrace) {
      print('❌ Failed to initialize notification service: $e');
      print('Stack trace: $stackTrace');
    }
  } catch (e, stackTrace) {
    print('❌ Failed to initialize Firebase: $e');
    print('Stack trace: $stackTrace');
  }

  // Initialize SharedPreferences
  try {
    await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize SharedPreferences: $e');
  }

  // Initialize translations
  try {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('app_language') ?? 'en';
    final language = AppLanguage.values.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => AppLanguage.english,
    );
    await TranslationService.loadTranslations(language);
    print('✅ Translations loaded for language: ${language.code}');
  } catch (e) {
    print('❌ Failed to load translations: $e');
    // Load English as fallback
    try {
      await TranslationService.loadTranslations(AppLanguage.english);
    } catch (e2) {
      print('❌ Failed to load English translations: $e2');
    }
  }

  // Initialize Dio and UserService
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Add logging interceptor for debugging
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
      logPrint: (obj) => print('🌐 [Dio] $obj'),
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      protectedPaths: [
        '/partner/profile',
        '/partner/update-profile',
        '/partner/upload-image',
        '/partner/logout',
        '/partner/update-notification',
        '/partner/add-default-address',
        '/partner/upload-documents',
        '/partner/v4/upload-documents',
        '/partner/v4/update-location',
        '/partner/bank/all',
        '/partner/bank/store',
        '/partner/bank/update',
        '/partner/bank/delete',
        '/partner/get-availability',
        '/partner/availability/mon',
        '/partner/availability/tue',
        '/partner/availability/wed',
        '/partner/availability/thu',
        '/partner/availability/fri',
        '/partner/availability/sat',
        '/partner/availability/sun',
        '/partner/all-jobs',
        '/partner/v4/all-jobs',
        '/partner/upcoming-jobs',
        '/partner/v4/upcoming-jobs',
        '/partner/cancelled-jobs',
        '/partner/v4/cancelled-jobs',
        '/partner/ongoing-jobs',
        '/partner/v4/all-ongoing-jobs',
        '/partner/past-jobs',
        '/partner/v4/all-completed-jobs',
        '/partner/assign-upcoming-jobs',
        '/partner/v4/all-assign-jobs',
        '/partner/accept-job',
        '/partner/assign-job',
        '/partner/verify-job-otp',
        '/partner/job-completed',
        '/partner/submit-job-report',
        '/partner/rating-customer',
        '/partner/single-job-details',
        '/partner/v4/single-job',
        '/partner/deshbord',
        '/partner/go-online',
        '/partner/get-go-online',
        '/partner/get-data-by-custom-date',
        '/add-to-cart',
        '/get-cart-data',
        '/partner/booking-transaction-daily',
        '/partner/booking-transaction-weekly',
        '/partner/booking-transaction-month',
        '/partner/transaction-history',
        '/partner/checkout-index',
        '/partner/checkout-store',
        '/partner/notifications',
        '/partner/notifications/mark-as-read',
        '/partner/update-mobile',
        '/partner/mobile-otp-verify',
      ],
    ),
  );
  dio.interceptors.add(TokenInterceptor(tokenManager: TokenManager()));

  // Add unauthorized interceptor LAST to handle 401 errors from all endpoints
  // This ensures it catches 401 errors after all other interceptors have processed
  dio.interceptors.add(UnauthorizedInterceptor(navigatorKey: navigatorKey));

  print('🔧 [Main] Dio initialized with base URL: ${ApiConfig.baseUrl}');
  final userService = UserService(dio);
  print('👤 [Main] UserService initialized');

  // 🆕 Configure Clarity Analytics
  final clarityConfig = ClarityConfig(projectId: 'vao6wyj0ty');

  // 🆕 Wrap the app with ClarityWidget
  runApp(
    ClarityWidget(
      app: ProviderScope(
        overrides: [userServiceProvider.overrideWithValue(userService)],
        child: const MyApp(),
      ),
      clarityConfig: clarityConfig,
    ),
  );

  print('✅ Clarity analytics initialized with project ID: vao6wyj0ty');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            // 🔒 Prevent iOS Large Text / Bold Text from breaking UI
            textScaler: TextScaler.linear(
              mediaQuery.textScaleFactor.clamp(1.0, 1.1),
            ),
          ),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'FIXIFY Partner',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF217043),
              ),
              useMaterial3: true,
              fontFamily: 'Roboto',
            ),

            // 🔤 Force English for Material widgets
            locale: const Locale('en'),
            supportedLocales: const [Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            home: const LocationAccessGate(child: AuthWrapper()),
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

class LocationAccessGate extends ConsumerStatefulWidget {
  final Widget child;

  const LocationAccessGate({super.key, required this.child});

  @override
  ConsumerState<LocationAccessGate> createState() => _LocationAccessGateState();
}

class _LocationAccessGateState extends ConsumerState<LocationAccessGate>
    with WidgetsBindingObserver {
  bool _isCheckingPermission = true;
  bool _isUpdatingLocationOnResume = false;
  PermissionStatus? _permissionStatus;
  bool _isLocationServiceEnabled = false;

  bool get _canAccessApp =>
      _permissionStatus?.isGranted == true && _isLocationServiceEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission(requestIfNeeded: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission(updateLocationIfAuthenticated: true);
    }
  }

  Future<void> _checkLocationPermission({
    bool requestIfNeeded = false,
    bool updateLocationIfAuthenticated = false,
  }) async {
    if (!mounted) return;

    setState(() {
      _isCheckingPermission = true;
    });

    final isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();
    var status = await Permission.location.status;
    if (isLocationServiceEnabled && requestIfNeeded && status.isDenied) {
      status = await Permission.location.request();
    }

    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _isLocationServiceEnabled = isLocationServiceEnabled;
      _isCheckingPermission = false;
    });

    if (updateLocationIfAuthenticated &&
        status.isGranted &&
        isLocationServiceEnabled) {
      await _updateLocationIfAuthenticated();
    }
  }

  Future<void> _updateLocationIfAuthenticated() async {
    if (_isUpdatingLocationOnResume) return;

    final authToken = ref.read(authProvider).authToken;
    if (authToken == null || authToken.isEmpty) return;

    _isUpdatingLocationOnResume = true;
    final result = await ref.read(userServiceProvider).updatePartnerLocation();
    _isUpdatingLocationOnResume = false;

    result.fold(
      (failure) {
        print(
          '❌ [LocationAccessGate] Failed to update partner location on resume: ${failure.message}',
        );
      },
      (_) {
        print('✅ [LocationAccessGate] Partner location updated on resume');
      },
    );
  }

  Future<void> _requestPermission() async {
    final isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      await Geolocator.openLocationSettings();
      await _checkLocationPermission(requestIfNeeded: true);
      return;
    }

    final currentStatus = await Permission.location.status;

    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      await openAppSettings();
      await _checkLocationPermission();
      return;
    }

    await _checkLocationPermission(requestIfNeeded: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const LocationBlockedScreen(isChecking: true);
    }

    if (_canAccessApp) {
      return widget.child;
    }

    return LocationBlockedScreen(
      isLocationServiceDisabled: !_isLocationServiceEnabled,
      isPermanentlyDenied:
          _permissionStatus?.isPermanentlyDenied == true ||
          _permissionStatus?.isRestricted == true,
      onEnableLocation: _requestPermission,
    );
  }
}

class LocationBlockedScreen extends StatelessWidget {
  final bool isChecking;
  final bool isLocationServiceDisabled;
  final bool isPermanentlyDenied;
  final VoidCallback? onEnableLocation;

  const LocationBlockedScreen({
    super.key,
    this.isChecking = false,
    this.isLocationServiceDisabled = false,
    this.isPermanentlyDenied = false,
    this.onEnableLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBCD4C6), Color(0xFFF7F8F7)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/Group 2.png',
                  height: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  isChecking
                      ? 'Checking location permission'
                      : isLocationServiceDisabled
                      ? 'Turn On Location'
                      : 'Location Permission Required',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isChecking
                      ? 'Please wait while we verify access.'
                      : isLocationServiceDisabled
                      ? 'Device location is turned off. Please turn on location services to continue using the app.'
                      : isPermanentlyDenied
                      ? 'Location access is blocked from settings. Please enable location permission to continue using the app.'
                      : 'This app needs location permission to work. Please allow location access to continue.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 30),
                if (isChecking)
                  const CircularProgressIndicator(color: Color(0xFF217043))
                else
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onEnableLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF217043),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: Text(
                        isLocationServiceDisabled
                            ? 'Turn On Location'
                            : isPermanentlyDenied
                            ? 'Open App Settings'
                            : 'Allow Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Wait a bit for the auth provider to initialize and check SharedPreferences
    await Future.delayed(const Duration(milliseconds: 1000));

    // Force the auth provider to check login status
    try {
      await ref.read(authProvider.notifier).checkLoginStatus();
    } catch (e) {
      print('Error in _checkAuthStatus: $e');
    }

    setState(() {
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    print('AuthWrapper - _isCheckingAuth: $_isCheckingAuth');
    print('AuthWrapper - Auth token: ${authState.authToken}');
    print('AuthWrapper - User token: ${authState.userToken}');
    print('AuthWrapper - Is verified: ${authState.isVerified}');

    // Show splash screen while checking authentication
    if (_isCheckingAuth) {
      print('AuthWrapper - Still checking auth, showing SplashScreen');
      return const SplashScreen();
    }

    // Let splash screen handle the navigation logic
    print(
      'AuthWrapper - Auth check complete, showing SplashScreen for navigation',
    );
    return const SplashScreen();
  }
}
