import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/models/notification_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final bool showbackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showbackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90); // adjust height as needed

  @override
  ConsumerState<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends ConsumerState<CustomAppBar> {
  List<NotificationItem> _notifications = [];
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (_isLoadingNotifications) return;

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getNotifications();

      result.fold(
        (failure) {
          // Silently fail - don't show error in app bar
          if (mounted) {
            setState(() {
              _isLoadingNotifications = false;
            });
          }
        },
        (data) {
          if (mounted) {
            setState(() {
              _notifications = data.notifications;
              _isLoadingNotifications = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => !n.markAsRead).length;
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        duration: const Duration(milliseconds: 300),
        child: const NotificationsScreen(),
      ),
    ).then((_) {
      // Reload notifications when returning from notifications screen
      _loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: topPadding + 80, // total height
      child: Column(
        children: [
          // Status bar color area
          Container(height: topPadding, color: AppColors.secondary),

          // Actual toolbar
          Container(
            color: AppColors.secondary,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    widget.showbackButton
                        ? IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                        )
                        : const SizedBox.shrink(),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _navigateToNotifications,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color(0xFF217043),
                          size: 24,
                        ),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          top: 6,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              color: const Color(0xFF217043),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _unreadCount > 9 ? '9+' : '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
