import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

// Models
class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      dialCode: json['dial_code'] ?? '',
      flag: json['flag'] ?? '',
    );
  }
}

class PhoneVerificationState {
  final String? phoneNumber;
  final String? countryCode;
  final String? sessionId;
  final bool isLoading;
  final String? error;
  final bool isVerified;
  final String? otp;
  final String? userId;
  final String? userToken;
  final String? authToken;

  PhoneVerificationState({
    this.phoneNumber,
    this.countryCode,
    this.sessionId,
    this.isLoading = false,
    this.error,
    this.isVerified = false,
    this.otp,
    this.userId,
    this.userToken,
    this.authToken,
  });

  PhoneVerificationState copyWith({
    String? phoneNumber,
    String? countryCode,
    String? sessionId,
    bool? isLoading,
    String? error,
    bool? isVerified,
    String? otp,
    String? userId,
    String? userToken,
    String? authToken,
  }) {
    return PhoneVerificationState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isVerified: isVerified ?? this.isVerified,
      otp: otp ?? this.otp,
      userId: userId ?? this.userId,
      userToken: userToken ?? this.userToken,
      authToken: authToken ?? this.authToken,
    );
  }
}

// Auth Provider
class AuthNotifier extends StateNotifier<PhoneVerificationState> {
  final UserService _userService;

  AuthNotifier(this._userService) : super(PhoneVerificationState()) {
    checkLoginStatus();
  }

