import 'package:fixify_admin/config/app_colors.dart';
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
  @override
  Widget build(BuildContext context) {
    // final notificationCount = ref.watch(notificationCountProvider);

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
                          onPressed: () => Navigator.pop(context),
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
                  onTap: () {
                    // Navigator.push(
                    //   context,
                    //   PageTransition(
                    //     type: PageTransitionType.rightToLeft,
                    //     duration: const Duration(milliseconds: 300),
                    //     child: const NotificationDetailScreen(),
                    //   ),
                    // );
                  },
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
                      if (0 > 0)
                        Positioned(
                          top: 6,
                          right: 8,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              color: const Color(0xFF217043),
                              shape: BoxShape.circle,
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
