// Earnings and Transaction Models
import 'bank_model.dart';

class BookingTransactionDailyResponse {
  final bool status;
  final String message;
  final String date;
  final int totalEarning;
  final int completePayout;
  final int pendingPayout;
  final List<BookingTransactionItem> data;

  BookingTransactionDailyResponse({
    required this.status,
    required this.message,
    required this.date,
    required this.totalEarning,
    required this.completePayout,
    required this.pendingPayout,
    required this.data,
  });

  factory BookingTransactionDailyResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
            ?.map((item) => BookingTransactionItem.fromJson(item))
            .toList() ??
        [];

    return BookingTransactionDailyResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      date: json['date'] ?? '',
      totalEarning: (json['total_earning'] ?? 0).toInt(),
      completePayout: (json['complete_payout'] ?? 0).toInt(),
      pendingPayout: (json['pending_payout'] ?? 0).toInt(),
      data: dataList,
    );
  }
}

class BookingTransactionWeeklyResponse {
  final bool status;
  final String message;
  final String fromDate;
  final String toDate;
  final int totalEarning;
  final int completePayout;
  final int pendingPayout;
  final List<BookingTransactionItem> data;

  BookingTransactionWeeklyResponse({
    required this.status,
    required this.message,
    required this.fromDate,
    required this.toDate,
    required this.totalEarning,
    required this.completePayout,
    required this.pendingPayout,
    required this.data,
  });

  factory BookingTransactionWeeklyResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
            ?.map((item) => BookingTransactionItem.fromJson(item))
            .toList() ??
        [];

    return BookingTransactionWeeklyResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      totalEarning: (json['total_earning'] ?? 0).toInt(),
      completePayout: (json['complete_payout'] ?? 0).toInt(),
      pendingPayout: (json['pending_payout'] ?? 0).toInt(),
      data: dataList,
    );
  }
}

class BookingTransactionMonthlyResponse {
  final bool status;
  final String message;
  final String month;
  final int totalEarning;
  final int completePayout;
  final int pendingPayout;
  final List<BookingTransactionItem> data;

  BookingTransactionMonthlyResponse({
    required this.status,
    required this.message,
    required this.month,
    required this.totalEarning,
    required this.completePayout,
    required this.pendingPayout,
    required this.data,
  });

  factory BookingTransactionMonthlyResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?)
            ?.map((item) => BookingTransactionItem.fromJson(item))
            .toList() ??
        [];

    return BookingTransactionMonthlyResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      month: json['month'] ?? '',
      totalEarning: (json['total_earning'] ?? 0).toInt(),
      completePayout: (json['complete_payout'] ?? 0).toInt(),
      pendingPayout: (json['pending_payout'] ?? 0).toInt(),
      data: dataList,
    );
  }
}

class BookingTransactionItem {
  final String username;
  final String address;
  final String price;
  final String workStatus;
  final String? dateTime;
  final String bookingId;
  final String token;

  BookingTransactionItem({
    required this.username,
    required this.address,
    required this.price,
    required this.workStatus,
    this.dateTime,
    required this.bookingId,
    required this.token,
  });

  factory BookingTransactionItem.fromJson(Map<String, dynamic> json) {
    return BookingTransactionItem(
      username: json['username'] ?? '',
      address: json['address'] ?? '',
      price: json['price'] ?? '',
      workStatus: json['work_status'] ?? '',
      dateTime: json['date_time'],
      bookingId: json['booking_id'] ?? '',
      token: json['token'] ?? '',
    );
  }

  bool get isCompleted {
    final status = workStatus.toLowerCase();
    return status == 'completed' || status == 'past';
  }
}

class TransactionHistoryResponse {
  final bool status;
  final String message;
  final List<TransactionHistoryItem> data;
  final List<WithdrawalTransactionItem> withdrawalData;

  TransactionHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.withdrawalData,
  });

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List<dynamic>?) ?? [];
    
    // Check if items are withdrawal transactions (have transaction_id and requested_withdraw_amount)
    final List<WithdrawalTransactionItem> withdrawals = [];
    final List<TransactionHistoryItem> regularTransactions = [];

    for (final item in dataList) {
      if (item is Map<String, dynamic>) {
        // Check if it's a withdrawal transaction (has transaction_id and requested_withdraw_amount)
        if (item.containsKey('transaction_id') && item.containsKey('requested_withdraw_amount')) {
          withdrawals.add(WithdrawalTransactionItem.fromJson(item));
        } else {
          // Try to parse as regular transaction
          try {
            regularTransactions.add(TransactionHistoryItem.fromJson(item));
          } catch (e) {
            // Skip if parsing fails
          }
        }
      }
    }

    return TransactionHistoryResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: regularTransactions,
      withdrawalData: withdrawals,
    );
  }
}

class TransactionHistoryItem {
  final String amount;
  final String time;
  final String title;
  final String subTitle;
  final String txnId;
  final String date;
  final TransactionType type;

  TransactionHistoryItem({
    required this.amount,
    required this.time,
    required this.title,
    required this.subTitle,
    required this.txnId,
    required this.date,
    required this.type,
  });

