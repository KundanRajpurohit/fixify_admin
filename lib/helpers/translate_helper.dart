import 'package:fixify_admin/helpers/app_localizations.dart';
import 'package:fixify_admin/services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper class to easily access translations in widgets
///
/// Usage:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final t = ref.l10n;
///     return Text(t.get('common.continue'));
///   }
/// }
/// ```
///
/// Or for parameters:
/// ```dart
/// t.get('withdraw.minimum_withdrawal', params: {'amount': '500'})
/// ```

extension TranslationExtension on WidgetRef {
  /// Quick access to translations
  String t(String key, {Map<String, String>? params}) {
    return AppLocalizations(this).get(key, params: params);
  }
}

/// Direct translation helper without needing WidgetRef
class T {
  static String get(String key, {Map<String, String>? params}) {
    return TranslationService.translate(key, params: params);
  }
}
