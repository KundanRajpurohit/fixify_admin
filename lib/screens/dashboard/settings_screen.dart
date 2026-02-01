import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/language_provider.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/settings/language_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';

import '../../components/custom_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<String, bool> _weeklyAvailability = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  
  bool _isLoading = true;
  bool _isUpdating = false;

  String _getDayInitial(String day) {
    return day.substring(0, 1).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getWeeklyAvailability();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${ref.t('settings.failed_to_load_availability')}: ${failure.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (data) {
          if (mounted) {
            final availabilityData = data['data'] as Map<String, dynamic>?;
            if (availabilityData != null) {
              setState(() {
                // Map API response (lowercase days, string "true"/"false") to UI state
                _weeklyAvailability['Monday'] = availabilityData['mon']?.toString().toLowerCase() == 'true';
                _weeklyAvailability['Tuesday'] = availabilityData['tue']?.toString().toLowerCase() == 'true';
                _weeklyAvailability['Wednesday'] = availabilityData['wed']?.toString().toLowerCase() == 'true';
                _weeklyAvailability['Thursday'] = availabilityData['thu']?.toString().toLowerCase() == 'true';
                _weeklyAvailability['Friday'] = availabilityData['fri']?.toString().toLowerCase() == 'true';
                _weeklyAvailability['Saturday'] = availabilityData['sat']?.toString().toLowerCase() == 'true';
                _weeklyAvailability['Sunday'] = availabilityData['sun']?.toString().toLowerCase() == 'true';
                _isLoading = false;
              });
            } else {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ref.t('common.error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDayAvailability(String day, bool value) async {
    // Optimistically update UI
    setState(() {
      _weeklyAvailability[day] = value;
      _isUpdating = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.updateDayAvailability(day, value);

      result.fold(
        (failure) {
          if (mounted) {
            // Revert on failure
            setState(() {
              _weeklyAvailability[day] = !value;
              _isUpdating = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${ref.t('settings.failed_to_update_availability')}: ${failure.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        (data) {
          if (mounted) {
            setState(() {
              _isUpdating = false;
            });
            // Show success message briefly
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${ref.t('settings.availability_updated').replaceAll('{day}', ref.t('settings.${day.toLowerCase()}'))}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        // Revert on error
        setState(() {
          _weeklyAvailability[day] = !value;
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ref.t('common.error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: CustomAppBar(title: ref.t('settings.settings'), showbackButton: false),
      body: Column(
        children: [
          // Header

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Language Selection Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransition(
                                type: PageTransitionType.rightToLeft,
                                duration: const Duration(milliseconds: 300),
                                child: const LanguageSelectionScreen(),
                              ),
                            ).then((shouldReload) {
                              if (shouldReload == true) {
                                // Reload or rebuild if needed
                                setState(() {});
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 16),
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.language,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ref.t('settings.language'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final currentLanguage = ref.watch(languageProvider);
                                            return Text(
                                              currentLanguage.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Set Weekly Availability Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.t('settings.set_weekly_availability'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ..._weeklyAvailability.entries.map((entry) {
                                final day = entry.key;
                                final isAvailable = entry.value;
                                final isLast = entry == _weeklyAvailability.entries.last;

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Day Initial Icon
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getDayInitial(day),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Day Name
                                        Expanded(
                                          child: Text(
                                            ref.t('settings.${day.toLowerCase()}'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        // Toggle Switch
                                        Switch(
                                          value: isAvailable,
                                          onChanged: _isUpdating
                                              ? null
                                              : (value) {
                                                  _updateDayAvailability(day, value);
                                                },
                                          activeColor: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    if (!isLast) ...[
                                      const SizedBox(height: 16),
                                      Divider(
                                        height: 1,
                                        color: Colors.grey.shade200,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}



