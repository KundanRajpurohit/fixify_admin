import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/providers/location_provider.dart'
    show userServiceProvider;
import 'package:fixify_admin/screens/dashboard/bank_accounts_screen.dart';
import 'package:fixify_admin/screens/dashboard/edit_profile_screen.dart';
import 'package:fixify_admin/screens/dashboard/privacy_policy_screen.dart';
import 'package:fixify_admin/screens/dashboard/terms_of_service_screen.dart';
import 'package:fixify_admin/screens/settings/earnings_dashboard_screen.dart';
import 'package:fixify_admin/screens/settings/revieW_page.dart';
import 'package:fixify_admin/screens/settings/transaction_history.dart';
import 'package:fixify_admin/services/user_service.dart';
import 'package:fixify_admin/widgets/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _screenLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getPartnerProfile();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        (data) {
          if (mounted) {
            setState(() {
              _profileData = data['data'];
              _notificationsEnabled = _profileData?['notification'] ?? false;
              _screenLockEnabled = _profileData?['screen_lock'] ?? false;
              _isLoading = false;
            });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: CustomAppBar(title: 'My Profile', showbackButton: false),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      _buildDocumentsSection(),
                      _buildEarningsSection(),
                      _buildRatingSection(),
                      _buildNotificationSection(),
                      _buildLegalSection(),
                      _buildLogoutButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
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
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = _profileData?['name'] ?? 'N/A';
    final mobile = _profileData?['mobile'] ?? 'N/A';
    final imageUrl = _profileData?['image'];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeft,
                    child: const EditProfileScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF217043),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FontAwesomeIcons.solidPenToSquare,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                child:
                    imageUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Name:', name),
          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade300),
          const SizedBox(height: 6),
          _buildInfoRow('Contact', '+91 $mobile'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 17, color: Color(0xff111928))),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    final nationalIdVerified =
        _profileData?['national_id_verification'] ?? false;
    final proofNationalIdVerified =
        _profileData?['proof_national_id_verification'] ?? false;
    final servicesLicenseVerified =
        _profileData?['services_license_verification'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Document\'s',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentItem('Aadhaar Card', nationalIdVerified),
          const Divider(height: 24),
          _buildDocumentItem('Address Proof', proofNationalIdVerified),
          const Divider(height: 24),
          _buildDocumentItem(
            'Service License (if applicable)',
            servicesLicenseVerified,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, bool isVerified) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, color: Color(0xff111928)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isVerified
                    ? AppColors.secondary.withOpacity(0.2)
                    : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isVerified ? 'Verified' : 'In review',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified ? AppColors.primary : Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings & Payments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            icon: Icons.account_balance_wallet,
            title: 'Earnings Dashboard',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EarningsDashboardScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          _buildMenuItem(
            icon: Icons.swap_horiz,
            title: 'Transaction History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          _buildMenuItem(
            icon: Icons.account_balance,
            title: 'My Bank Account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BankAccountsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMenuItem(
        icon: Icons.star,
        title: 'My Rating & Reviews',
        onTap: () {
          // Navigate to rating & reviews
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RatingPage()),
          );
        },
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notification & Security',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildToggleItem(
            icon: Icons.notifications,
            title: 'Notifications On/Off',
            value: _notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Check for notification permission
                final status = await Permission.notification.status;

                if (status.isDenied || status.isPermanentlyDenied) {
                  // Show permission dialog
                  final shouldRequest = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Notification Permission Required'),
                          content: Text(
                            status.isPermanentlyDenied
                                ? 'Notifications are disabled for this app. Please enable them in your device settings to receive notifications.'
                                : 'To enable notifications, please grant notification permission.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Open Settings'),
                            ),
                          ],
                        ),
                  );

                  if (shouldRequest == true) {
                    if (status.isPermanentlyDenied) {
                      // Open app settings directly if permanently denied
                      await openAppSettings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enable "All fixify_admin notifications" in settings',
                            ),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                      return;
                    } else {
                      // Try to request permission
                      final result = await Permission.notification.request();
                      if (!result.isGranted) {
                        if (mounted) {
                          // Open app settings if permission still not granted
                          await openAppSettings();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enable notifications in settings',
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        return;
                      }
                    }
                  } else {
                    return; // User cancelled
                  }
                } else if (!status.isGranted) {
                  // If status is not granted but not denied, try requesting
                  final result = await Permission.notification.request();
                  if (!result.isGranted) {
                    if (mounted) {
                      await openAppSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enable notifications in settings',
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                    return;
                  }
                }
              }

              // Update notification setting via API
              final userService = ref.read(userServiceProvider);
              final result = await userService.updateNotification(value);

              result.fold(
                (failure) {
                  if (mounted) {
                    setState(() {
                      _notificationsEnabled = !value; // Revert on failure
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update notification: ${failure.message}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                (data) {
                  if (mounted) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  }
                },
              );
            },
          ),
          const Divider(height: 24),
          _buildToggleItem(
            icon: Icons.lock,
            title: 'Screen Lock',
            value: _screenLockEnabled,
            onChanged: (value) {
              setState(() {
                _screenLockEnabled = value;
              });
              // TODO: Update screen lock setting via API
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legal Pages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 24),
          _buildMenuItem(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMenuItem(
        icon: Icons.logout,
        title: 'Logout',
        onTap: () {
          showDialog(
            context: context,
            builder:
                (context) => LogoutDialog(
                  onLogout: () async {
                    Navigator.of(context).pop(); // Close dialog

                    // Call logout API (will clear preferences even on 401)
                    final userService = ref.read(userServiceProvider);
                    final result = await userService.partnerLogout();

                    // Always clear auth state and navigate, regardless of API result
                    await ref.read(authProvider.notifier).logout();

                    // Navigation will be handled by auth state change
                    if (mounted) {
                      result.fold(
                        (failure) {
                          // Even if API fails, we've cleared preferences
                          print(
                            '⚠️ [ProfileScreen] Logout API failed but preferences cleared',
                          );
                        },
                        (data) {
                          print('✅ [ProfileScreen] Logout successful');
                        },
                      );
                    }
                  },
                  onCancel: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, color: Colors.black),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, color: Colors.black87),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
