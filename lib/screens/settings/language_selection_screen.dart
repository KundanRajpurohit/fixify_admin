import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/main.dart' show navigatorKey;
import 'package:fixify_admin/providers/language_provider.dart';
import 'package:fixify_admin/screens/dashboard/dashboard_screen.dart'
    show HomePageScreen;
import 'package:fixify_admin/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  bool _isLoading = false;

  Future<void> _changeLanguage(AppLanguage language) async {
    final currentLanguage = ref.read(languageProvider);
    if (language == currentLanguage) {
      // Already selected
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load translations first
      await TranslationService.loadTranslations(language);

      // Then update language provider (this will trigger rebuilds)
      await ref.read(languageProvider.notifier).setLanguage(language);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.t('settings.language_changed_successfully')),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        // Restart app by navigating to home and clearing all previous routes
        Future.delayed(const Duration(milliseconds: 800), () {
          if (navigatorKey.currentState != null && mounted) {
            // Pop current language selection screen first
            Navigator.of(context).pop();

            // Clear all routes and navigate to home screen to restart the app
            Future.delayed(const Duration(milliseconds: 300), () {
              if (navigatorKey.currentState != null) {
                navigatorKey.currentState!.pushAndRemoveUntil(
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 500),
                    child: const HomePageScreen(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              }
            });
          } else {
            // Fallback: just pop if navigator key is not available
            if (mounted) {
              Navigator.pop(context, true);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: CustomAppBar(
        title: ref.t('settings.select_language'),
        showbackButton: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ...AppLanguage.values.map((language) {
                            final isSelected =
                                currentLanguage.code == language.code;
                            return GestureDetector(
                              onTap: () => _changeLanguage(language),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? AppColors.secondary.withOpacity(0.1)
                                          : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade300,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          language.code.toUpperCase(),
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            language.name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            language.code == 'hi'
                                                ? 'Hindi'
                                                : 'English',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
