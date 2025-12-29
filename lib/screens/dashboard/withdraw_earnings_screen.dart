import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/models/bank_model.dart';
import 'package:fixify_admin/models/earnings_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WithdrawEarningsScreen extends ConsumerStatefulWidget {
  const WithdrawEarningsScreen({super.key});

  @override
  ConsumerState<WithdrawEarningsScreen> createState() => _WithdrawEarningsScreenState();
}

class _WithdrawEarningsScreenState extends ConsumerState<WithdrawEarningsScreen> {
  final _amountController = TextEditingController();
  String? _selectedBankAccountId;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;

  CheckoutIndexResponse? _checkoutData;
  int? _minimumWithdrawal;
  int? _maximumWithdrawal;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckoutData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.getCheckoutIndex();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _errorMessage = failure.message;
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
              _checkoutData = data;
              _isLoading = false;
              if (data.bankAccounts.isNotEmpty) {
                _selectedBankAccountId = data.bankAccounts[0].id?.toString();
              }
              // Parse rules from HTML (basic extraction)
              _parseRulesFromHtml(data.ruleLimits);
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _parseRulesFromHtml(String html) {
    // Basic parsing - extract min/max amounts from HTML
    final minMatch = RegExp(r'Minimum withdrawal: ₹(\d+)').firstMatch(html);
    final maxMatch = RegExp(r'Maximum per withdrawal: ₹(\d+)').firstMatch(html);
    
    if (minMatch != null) {
      _minimumWithdrawal = int.tryParse(minMatch.group(1) ?? '');
    }
    if (maxMatch != null) {
      _maximumWithdrawal = int.tryParse(maxMatch.group(1) ?? '');
    }

    // Defaults if not found
    _minimumWithdrawal ??= 500;
    _maximumWithdrawal ??= 10000;
  }

  double get _withdrawalAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
  }

  double get _platformFee => (_checkoutData?.platformFee ?? 0).toDouble();
  double get _willReceive => _withdrawalAmount - _platformFee;

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Withdrawal Request Submitted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your withdrawal request of ₹${_amountController.text} has been received and is under review. You\'ll receive the amount in 1-2 business days.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to earnings dashboard
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Transaction',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleWithdraw() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter withdrawal amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = _withdrawalAmount;
    if (amount < (_minimumWithdrawal ?? 500)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal amount is ₹${_minimumWithdrawal ?? 500}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > (_maximumWithdrawal ?? 10000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum withdrawal amount is ₹${_maximumWithdrawal ?? 10000}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedBankAccountId == null || _checkoutData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find the selected bank account
    final selectedAccount = _checkoutData!.bankAccounts.firstWhere(
      (account) => account.id?.toString() == _selectedBankAccountId,
      orElse: () => _checkoutData!.bankAccounts[0],
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.submitWithdrawalRequest(
        accountNumber: selectedAccount.accountNumber,
        withdrawAmountRequest: amount.toInt().toString(),
      );

    if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
        },
        (data) {
    setState(() {
      _isSubmitting = false;
    });
          _amountController.clear();
    _showSuccessDialog();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Withdraw Earnings', showbackButton: true),
      backgroundColor: const Color(0xFFF5F7F8),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _errorMessage != null && _checkoutData == null
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
                        onPressed: _loadCheckoutData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Withdrawal Rules
                  _buildRulesCard(),
                  const SizedBox(height: 16),
                  // Select Bank Account
                  _buildBankAccountSelection(),
                  const SizedBox(height: 16),
                  // Enter Amount
                  _buildAmountInput(),
                  const SizedBox(height: 16),
                  // Summary
                  _buildSummaryCard(),
                ],
              ),
            ),
          ),

          // Request Withdrawal Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                          child: _isSubmitting
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Request Withdrawal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard() {
    if (_checkoutData == null) return const SizedBox.shrink();

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
          const Text(
            'Withdrawal Rules / Limits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Parse HTML and display rules
          if (_checkoutData!.ruleLimits.isNotEmpty)
            ..._parseRulesToList(_checkoutData!.ruleLimits)
          else
            ...[
              _buildRuleItem('Minimum withdrawal: ₹${_minimumWithdrawal ?? 500}'),
              _buildRuleItem('Maximum per withdrawal: ₹${_maximumWithdrawal ?? 10000}'),
          _buildRuleItem('Daily limit: 2 withdrawals per day'),
          _buildRuleItem('Processing Time: 1-2 business days'),
            ],
        ],
      ),
    );
  }

  List<Widget> _parseRulesToList(String html) {
    // Simple HTML parsing to extract list items
    final List<Widget> rules = [];
    final regex = RegExp(r'<li>(.*?)</li>');
    final matches = regex.allMatches(html);
    
    for (final match in matches) {
      final text = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
      if (text.isNotEmpty) {
        rules.add(_buildRuleItem(text));
      }
    }

    return rules.isEmpty
        ? [
            _buildRuleItem('Minimum withdrawal: ₹${_minimumWithdrawal ?? 500}'),
            _buildRuleItem('Maximum per withdrawal: ₹${_maximumWithdrawal ?? 10000}'),
            _buildRuleItem('Daily limit: 2 withdrawals per day'),
            _buildRuleItem('Processing Time: 1-2 business days'),
          ]
        : rules;
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSelection() {
    if (_checkoutData == null || _checkoutData!.bankAccounts.isEmpty) {
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
        child: const Text(
          'No bank accounts found. Please add a bank account first.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

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
          const Text(
            'Select Withdrawal Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._checkoutData!.bankAccounts.map((account) {
            final isSelected = _selectedBankAccountId == account.id?.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBankAccountId = account.id?.toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                            ? AppColors.secondary.withOpacity(0.1)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: account.id?.toString() ?? '',
                        groupValue: _selectedBankAccountId,
                        onChanged: (value) {
                          setState(() {
                            _selectedBankAccountId = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.bankName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              account.accountHolderName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ac No. : ${account.maskedAccountNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
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
          const Text(
            'Enter Withdrawal Amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter amount (₹${_minimumWithdrawal ?? 500} - ₹${_maximumWithdrawal ?? 10000})',
              prefixText: '₹ ',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
          const Text(
            'Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Withdrawal Amount',
            '₹${_withdrawalAmount.toStringAsFixed(0)}',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Platform Fee',
            '₹${_platformFee.toStringAsFixed(0)}',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Will Receive',
            '₹${_willReceive.toStringAsFixed(0)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
