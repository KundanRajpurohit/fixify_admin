import 'package:dio/dio.dart';
import 'package:fixify_admin/config/api_config.dart';
import 'package:fixify_admin/dio/auth_interceptor.dart';
import 'package:fixify_admin/dio/unauth_interceptor.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/auth/splash_screen.dart';
import 'package:fixify_admin/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for handling 401 redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  try {
    await SharedPreferences.getInstance();
    print('SharedPreferences initialized successfully');
  } catch (e) {
    print('Failed to initialize SharedPreferences: $e');
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
        '/partner/upcoming-jobs',
        '/partner/cancelled-jobs',
        '/partner/ongoing-jobs',
        '/partner/past-jobs',
        '/partner/assign-upcoming-jobs',
        '/partner/accept-job',
        '/partner/assign-job',
        '/partner/verify-job-otp',
        '/partner/job-completed',
        '/partner/submit-job-report',
        '/partner/rating-customer',
        '/partner/single-job-details',
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
      ],
    ),
  );
  
  // Add unauthorized interceptor LAST to handle 401 errors from all endpoints
  // This ensures it catches 401 errors after all other interceptors have processed
  dio.interceptors.add(
    UnauthorizedInterceptor(navigatorKey: navigatorKey),
  );

  print('🔧 [Main] Dio initialized with base URL: ${ApiConfig.baseUrl}');
  final userService = UserService(dio);
  print('👤 [Main] UserService initialized');

  runApp(
    ProviderScope(
      overrides: [
        userServiceProvider.overrideWithValue(userService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'FIXIFY',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF217043),
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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