import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/providers/location_provider.dart'
    show userServiceProvider;
import 'package:fixify_admin/screens/dashboard/bank_accounts_screen.dart';
import 'package:fixify_admin/screens/settings/earnings_dashboard_screen.dart';
import 'package:fixify_admin/screens/settings/revieW_page.dart';
import 'package:fixify_admin/screens/settings/transaction_history.dart';
import 'package:fixify_admin/services/user_service.dart';
import 'package:fixify_admin/widgets/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      _buildHeader(),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Name:', name),
          const SizedBox(height: 12),
          _buildInfoRow('Contact', '+91 $mobile'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
            color: Colors.black.withOpacity(0.05),
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
          style: const TextStyle(fontSize: 14, color: Colors.black87),
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
            color: Colors.black.withOpacity(0.05),
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
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              // TODO: Update notification setting via API
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
              // Navigate to privacy policy
            },
          ),
          const Divider(height: 24),
          _buildMenuItem(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () {
              // Navigate to terms of service
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
            color: Colors.black.withOpacity(0.05),
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
                    await ref.read(authProvider.notifier).logout();
                    // Navigation will be handled by auth state change
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
              style: const TextStyle(fontSize: 14, color: Colors.black87),
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
            style: const TextStyle(fontSize: 14, color: Colors.black87),
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
