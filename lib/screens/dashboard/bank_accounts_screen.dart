import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/models/bank_model.dart';
import 'package:fixify_admin/screens/dashboard/add_edit_bank_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  // Sample bank accounts data - replace with API data
  final List<BankAccount> _bankAccounts = [
    BankAccount(
      id: '1',
      accountHolderName: 'Dhaval Paghadal',
      bankName: 'HDFC Bank',
      accountNumber: '12345678904421',
      ifscCode: 'HDFC00017782',
    ),
    BankAccount(
      id: '2',
      accountHolderName: 'Dhaval Paghadal',
      bankName: 'HDFC Bank',
      accountNumber: '12345678904421',
      ifscCode: 'HDFC00017782',
    ),
    BankAccount(
      id: '3',
      accountHolderName: 'Dhaval Paghadal',
      bankName: 'HDFC Bank',
      accountNumber: '12345678904421',
      ifscCode: 'HDFC00017782',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: Column(
        children: [
          // Header
          CustomAppBar(title: 'My Bank Accounts', showbackButton: true),
          // Bank Accounts List
          Expanded(
            child:
                _bankAccounts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bank accounts added',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bankAccounts.length,
                      itemBuilder: (context, index) {
                        return _buildBankAccountCard(_bankAccounts[index]);
                      },
                    ),
          ),

          // Add New Bank Account Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      type: PageTransitionType.rightToLeft,
                      duration: const Duration(milliseconds: 300),
                      child: const AddEditBankAccountScreen(),
                    ),
                  ).then((result) {
                    if (result != null && result is BankAccount) {
                      setState(() {
                        _bankAccounts.add(result);
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add New Bank Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountCard(BankAccount account) {
    final bank = BankValidationRules.getBankByName(account.bankName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Bank Logo
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(25),
            ),
            child:
                bank != null && bank.logoImageUrl.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        bank.logoImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.account_balance, size: 30);
                        },
                      ),
                    )
                    : const Icon(Icons.account_balance, size: 30),
          ),
          const SizedBox(width: 12),
          // Bank Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.bankName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.accountHolderName,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ac No. : ${account.maskedAccountNumber}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  'IFSC: ${account.ifscCode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          // Edit Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: AppColors.primary, size: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                  child: AddEditBankAccountScreen(bankAccount: account),
                ),
              ).then((result) {
                if (result != null && result is BankAccount) {
                  setState(() {
                    final index = _bankAccounts.indexWhere(
                      (acc) => acc.id == account.id,
                    );
                    if (index != -1) {
                      _bankAccounts[index] = result;
                    }
                  });
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
