import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/screens/dashboard/withdraw_earnings_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen> {
  int _selectedFilter = 0; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];

  String get _dateDisplay {
    switch (_selectedFilter) {
      case 0:
        return 'Date: 01 Jan 2025';
      case 1:
        return 'Week: 01 Jan 2025 To 07 Jan 2025';
      case 2:
        return 'Month: Sep 2025';
      default:
        return 'Date: 01 Jan 2025';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Earnings Dashboard', showbackButton: true),
      backgroundColor: const Color(0xFFF5F7F8),
      body: Column(
        children: [
          // Header

          // Time Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Color(0xFFF5F7F8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: List.generate(_filters.length, (index) {
                      final isSelected = _selectedFilter == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: EdgeInsets.only(
                              right: index < _filters.length - 1 ? 4 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? AppColors.primary.withOpacity(0.4)
                                        : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _filters[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected
                                        ? AppColors.primary
                                        : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dateDisplay,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTotalEarningsCard(),
                      const SizedBox(height: 16),
                      // Payout Status Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildPayoutStatusCard(
                              icon: Icons.check_circle,
                              iconColor: Colors.blue,
                              title: 'Completed Payouts',
                              amount: '₹4,000',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPayoutStatusCard(
                              icon: Icons.access_time,
                              iconColor: Colors.orange,
                              title: 'Pending Payouts',
                              amount: '₹2,000',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Earnings Card

                  // View All Payouts
                  const Text(
                    'View All Payouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payout List
                  _buildPayoutList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: const WithdrawEarningsScreen(),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Background Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/Metric item.png',
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
            // Content Overlay
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      '₹6,000',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutList() {
    final payouts = [
      {
        'amount': '₹199',
        'status': 'Job Completed',
        'description': 'Smart Switch Installation',
        'time': '4:15 PM',
        'jobId': '#256425',
        'isCompleted': true,
        'date': 'Today',
      },
      {
        'amount': '₹199',
        'status': 'Job Completed',
        'description': 'Smart Switch Installation',
        'time': '4:15 PM',
        'jobId': '#256425',
        'isCompleted': true,
        'date': 'Today',
      },
      {
        'amount': '₹199',
        'status': 'Job Pending',
        'description': 'Smart Switch Installation',
        'time': '4:15 PM',
        'jobId': '#256425',
        'isCompleted': false,
        'date': '25 Nov 2025',
      },
      {
        'amount': '₹199',
        'status': 'Job Pending',
        'description': 'Smart Switch Installation',
        'time': '4:15 PM',
        'jobId': '#256425',
        'isCompleted': false,
        'date': '25 Nov 2025',
      },
    ];

    String? currentDate;
    return Column(
      children:
          payouts.map((payout) {
            final showDateHeader = currentDate != payout['date'];
            if (showDateHeader) {
              currentDate = payout['date'] as String;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDateHeader) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: Text(
                      payout['date'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
                _buildPayoutItem(payout),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildPayoutItem(Map<String, dynamic> payout) {
    final isCompleted = payout['isCompleted'] as bool;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payout['amount'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payout['status'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  payout['description'] as String,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payout['time'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    payout['jobId'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
