import 'package:fixify_admin/services/translation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocalizations {
  final WidgetRef ref;

  AppLocalizations(this.ref);

  String get(String key, {Map<String, String>? params}) {
    return TranslationService.translate(key, params: params);
  }
}

extension LocalizationExtension on WidgetRef {
  AppLocalizations get l10n => AppLocalizations(this);
}
