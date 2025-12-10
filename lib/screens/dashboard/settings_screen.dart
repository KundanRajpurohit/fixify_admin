import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  String _getDayShortName(String day) {
    return day.substring(0, 3);
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
                content: Text('Failed to load availability: ${failure.message}'),
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
            content: Text('Error: ${e.toString()}'),
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
                content: Text('Failed to update availability: ${failure.message}'),
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
                content: Text('${day} availability updated'),
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
            content: Text('Error: ${e.toString()}'),
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
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Setting',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Color(0xFF217043),
                          size: 22,
                        ),
                        onPressed: () {
                          // Handle notifications
                        },
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
                              const Text(
                                'Set Weekly Availability',
                                style: TextStyle(
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
                                            _getDayShortName(day),
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



