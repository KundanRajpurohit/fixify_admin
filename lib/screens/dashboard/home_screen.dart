import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';
import 'dashboard_screen.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final ValueNotifier<int> tabNotifier;
  const HomeDashboardScreen({super.key, required this.tabNotifier});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen>
    with WidgetsBindingObserver {
  static const Color _green = Color(0xFF2F6F3E);
  static const Color _lightGreen = Color(0xFFE6F6E7);
  bool _isOnline = false;
  bool _isLoading = true;
  bool _isLoadingCustomDate = false;

  // Dashboard stats
  Map<String, dynamic>? _dashboardData;

  // Custom date range data
  DateTime? _startDate;
  DateTime? _endDate;
  Map<String, dynamic>? _customDateData;
  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
    await _loadOnlineStatus();
    await _loadCustomDateData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensures refresh AFTER build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshDashboard();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadOnlineStatus();
    // Set default date range (last 10 days)
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 10));
    _loadCustomDateData();
    widget.tabNotifier.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Dashboard tab index = 0
    if (widget.tabNotifier.value == 0) {
      _refreshDashboard();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final service = ref.read(userServiceProvider);
    final result = await service.getDashboardStats();

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _loadOnlineStatus() async {
    final service = ref.read(userServiceProvider);
    final result = await service.getGoOnlineStatus();

    result.fold(
      (failure) {
        if (!mounted) return;
        // Don't show error, just use default value
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _isOnline = data['go_online'] == 1 || data['online'] == true;
        });
      },
    );
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() => _isOnline = value);

    final service = ref.read(userServiceProvider);
    final result = await service.goOnline(value);

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() => _isOnline = !value); // Revert on error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (data) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'You are now online' : 'You are now offline'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  Future<void> _loadCustomDateData() async {
    if (_startDate == null || _endDate == null) return;

    setState(() => _isLoadingCustomDate = true);

    final service = ref.read(userServiceProvider);
    final startDateStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_endDate!);

    final result = await service.getDataByCustomDate(
      startDate: startDateStr,
      endDate: endDateStr,
    );

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() => _isLoadingCustomDate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _customDateData = data;
          _isLoadingCustomDate = false;
        });
      },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          _startDate != null && _endDate != null
              ? DateTimeRange(start: _startDate!, end: _endDate!)
              : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadCustomDateData();
    }
  }

  String _formatTrendText(Map<String, dynamic>? data) {
    if (data == null) return 'No change';

    final percentage = data['percentage_change'] ?? 0;
    final trend = data['trend'] ?? 'no_change';

    if (trend == 'no_change' || percentage == 0) {
      return 'No change';
    }

    final symbol = trend == 'up' ? '↑' : '↓';
    final color = trend == 'up' ? Colors.green : Colors.red;

    return '$symbol ${percentage.abs()}% vs Yesterday';
  }

  Color _getTrendColor(Map<String, dynamic>? data) {
    if (data == null) return Colors.grey;
    final trend = data['trend'] ?? 'no_change';
    return trend == 'up'
        ? Colors.green
        : trend == 'down'
        ? Colors.red
        : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: CustomAppBar(title: 'Dashboard', showbackButton: false),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: () async {
                        await _loadDashboardData();
                        await _loadOnlineStatus();
                        await _loadCustomDateData();
                      },
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    title: "Today's Booking",
                                    value:
                                        _dashboardData?['booking']?['today']
                                            ?.toString() ??
                                        '0',
                                    trendText: _formatTrendText(
                                      _dashboardData?['booking'],
                                    ),
                                    trendColor: _getTrendColor(
                                      _dashboardData?['booking'],
                                    ),
                                    chartColor: _getTrendColor(
                                      _dashboardData?['booking'],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _statCard(
                                    title: "Today's Earnings",
                                    value:
                                        '₹${_dashboardData?['earning']?['today']?.toString() ?? '0.00'}',
                                    trendText: _formatTrendText(
                                      _dashboardData?['earning'],
                                    ),
                                    trendColor: _getTrendColor(
                                      _dashboardData?['earning'],
                                    ),
                                    chartColor: _getTrendColor(
                                      _dashboardData?['earning'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _performanceCard(),
                            const SizedBox(height: 12),
                            _quickActionCard(),
                            const SizedBox(height: 12),
                            _earningsSummaryCard(),
                          ],
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String trendText,
    required Color trendColor,
    required Color chartColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trendText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: trendColor,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(painter: _SimpleCurvePainter(chartColor)),
          ),
        ],
      ),
    );
  }

  Widget _performanceCard() {
    final performance = _dashboardData?['performance'];
    final score = performance?['today_score']?.toString() ?? '0';
    final trendText = _formatTrendText(performance);
    final trendColor = _getTrendColor(performance);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Score',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trendText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: trendColor,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: CustomPaint(painter: _SimpleCurvePainter(trendColor)),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Action',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: _lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.power_settings_new,
                  size: 18,
                  color: _green,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Go Online',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch(
                activeColor: _green,
                value: _isOnline,
                onChanged: _toggleOnlineStatus,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.work_outline,
                size: 18,
                color: Color(0xFF4A6CF7),
              ),
            ),
            title: const Text(
              'View Jobs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Navigate to My Jobs screen (index 1)
              Navigator.pushReplacement(
                context,
                PageTransition(
                  type: PageTransitionType.fade,
                  duration: const Duration(milliseconds: 300),
                  child: const HomePageScreen(initialIndex: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _earningsSummaryCard() {
    final totalEarning = _customDateData?['total_earning']?.toString() ?? '0';
    final completedJobs = _customDateData?['completed_jobs']?.toString() ?? '0';
    final completedEarning =
        _customDateData?['completed_earning']?.toString() ?? '0';

    final dateRangeText =
        _startDate != null && _endDate != null
            ? '${DateFormat('dd MMM yyyy').format(_startDate!)} To ${DateFormat('dd MMM yyyy').format(_endDate!)}'
            : 'Select Date Range';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date row
          Row(
            children: [
              const Text(
                'Date:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateRangeText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                onPressed: _selectDateRange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // green earnings card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF1F6D38), Color(0xFF0B4720)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$totalEarning',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Completed\nJobs',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        completedJobs,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF6E5), Color(0xFFFFFDF7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completed\nEarnings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹$completedEarning',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Very simple curved line to mimic the mini charts.
class _SimpleCurvePainter extends CustomPainter {
  final Color color;
  _SimpleCurvePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.2,
      size.width * 0.4,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.9,
      size.width * 0.9,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SimpleCurvePainter oldDelegate) =>
      oldDelegate.color != oldDelegate.color;
}