  // SharedPreferences keys
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _phoneNumberKey = 'phone_number';
  static const String _countryCodeKey = 'country_code';
  static const String _userIdKey = 'user_id';
  static const String _userTokenKey = 'user_token';
  static const String _authTokenKey = 'authorization_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<void> checkLoginStatus() async {
    try {
      print('Starting auth check...');

      // Test SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      print('SharedPreferences instance created successfully');

      // Try to read a simple value first
      final testValue = prefs.getString('test_key');
      print('Test read successful, value: $testValue');

      // Now read the actual auth values
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final savedPhoneNumber = prefs.getString(_phoneNumberKey) ?? '';
      final savedCountryCode = prefs.getString(_countryCodeKey) ?? '';
      final savedUserId = prefs.getString(_userIdKey) ?? '';
      final savedUserToken = prefs.getString(_userTokenKey) ?? '';
      final savedAuthToken = prefs.getString(_authTokenKey) ?? '';

      print(
        'Auth Check - isLoggedIn: $isLoggedIn, phoneNumber: $savedPhoneNumber',
      );

      if (isLoggedIn &&
          savedPhoneNumber.isNotEmpty &&
          savedAuthToken.isNotEmpty) {
        state = state.copyWith(
          isVerified: true,
          phoneNumber: savedPhoneNumber,
          countryCode: savedCountryCode,
          userId: savedUserId,
          userToken: savedUserToken,
          authToken: savedAuthToken,
        );
        print('Auth Check - User is verified and logged in');
      } else {
        print('Auth Check - User is not logged in');
      }
    } catch (e) {
      print('Error checking login status: $e');
      print('Error type: ${e.runtimeType}');
      // If SharedPreferences fails, assume user is not logged in
      state = state.copyWith(isVerified: false);
    }
  }

  Future<void> _saveLoginStatus(
    String phoneNumber,
    String countryCode,
    String userId,
    String userToken,
    String authToken,
    String refreshToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_phoneNumberKey, phoneNumber);
      await prefs.setString(_countryCodeKey, countryCode);
      if (userId.isNotEmpty) {
        await prefs.setString(_userIdKey, userId);
      }
      if (userToken.isNotEmpty) {
        await prefs.setString(_userTokenKey, userToken);
      }
      await prefs.setString(_authTokenKey, authToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      print(
        'Login status saved - phoneNumber: $phoneNumber, countryCode: $countryCode, userId: $userId, userToken: $userToken , refreshtoken: $refreshToken',
      );
    } catch (e) {
      print('Error saving login status: $e');
    }
  }

  Future<void> _clearLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_phoneNumberKey);
      await prefs.remove(_countryCodeKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userTokenKey);
      await prefs.remove(_authTokenKey);
    } catch (e) {
      print('Error clearing login status: $e');
    }
  }

  Future<bool> verifyOTP(String otp) async
  {
    print('🔐 [AuthProvider] Starting verifyOTP...');
    print('🔢 [AuthProvider] OTP to verify: $otp');
    print('📱 [AuthProvider] Phone number: ${state.phoneNumber}');
    print('👤 [AuthProvider] User ID: ${state.userId}');
    print('🔑 [AuthProvider] User Token: ${state.userToken}');

    if (state.phoneNumber == null) {
      print('❌ [AuthProvider] Phone number is null');
      state = state.copyWith(
        error: 'Phone number not found. Please request OTP again.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    print('⏳ [AuthProvider] Set isLoading to true');

    try {
      print('📤 [AuthProvider] Calling UserService.verifyOtp...');
      final result = await _userService.verifyOtp(
        mobile: state.phoneNumber!,
        otp: otp,
      );

      print('📥 [AuthProvider] VerifyOTP result received');
      return result.fold(
        (failure) {
          print('❌ [AuthProvider] VerifyOTP failed: ${failure.message}');
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (data) async {
          print('✅ [AuthProvider] VerifyOTP successful');
          print('📊 [AuthProvider] Response data: $data');
          print('🔑 [AuthProvider] Auth token: ${data['token']}');

          // Save login status to SharedPreferences
          // For login flow, userId and userToken might be null, so use empty strings or get from response
          print('💾 [AuthProvider] Saving login status...');
          final userId = state.userId ?? data['data']?['id']?.toString() ?? '';
          final userToken =
              state.userToken ?? data['data']?['partnerid']?.toString() ?? '';
          final countryCode = state.countryCode ?? '+91';

          await _saveLoginStatus(
            state.phoneNumber ?? '',
            countryCode,
            userId,
            userToken,
            data['token'],
            data['refresh_token'] ?? '',
          );
          print('✅ [AuthProvider] Login status saved');

          state = state.copyWith(
            isLoading: false,
            isVerified: true,
            authToken: data['token'],
            userId: userId.isNotEmpty ? userId : state.userId,
            userToken: userToken.isNotEmpty ? userToken : state.userToken,
            error: null,
          );
          print('✅ [AuthProvider] State updated - user verified');
          return true;
        },
      );
    } catch (e) {
      print('❌ [AuthProvider] VerifyOTP exception: $e');
      print('❌ [AuthProvider] Exception type: ${e.runtimeType}');
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  // Set user data from default address response
  void setUserData(String userId, String userToken) {
    state = state.copyWith(userId: userId, userToken: userToken);
  }

  Future<void> logout() async {
    await _clearLoginStatus();
    state = PhoneVerificationState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = PhoneVerificationState();
  }
}

// Providers
final authProvider =
    StateNotifierProvider<AuthNotifier, PhoneVerificationState>((ref) {
      final userService = ref.watch(userServiceProvider);
      return AuthNotifier(userService);
    });

// Country data provider
final countriesProvider = Provider<List<Country>>((ref) {
  return [
    Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    Country(
      name: 'United Arab Emirates',
      code: 'AE',
      dialCode: '+971',
      flag: '🇦🇪',
    ),
    Country(name: 'Andorra', code: 'AD', dialCode: '+376', flag: '🇦🇩'),
    Country(name: 'Afghanistan', code: 'AF', dialCode: '+93', flag: '🇦🇫'),
    Country(
      name: 'Antigua & Barbuda',
      code: 'AG',
      dialCode: '+1',
      flag: '🇦🇬',
    ),
    Country(name: 'Anguilla', code: 'AI', dialCode: '+1', flag: '🇦🇮'),
    Country(name: 'Albania', code: 'AL', dialCode: '+355', flag: '🇦🇱'),
    Country(name: 'Armenia', code: 'AM', dialCode: '+374', flag: '🇦🇲'),
    Country(name: 'Angola', code: 'AO', dialCode: '+244', flag: '🇦🇴'),
    Country(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
    Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    Country(name: 'Austria', code: 'AT', dialCode: '+43', flag: '🇦🇹'),
    Country(name: 'Azerbaijan', code: 'AZ', dialCode: '+994', flag: '🇦🇿'),
    Country(name: 'Bahamas', code: 'BS', dialCode: '+1', flag: '🇧🇸'),
    Country(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
    Country(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    Country(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
    Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    Country(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    Country(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    Country(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    Country(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    Country(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    Country(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  ];
});

// Selected country provider
final selectedCountryProvider = StateProvider<Country>((ref) {
  final countries = ref.watch(countriesProvider);
  return countries.firstWhere(
    (country) => country.code == 'IN',
  ); // Default to India
});
