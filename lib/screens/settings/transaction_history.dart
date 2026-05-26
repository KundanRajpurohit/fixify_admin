import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/models/earnings_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  TransactionHistoryResponse? _transactionData;

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getTransactionHistory();

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (data) {
          setState(() {
            _transactionData = data;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  // Group transactions by date
  Map<String, List<dynamic>> _groupTransactionsByDate() {
    final grouped = <String, List<dynamic>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Add withdrawal transactions
    for (final withdrawal in _transactionData?.withdrawalData ?? []) {
      String dateKey = _parseWithdrawalDate(withdrawal.requestedAt, today);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(withdrawal);
    }

    // Add regular transactions
    for (final item in _transactionData?.data ?? []) {
      String dateKey;

      if (item.date.toLowerCase() == 'today') {
        dateKey = 'Today';
      } else {
        try {
          DateTime? parsedDate;
          try {
            parsedDate = DateFormat('dd MMM yyyy').parse(item.date);
          } catch (e) {
            try {
              parsedDate = DateFormat('yyyy-MM-dd').parse(item.date);
            } catch (e2) {
              parsedDate = null;
            }
          }

          if (parsedDate != null) {
            final itemDate = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );
            final difference = today.difference(itemDate).inDays;

            if (difference == 0) {
              dateKey = 'Today';
            } else if (difference == 1) {
              dateKey = 'Yesterday';
            } else {
              dateKey = DateFormat('dd MMM yyyy').format(parsedDate);
            }
          } else {
            dateKey = item.date;
          }
        } catch (e) {
          dateKey = item.date;
        }
      }

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    // Sort dates - Today first, then by date (newest first)
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          if (a == 'Today') return -1;
          if (b == 'Today') return 1;
          if (a == 'Yesterday') {
            if (b == 'Today') return 1;
            return -1;
          }
          if (b == 'Yesterday') {
            if (a == 'Today') return -1;
            return 1;
          }
          try {
            final dateA = DateFormat('dd MMM yyyy').parse(a);
            final dateB = DateFormat('dd MMM yyyy').parse(b);
            return dateB.compareTo(dateA);
          } catch (e) {
            return a.compareTo(b);
          }
        });

    final sortedMap = <String, List<dynamic>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  String _parseWithdrawalDate(String dateString, DateTime today) {
    try {
      // Try parsing format: "23 Dec 2025, 6:27 PM"
      final parsedDate = DateFormat('dd MMM yyyy, h:mm a').parse(dateString);
      final itemDate = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );
      final difference = today.difference(itemDate).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('dd MMM yyyy').format(parsedDate);
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CustomAppBar(
        title: ref.t('profile.transaction_history'),
        showbackButton: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null &&
                  ((_transactionData?.withdrawalData.isEmpty ?? true) &&
                      (_transactionData?.data.isEmpty ?? true))
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
                      onPressed: _loadTransactionHistory,
                      child: Text(ref.t('common.retry')),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'View all your completed payouts and earnings.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTransactionList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildTransactionList() {
    final groupedTransactions = _groupTransactionsByDate();

    if (groupedTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No transactions found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children:
          groupedTransactions.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateDivider(label: entry.key),
                const SizedBox(height: 16),
                ...entry.value.map((item) {
                  return Column(
                    children: [
                      if (item is WithdrawalTransactionItem)
                        _WithdrawalTransactionCard(item: item)
                      else if (item is TransactionHistoryItem)
                        _TransactionCard(item: item),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],
            );
          }).toList(),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String label;

  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF6F7787),
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 1)),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TransactionHistoryItem item;

  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final borderColor =
        item.type == TransactionType.credit
            ? const Color(0xFF1EC37F)
            : const Color(0xFFFF5B5B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Amount + time
          Row(
            children: [
              Text(
                item.amount.startsWith('₹') ? item.amount : '₹${item.amount}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                item.time,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6F7787),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          /// Title + txnId + copy icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.txnId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6F7787),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Color(0xFF6F7787),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          /// Sub title
          Text(
            item.subTitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6F7787)),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalTransactionCard extends StatelessWidget {
  final WithdrawalTransactionItem item;

  const _WithdrawalTransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFFFF5B5B); // Debit color for withdrawals

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderColor, width: 3)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Amount + time
          Row(
            children: [
              Text(
                item.amount,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _extractTime(item.requestedAt),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6F7787),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          /// Title + transaction ID + copy icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdrawal Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.bank} - ${item.accountHolderName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6F7787),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Account: ****${item.accountNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6F7787),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${item.transactionId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6F7787),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Color(0xFF6F7787),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          /// Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(item.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(item.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractTime(String dateTimeString) {
    try {
      // Format: "23 Dec 2025, 6:27 PM"
      final parts = dateTimeString.split(', ');
      if (parts.length > 1) {
        return parts[1]; // Returns "6:27 PM"
      }
      return dateTimeString;
    } catch (e) {
      return dateTimeString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
