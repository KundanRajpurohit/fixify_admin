import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  hindi('hi', 'हिंदी');

  final String code;
  final String name;

  const AppLanguage(this.code, this.name);
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  static const String _languageKey = 'app_language';
  static const String _languageSelectedKey = 'language_selected';

  LanguageNotifier() : super(AppLanguage.english) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      
      final language = AppLanguage.values.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => AppLanguage.english,
      );
      
      state = language;
    } catch (e) {
      print('Error loading language: $e');
      state = AppLanguage.english;
    }
  }

  /// Check if user has selected a language before
  /// Returns true if either the flag is set OR a language code is stored
  Future<bool> hasLanguageBeenSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if language selection flag is set
      final flagSet = prefs.getBool(_languageSelectedKey) ?? false;
      
      // Also check if a language code is stored (fallback check)
      final languageCode = prefs.getString(_languageKey);
      final languageStored = languageCode != null && languageCode.isNotEmpty;
      
      // Return true if either condition is met
      final hasSelected = flagSet || languageStored;
      
      print('🌐 [LanguageProvider] Language selection check:');
      print('   Flag set: $flagSet');
      print('   Language stored: $languageStored (code: $languageCode)');
      print('   Has selected: $hasSelected');
      
      return hasSelected;
    } catch (e) {
      print('❌ [LanguageProvider] Error checking language selection: $e');
      return false;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
      await prefs.setBool(_languageSelectedKey, true); // Mark language as selected
      state = language;
    } catch (e) {
      print('Error saving language: $e');
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