  factory TransactionHistoryItem.fromJson(Map<String, dynamic> json) {
    // Determine transaction type based on title or amount prefix
    final title = json['title'] ?? json['transaction_title'] ?? '';
    final amount = json['amount'] ?? json['transaction_amount'] ?? '';
    final amountStr = amount.toString();
    final isCredit = title.toLowerCase().contains('payout received') ||
        title.toLowerCase().contains('credit') ||
        title.toLowerCase().contains('received') ||
        (!amountStr.startsWith('-') && amountStr.isNotEmpty);

    return TransactionHistoryItem(
      amount: amountStr,
      time: json['time'] ?? json['transaction_time'] ?? json['created_at'] ?? '',
      title: title,
      subTitle: json['sub_title'] ?? json['subTitle'] ?? json['description'] ?? json['subtitle'] ?? '',
      txnId: json['txn_id'] ?? json['txnId'] ?? json['transaction_id'] ?? json['id'] ?? '',
      date: json['date'] ?? json['transaction_date'] ?? json['created_at'] ?? '',
      type: isCredit ? TransactionType.credit : TransactionType.debit,
    );
  }
}

enum TransactionType {
  credit,
  debit,
}

// Withdrawal Models
class CheckoutIndexResponse {
  final bool status;
  final String message;
  final String ruleLimits;
  final List<BankAccount> bankAccounts;
  final int platformFee;

  CheckoutIndexResponse({
    required this.status,
    required this.message,
    required this.ruleLimits,
    required this.bankAccounts,
    required this.platformFee,
  });

  factory CheckoutIndexResponse.fromJson(Map<String, dynamic> json) {
    final bankAccountsList = (json['data'] as List<dynamic>?)
            ?.map((item) => BankAccount.fromJson(item))
            .toList() ??
        [];

    return CheckoutIndexResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      ruleLimits: json['rule_limits'] ?? '',
      bankAccounts: bankAccountsList,
      platformFee: (json['platform_fee'] ?? 0).toInt(),
    );
  }
}

// Updated Transaction History Item for withdrawal transactions
class WithdrawalTransactionItem {
  final int transactionId;
  final String bank;
  final String accountHolderName;
  final String accountNumber; // Last 4 digits
  final String ifscCode;
  final int requestedWithdrawAmount;
  final int approveWithdrawAmount;
  final String status;
  final String requestedAt;
  final String processedAt;
  final bool platformFee;

  WithdrawalTransactionItem({
    required this.transactionId,
    required this.bank,
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.requestedWithdrawAmount,
    required this.approveWithdrawAmount,
    required this.status,
    required this.requestedAt,
    required this.processedAt,
    required this.platformFee,
  });

  factory WithdrawalTransactionItem.fromJson(Map<String, dynamic> json) {
    // Handle transaction_id (can be int or String)
    int transactionId = 0;
    if (json['transaction_id'] != null) {
      if (json['transaction_id'] is int) {
        transactionId = json['transaction_id'] as int;
      } else if (json['transaction_id'] is String) {
        transactionId = int.tryParse(json['transaction_id'] as String) ?? 0;
      }
    }

    // Handle requested_withdraw_amount (can be int or String)
    int requestedAmount = 0;
    if (json['requested_withdraw_amount'] != null) {
      if (json['requested_withdraw_amount'] is int) {
        requestedAmount = json['requested_withdraw_amount'] as int;
      } else if (json['requested_withdraw_amount'] is String) {
        requestedAmount = int.tryParse(json['requested_withdraw_amount'] as String) ?? 0;
      } else if (json['requested_withdraw_amount'] is num) {
        requestedAmount = (json['requested_withdraw_amount'] as num).toInt();
      }
    }

    // Handle approve_withdraw_amount (can be int or String)
    int approveAmount = 0;
    if (json['approve_withdraw_amount'] != null) {
      if (json['approve_withdraw_amount'] is int) {
        approveAmount = json['approve_withdraw_amount'] as int;
      } else if (json['approve_withdraw_amount'] is String) {
        approveAmount = int.tryParse(json['approve_withdraw_amount'] as String) ?? 0;
      } else if (json['approve_withdraw_amount'] is num) {
        approveAmount = (json['approve_withdraw_amount'] as num).toInt();
      }
    }

    // Handle account_number (can be int or String)
    String accountNumber = '';
    if (json['account_number'] != null) {
      if (json['account_number'] is String) {
        accountNumber = json['account_number'] as String;
      } else {
        accountNumber = json['account_number'].toString();
      }
    }

    // Handle platform_fee (can be bool or int 0/1)
    bool platformFee = false;
    if (json['platform_fee'] != null) {
      if (json['platform_fee'] is bool) {
        platformFee = json['platform_fee'] as bool;
      } else if (json['platform_fee'] is int) {
        platformFee = (json['platform_fee'] as int) != 0;
      } else if (json['platform_fee'] is String) {
        platformFee = json['platform_fee'] == 'true' || json['platform_fee'] == '1';
      }
    }

    return WithdrawalTransactionItem(
      transactionId: transactionId,
      bank: json['bank']?.toString() ?? '',
      accountHolderName: json['account_holder_name']?.toString() ?? '',
      accountNumber: accountNumber,
      ifscCode: json['ifsc_code']?.toString() ?? '',
      requestedWithdrawAmount: requestedAmount,
      approveWithdrawAmount: approveAmount,
      status: json['status']?.toString() ?? '',
      requestedAt: json['requested_at']?.toString() ?? '',
      processedAt: json['processed_at']?.toString() ?? '',
      platformFee: platformFee,
    );
  }

  TransactionType get type => TransactionType.debit; // Withdrawals are always debit
  String get amount => '₹$requestedWithdrawAmount';
}

