import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/screens/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPendingScreen extends ConsumerWidget {
  const AccountPendingScreen({super.key});

  static const Color _surface = Color(0xFFF6F7F9);
  static const Color _warning = Color(0xFFF59E0B);
  static const String _supportEmail = 'info@fixify.expert';

  Future<void> _contactSupport(BuildContext context, WidgetRef ref) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Fixify partner account activation support',
        'body':
            'Hi Fixify Support,\n\nPlease help me with my partner account activation.\n\nMobile number:\nIssue details:\n',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.t('common.support_email')),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final documentsSubmitted = authState.hasSubmittedDocuments;
    final titleKey =
        documentsSubmitted
            ? 'auth.documents_in_review_title'
            : 'auth.account_not_active';
    final descriptionKey =
        documentsSubmitted
            ? 'auth.documents_in_review_description'
            : 'auth.account_not_active_description';

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 500),
                        child: const OnboardingScreen(),
                      ),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: ref.t('profile.logout'),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: _warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _warning.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: _warning,
                  size: 56,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                ref.t(titleKey),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ref.t(descriptionKey),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 28),
              _StatusPanel(documentsSubmitted: documentsSubmitted),
              const SizedBox(height: 18),
              _SupportPanel(
                onContactSupport: () => _contactSupport(context, ref),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _contactSupport(context, ref),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: Text(ref.t('auth.contact_support')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 500),
                        child: const OnboardingScreen(),
                      ),
                      (_) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(ref.t('profile.logout')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends ConsumerWidget {
  const _StatusPanel({required this.documentsSubmitted});

  final bool documentsSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _StatusRow(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.primary,
            title: ref.t(
              documentsSubmitted
                  ? 'auth.document_review_step_uploaded'
                  : 'auth.account_review_step_profile',
            ),
            subtitle: ref.t(
              documentsSubmitted
                  ? 'auth.document_review_step_uploaded_desc'
                  : 'auth.account_review_step_profile_desc',
            ),
          ),
          const Divider(height: 26),
          _StatusRow(
            icon: Icons.schedule_rounded,
            iconColor: AccountPendingScreen._warning,
            title: ref.t(
              documentsSubmitted
                  ? 'auth.document_review_step_checking'
                  : 'auth.account_review_step_verification',
            ),
            subtitle: ref.t(
              documentsSubmitted
                  ? 'auth.document_review_step_checking_desc'
                  : 'auth.account_review_step_verification_desc',
            ),
          ),
          const Divider(height: 26),
          _StatusRow(
            icon: Icons.dashboard_customize_outlined,
            iconColor: Colors.grey,
            title: ref.t('auth.account_review_step_dashboard'),
            subtitle: ref.t('auth.account_review_step_dashboard_desc'),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportPanel extends ConsumerWidget {
  const _SupportPanel({required this.onContactSupport});

  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.headset_mic_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref.t('auth.account_support_title'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ref.t('auth.account_support_description'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onContactSupport,
            icon: const Icon(Icons.arrow_forward_rounded),
            color: AppColors.primary,
            tooltip: ref.t('auth.contact_support'),
          ),
        ],
      ),
    );
  }
}
