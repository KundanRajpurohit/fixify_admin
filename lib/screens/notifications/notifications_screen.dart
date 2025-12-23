import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/models/notification_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationItem> _notifications = [];
  Set<String> _markingAsRead = {}; // Track which notifications are being marked as read

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getNotifications();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _errorMessage = failure.message;
              _isLoading = false;
            });
          }
        },
        (data) {
          if (mounted) {
            setState(() {
              _notifications = data.notifications;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (notification.markAsRead || _markingAsRead.contains(notification.notificationToken)) {
      return;
    }

    setState(() {
      _markingAsRead.add(notification.notificationToken);
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.markNotificationAsRead(
        notificationToken: notification.notificationToken,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _markingAsRead.remove(notification.notificationToken);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
          setState(() {
            _markingAsRead.remove(notification.notificationToken);
            // Update the notification in the list
            final index = _notifications.indexWhere(
              (n) => n.notificationToken == notification.notificationToken,
            );
            if (index != -1) {
              _notifications[index] = NotificationItem(
                message: notification.message,
                createdAt: notification.createdAt,
                markAsRead: true,
                notificationToken: notification.notificationToken,
              );
            }
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _markingAsRead.remove(notification.notificationToken);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CustomAppBar(title: 'Notifications', showbackButton: true),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF217043)),
              ),
            )
          : _errorMessage != null && _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF217043),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'re all caught up!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: const Color(0xFF217043),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _NotificationCard(
                            notification: notification,
                            onTap: () => _markAsRead(notification),
                            isMarkingAsRead: _markingAsRead.contains(notification.notificationToken),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final bool isMarkingAsRead;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.isMarkingAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: notification.markAsRead ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.markAsRead
                ? Colors.grey.shade200
                : const Color(0xFF217043),
            width: notification.markAsRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: notification.markAsRead
                    ? Colors.grey.shade200
                    : const Color(0xFF217043).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications,
                color: notification.markAsRead
                    ? Colors.grey.shade400
                    : const Color(0xFF217043),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.markAsRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (!notification.markAsRead && !isMarkingAsRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF217043),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (isMarkingAsRead)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF217043),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

