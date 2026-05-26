import 'dart:convert';

import 'package:fixify_admin/providers/language_provider.dart';
import 'package:flutter/services.dart';

class TranslationService {
  static Map<String, dynamic> _localizedStrings = {};
  static AppLanguage _currentLanguage = AppLanguage.english;

  static Future<void> loadTranslations(AppLanguage language) async {
    _currentLanguage = language;
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/translations/${language.code}.json',
      );
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading translations for ${language.code}: $e');
      // Fallback to English if translation file doesn't exist
      if (language.code != 'en') {
        try {
          final String jsonString = await rootBundle.loadString(
            'assets/translations/en.json',
          );
          _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
        } catch (e2) {
          print('Error loading English translations: $e2');
        }
      }
    }
  }

  static Future<void> reloadTranslations(AppLanguage language) async {
    await loadTranslations(language);
  }

  static String translate(String key, {Map<String, String>? params}) {
    final keys = key.split('.');
    dynamic value = _localizedStrings;

    for (final k in keys) {
      if (value is Map<String, dynamic>) {
        value = value[k];
      } else {
        return key; // Return key if not found
      }
    }

    if (value == null) {
      return key; // Return key if not found
    }

    String result = value.toString();

    // Replace parameters
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        result = result.replaceAll('{$paramKey}', paramValue);
      });
    }

    return result;
  }

  static AppLanguage get currentLanguage => _currentLanguage;
}
