import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/models/earnings_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/dashboard/withdraw_earnings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

class EarningsDashboardScreen extends ConsumerStatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  ConsumerState<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState
    extends ConsumerState<EarningsDashboardScreen> {
  int _selectedFilter = 0; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];

  bool _isLoading = false;
  String? _errorMessage;

  // Selected dates
  DateTime? _selectedDate; // For daily filter
  DateTime? _selectedWeekDate; // For weekly filter (any date in the week)
  DateTime? _selectedMonth; // For monthly filter

  // Data holders
  BookingTransactionDailyResponse? _dailyData;
  BookingTransactionWeeklyResponse? _weeklyData;
  BookingTransactionMonthlyResponse? _monthlyData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final now = DateTime.now();

      switch (_selectedFilter) {
        case 0: // Daily
          final selectedDate = _selectedDate ?? now;
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
          final result = await userService.getBookingTransactionDaily(
            date: dateStr,
          );
          result.fold(
            (failure) {
              setState(() {
                _errorMessage = failure.message;
                _isLoading = false;
              });
            },
            (data) {
              setState(() {
                _dailyData = data;
                _isLoading = false;
              });
            },
          );
          break;

        case 1: // Weekly
          // For weekly, we can pass a date parameter (any date in the week)
          // If not selected, use current date
          final weekDate = _selectedWeekDate ?? now;
          final dateStr = DateFormat('yyyy-MM-dd').format(weekDate);
          final result = await userService.getBookingTransactionWeekly(
            date: dateStr,
          );
          result.fold(
            (failure) {
              setState(() {
                _errorMessage = failure.message;
                _isLoading = false;
              });
            },
            (data) {
              setState(() {
                _weeklyData = data;
                _isLoading = false;
              });
            },
          );
          break;

        case 2: // Monthly
          final selectedMonth = _selectedMonth ?? now;
          final monthName = DateFormat('MMMM').format(selectedMonth);
          final year = DateFormat('yyyy').format(selectedMonth);
          final result = await userService.getBookingTransactionMonthly(
            month: monthName,
            year: year,
          );
          result.fold(
            (failure) {
              setState(() {
                _errorMessage = failure.message;
                _isLoading = false;
              });
            },
            (data) {
              setState(() {
                _monthlyData = data;
                _isLoading = false;
              });
            },
          );
          break;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(int index) {
    if (_selectedFilter != index) {
      setState(() {
        _selectedFilter = index;
      });
      _loadData();
    }
  }

  String get _dateDisplay {
    if (_isLoading) {
      return 'Loading...';
    }

    switch (_selectedFilter) {
      case 0:
        final date = _selectedDate ?? DateTime.now();
        if (_dailyData != null && _dailyData!.date.isNotEmpty) {
          try {
            final parsedDate = DateTime.parse(_dailyData!.date);
            return 'Date: ${DateFormat('dd MMM yyyy').format(parsedDate)}';
          } catch (e) {
            return 'Date: ${_dailyData!.date}';
          }
        }
        return 'Date: ${DateFormat('dd MMM yyyy').format(date)}';

      case 1:
        if (_weeklyData != null) {
          return 'Week: ${_weeklyData!.fromDate} To ${_weeklyData!.toDate}';
        }
        final weekDate = _selectedWeekDate ?? DateTime.now();
        return 'Week: ${DateFormat('dd MMM yyyy').format(weekDate)}';

      case 2:
        if (_monthlyData != null && _monthlyData!.month.isNotEmpty) {
          return 'Month: ${_monthlyData!.month}';
        }
        final month = _selectedMonth ?? DateTime.now();
        return 'Month: ${DateFormat('MMM yyyy').format(month)}';

      default:
        return 'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}';
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _selectWeekDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedWeekDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedWeekDate) {
      setState(() {
        _selectedWeekDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _selectMonth() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
      _loadData();
    }
  }

  int get _totalEarning {
    switch (_selectedFilter) {
      case 0:
        return _dailyData?.totalEarning ?? 0;
      case 1:
        return _weeklyData?.totalEarning ?? 0;
      case 2:
        return _monthlyData?.totalEarning ?? 0;
      default:
        return 0;
    }
  }

  int get _completePayout {
    switch (_selectedFilter) {
      case 0:
        return _dailyData?.completePayout ?? 0;
      case 1:
        return _weeklyData?.completePayout ?? 0;
      case 2:
        return _monthlyData?.completePayout ?? 0;
      default:
        return 0;
    }
  }

  int get _pendingPayout {
    switch (_selectedFilter) {
      case 0:
        return _dailyData?.pendingPayout ?? 0;
      case 1:
        return _weeklyData?.pendingPayout ?? 0;
      case 2:
        return _monthlyData?.pendingPayout ?? 0;
      default:
        return 0;
    }
  }

  List<BookingTransactionItem> get _transactionItems {
    switch (_selectedFilter) {
      case 0:
        return _dailyData?.data ?? [];
      case 1:
        return _weeklyData?.data ?? [];
      case 2:
        return _monthlyData?.data ?? [];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Earnings Dashboard', showbackButton: true),
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: _isLoading && _transactionItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _transactionItems.isEmpty
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
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
          child: Column(
            children: [
              // Time Filters
              Container(
                padding: const EdgeInsets.all(16),
                          color: const Color(0xFFF5F7F8),
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
                                        onTap: () => _onFilterChanged(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: EdgeInsets.only(
                                  right: index < _filters.length - 1 ? 4 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                            color: isSelected
                                          ? AppColors.primary.withOpacity(0.08)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                              color: isSelected
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
                                              color: isSelected
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
                                    GestureDetector(
                                      onTap: () {
                                        switch (_selectedFilter) {
                                          case 0:
                                            _selectDate();
                                            break;
                                          case 1:
                                            _selectWeekDate();
                                            break;
                                          case 2:
                                            _selectMonth();
                                            break;
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
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
                                            Expanded(
                                              child: Text(
                                  _dateDisplay,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              size: 20,
                                              color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                                    ),
                                    const SizedBox(height: 16),
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
                                            amount: '₹${_completePayout.toString()}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildPayoutStatusCard(
                                  icon: Icons.access_time,
                                  iconColor: Colors.orange,
                                  title: 'Pending Payouts',
                                            amount: '₹${_pendingPayout.toString()}',
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ],
          ),
        ),
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 160,
                    color: AppColors.primary,
                  );
                },
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
                      '₹${_totalEarning.toString()}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
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
    final items = _transactionItems;

    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
                    child: Text(
            'No transactions found',
                      style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
                      ),
                    ),
                  ),
      );
    }

    // Group items by date if possible
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPayoutItem(item),
            );
          }).toList(),
    );
  }

  Widget _buildPayoutItem(BookingTransactionItem item) {
    final isCompleted = item.isCompleted;
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
                  '₹${item.price}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.workStatus,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.username,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  item.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.dateTime != null) ...[
              Text(
                  _formatDateTime(item.dateTime!),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Text(
                    item.bookingId,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      // Copy to clipboard
                      // You can implement clipboard functionality here
                    },
                    child: Icon(Icons.copy, size: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return dateTime;
    }
  }
}
