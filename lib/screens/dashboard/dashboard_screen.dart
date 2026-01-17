import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'my_jobs_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomePageScreen extends StatefulWidget {
  final int initialIndex;
  final String? userId;
  final String? sessionId;

  const HomePageScreen({
    super.key,
    this.initialIndex = 0,
    this.userId,
    this.sessionId,
  });

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  late int _selectedIndex;
  final ValueNotifier<int> _tabNotifier = ValueNotifier<int>(0);

  final List<IconData> _icons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.clipboardList,
    FontAwesomeIcons.gear,
    FontAwesomeIcons.user,
  ];

  final List<String> _labels = ['Home', 'My Jobs', 'Settings', 'Profile'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabNotifier.value = _selectedIndex;
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    _tabNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(tabNotifier: _tabNotifier),
      MyJobsScreen(),
      const SettingsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          // Exit the app when back button is pressed on this screen
          SystemNavigator.pop();
          return false;
        },
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: SizedBox(
              height: 50,
              child: Stack(
                children: [
                  // Animated sliding indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    left: _getIndicatorPosition(),
                    top: 5,
                    child: Container(
                      height: 40,
                      width: _getIndicatorWidth(),
                      decoration: BoxDecoration(
                        color: const Color(0xFF217043),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  // Navigation items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (index) => Expanded(
                        child: _buildNavItem(
                          index: index,
                          icon: _icons[index],
                          label: _labels[index],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition() {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 16) / 4;
    return 8 +
        (itemWidth * _selectedIndex) +
        (itemWidth - _getIndicatorWidth()) / 2;
  }

  double _getIndicatorWidth() {
    switch (_selectedIndex) {
      case 0:
        return 95.0; // Home
      case 1:
        return 115.0; // Search
      case 2:
        return 115.0; // Cart
      case 3:
        return 90.0; // Profile
      default:
        return 100.0;
    }
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isSelected ? 1.0 : 1.0,
                  child: Row(
                    children: [
                      SizedBox(width: !isSelected ? 0 : 6),
                      Icon(
                        icon,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 3 : 0,
            ),
            SizedBox(width: !isSelected ? 0 : 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isSelected ? 12 : 0,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              child: Text(
                isSelected ? label : '',
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
