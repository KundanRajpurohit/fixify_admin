// token_manager.dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _accessKey = 'authorization_token'; // Use existing key from UserService
  static const _refreshKey = 'refresh_token';
  
  SharedPreferences? _prefs;
  
  // Initialize SharedPreferences (call this before using TokenManager)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  Future<String?> getAccessToken() async {
    await init();
    return _prefs!.getString(_accessKey);
  }
  
  Future<String?> getRefreshToken() async {
    await init();
    return _prefs!.getString(_refreshKey);
  }
  
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await init();
    await _prefs!.setString(_accessKey, accessToken);
    await _prefs!.setString(_refreshKey, refreshToken);
  }
  
  Future<void> clearTokens() async {
    await init();
    await _prefs!.remove(_accessKey);
    await _prefs!.remove(_refreshKey);
  }
}
