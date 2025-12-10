import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = <_TransactionGroup>[
      _TransactionGroup(
        label: 'Today',
        items: [
          _TransactionItem(
            amount: '₹199',
            time: '4:15 PM',
            title: 'Payout Received',
            subTitle: 'Smart Switch Installation',
            txnId: '#256425',
            type: TransactionType.credit,
          ),
          _TransactionItem(
            amount: '₹199',
            time: '4:15 PM',
            title: 'Payout Received',
            subTitle: 'Smart Switch Installation',
            txnId: '#256425',
            type: TransactionType.credit,
          ),
        ],
      ),
      _TransactionGroup(
        label: '25 Nov 2025',
        items: [
          _TransactionItem(
            amount: '₹150',
            time: '4:15 PM',
            title: 'Platform Fee Deduction',
            subTitle: 'Sep 2025 Service Charge',
            txnId: '#256425',
            type: TransactionType.debit,
          ),
          _TransactionItem(
            amount: '₹150',
            time: '4:15 PM',
            title: 'Platform Fee Deduction',
            subTitle: 'Sep 2025 Service Charge',
            txnId: '#256425',
            type: TransactionType.debit,
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: CustomAppBar(title: 'Transaction History', showbackButton: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 18),
            const Text(
              'View all your completed payouts and earnings.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            for (final group in transactions) ...[
              _DateDivider(label: group.label),
              const SizedBox(height: 16),
              for (final item in group.items) ...[
                _TransactionCard(item: item),
                const SizedBox(height: 16),
              ],
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

enum TransactionType { credit, debit }

class _TransactionItem {
  final String amount;
  final String time;
  final String title;
  final String subTitle;
  final String txnId;
  final TransactionType type;

  _TransactionItem({
    required this.amount,
    required this.time,
    required this.title,
    required this.subTitle,
    required this.txnId,
    required this.type,
  });
}

class _TransactionGroup {
  final String label;
  final List<_TransactionItem> items;

  _TransactionGroup({required this.label, required this.items});
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
  final _TransactionItem item;

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
                item.amount,
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
