class BankInfo {
  final String bankName;
  final String type;
  final String shortCode;
  final String ifscPrefix;
  final String logoImageUrl;
  final AccountValidation accountValidation;

  BankInfo({
    required this.bankName,
    required this.type,
    required this.shortCode,
    required this.ifscPrefix,
    required this.logoImageUrl,
    required this.accountValidation,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      bankName: json['bank_name'],
      type: json['type'],
      shortCode: json['short_code'],
      ifscPrefix: json['ifsc_prefix'],
      logoImageUrl: json['logo_image_url'],
      accountValidation: AccountValidation.fromJson(
        json['account_number_validation'],
      ),
    );
  }
}

class AccountValidation {
  final int minLength;
  final int maxLength;
  final String formatNotes;

  AccountValidation({
    required this.minLength,
    required this.maxLength,
    required this.formatNotes,
  });

  factory AccountValidation.fromJson(Map<String, dynamic> json) {
    return AccountValidation(
      minLength: json['min_length'],
      maxLength: json['max_length'],
      formatNotes: json['format_notes'],
    );
  }
}

class BankAccount {
  final int? id;
  final String? partnerid;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;

  BankAccount({
    this.id,
    this.partnerid,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      partnerid: json['partnerid']?.toString(),
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id.toString(),
      'account_holder_name': accountHolderName,
      'bank': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
    };
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '**** ${accountNumber.substring(accountNumber.length - 4)}';
  }
}

class BankValidationRules {
  static const String ifscRegex = r'^[A-Z]{4}0[A-Z0-9]{6}$';
  static const int ifscLength = 11;

  static final List<BankInfo> banks = [
    // Public Sector Banks
    BankInfo(
      bankName: 'State Bank of India',
      type: 'PSB',
      shortCode: 'SBI',
      ifscPrefix: 'SBIN',
      logoImageUrl: 'https://sbi.bank.in/o/SBI-Theme/images/custom/logo.png',
      accountValidation: AccountValidation(
        minLength: 11,
        maxLength: 13,
        formatNotes: 'Typically 11-13 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Punjab National Bank',
      type: 'PSB',
      shortCode: 'PNB',
      ifscPrefix: 'PUNB',
      logoImageUrl: 'https://pnb.bank.in/images/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Bank of Baroda',
      type: 'PSB',
      shortCode: 'BOB',
      ifscPrefix: 'BARB',
      logoImageUrl: 'https://bankofbaroda.bank.in/-/media/project/bob/countrywebsites/india/icons/bob-logo.svg',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Canara Bank',
      type: 'PSB',
      shortCode: 'CANARA',
      ifscPrefix: 'CNRB',
      logoImageUrl: 'https://canarabank.bank.in/assets/images/logo.webp',
      accountValidation: AccountValidation(
        minLength: 13,
        maxLength: 13,
        formatNotes: 'Typically 13 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Union Bank of India',
      type: 'PSB',
      shortCode: 'UBI',
      ifscPrefix: 'UBIN',
      logoImageUrl: 'https://www.unionbankofindia.bank.in/img/header/ubi_logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Bank of India',
      type: 'PSB',
      shortCode: 'BOI',
      ifscPrefix: 'BKID',
      logoImageUrl: 'https://bankofindia.bank.in/o/boi-global-theme/images/boi/logos/boi_en_US_logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Indian Bank',
      type: 'PSB',
      shortCode: 'INDB',
      ifscPrefix: 'IDIB',
      logoImageUrl: 'https://imgs.search.brave.com/7IHUYS1Y-KcWG0TjeWf7kfSGYvBs2msHB7RdB5ct5NM/rs:fit:500:0:0:0/g:ce/aHR0cHM6Ly91cGxv/YWQud2lraW1lZGlh/Lm9yZy93aWtpcGVk/aWEvZW4vdGh1bWIv/Yi9iYy9JbmRpYW5f/QmFua19sb2dvLnN2/Zy81MTJweC1JbmRp/YW5fQmFua19sb2dv/LnN2Zy5wbmc',
      accountValidation: AccountValidation(
        minLength: 9,
        maxLength: 18,
        formatNotes: 'Varies between 9 and 18 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Central Bank of India',
      type: 'PSB',
      shortCode: 'CBI',
      ifscPrefix: 'CBIN',
      logoImageUrl: 'https://centralbank.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 10,
        maxLength: 10,
        formatNotes: 'Typically 10 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Indian Overseas Bank',
      type: 'PSB',
      shortCode: 'IOB',
      ifscPrefix: 'IOBA',
      logoImageUrl: 'https://iob.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'UCO Bank',
      type: 'PSB',
      shortCode: 'UCO',
      ifscPrefix: 'UCBA',
      logoImageUrl: 'https://uco.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Bank of Maharashtra',
      type: 'PSB',
      shortCode: 'BOM',
      ifscPrefix: 'MAHB',
      logoImageUrl: 'https://bankofmaharashtra.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Punjab and Sind Bank',
      type: 'PSB',
      shortCode: 'PSB',
      ifscPrefix: 'PSIB',
      logoImageUrl: 'https://punjabandsind.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    // Private Sector Banks
    BankInfo(
      bankName: 'HDFC Bank',
      type: 'PVB',
      shortCode: 'HDFC',
      ifscPrefix: 'HDFC',
      logoImageUrl: 'https://hdfc.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'ICICI Bank',
      type: 'PVB',
      shortCode: 'ICICI',
      ifscPrefix: 'ICIC',
      logoImageUrl: 'https://icici.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 12,
        maxLength: 12,
        formatNotes: 'Typically 12 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Axis Bank',
      type: 'PVB',
      shortCode: 'AXIS',
      ifscPrefix: 'UTIB',
      logoImageUrl: 'https://axis.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Kotak Mahindra Bank',
      type: 'PVB',
      shortCode: 'KMB',
      ifscPrefix: 'KKBK',
      logoImageUrl: 'https://kotak.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'IDBI Bank',
      type: 'PVB',
      shortCode: 'IDBI',
      ifscPrefix: 'IBKL',
      logoImageUrl: 'https://idbi.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Yes Bank',
      type: 'PVB',
      shortCode: 'YESB',
      ifscPrefix: 'YESB',
      logoImageUrl: 'https://yes.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Federal Bank',
      type: 'PVB',
      shortCode: 'FDRL',
      ifscPrefix: 'FDRL',
      logoImageUrl: 'https://federal.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'IndusInd Bank',
      type: 'PVB',
      shortCode: 'INDUS',
      ifscPrefix: 'INDB',
      logoImageUrl: 'https://indusind.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 12,
        maxLength: 12,
        formatNotes: 'Typically 12 digits.',
      ),
    ),
    BankInfo(
      bankName: 'IDFC First Bank',
      type: 'PVB',
      shortCode: 'IDFCF',
      ifscPrefix: 'IDFB',
      logoImageUrl: 'https://idfcfirst.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 12,
        maxLength: 12,
        formatNotes: 'Typically 12 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Bandhan Bank',
      type: 'PVB',
      shortCode: 'BANDHAN',
      ifscPrefix: 'BDBL',
      logoImageUrl: 'https://bandhan.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 12,
        maxLength: 12,
        formatNotes: 'Typically 12 digits.',
      ),
    ),
    BankInfo(
      bankName: 'RBL Bank',
      type: 'PVB',
      shortCode: 'RBL',
      ifscPrefix: 'RATN',
      logoImageUrl: 'https://rbl.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Jammu & Kashmir Bank',
      type: 'PVB',
      shortCode: 'JKB',
      ifscPrefix: 'JAKA',
      logoImageUrl: 'https://jkb.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Karnataka Bank',
      type: 'PVB',
      shortCode: 'KBL',
      ifscPrefix: 'KARB',
      logoImageUrl: 'https://karnatakabank.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Karur Vysya Bank',
      type: 'PVB',
      shortCode: 'KVB',
      ifscPrefix: 'KVBL',
      logoImageUrl: 'https://kvb.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Tamilnad Mercantile Bank',
      type: 'PVB',
      shortCode: 'TMB',
      ifscPrefix: 'TMBL',
      logoImageUrl: 'https://tmb.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'South Indian Bank',
      type: 'PVB',
      shortCode: 'SIB',
      ifscPrefix: 'SIBL',
      logoImageUrl: 'https://southindianbank.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'City Union Bank',
      type: 'PVB',
      shortCode: 'CUB',
      ifscPrefix: 'CIUB',
      logoImageUrl: 'https://cityunionbank.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'CSB Bank',
      type: 'PVB',
      shortCode: 'CSB',
      ifscPrefix: 'CSBK',
      logoImageUrl: 'https://csb.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 16,
        formatNotes: 'Typically 14-16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'DCB Bank',
      type: 'PVB',
      shortCode: 'DCB',
      ifscPrefix: 'DCBL',
      logoImageUrl: 'https://dcb.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 14,
        maxLength: 14,
        formatNotes: 'Typically 14 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Dhanlaxmi Bank',
      type: 'PVB',
      shortCode: 'DLB',
      ifscPrefix: 'DLXB',
      logoImageUrl: 'https://dhan.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 16,
        maxLength: 16,
        formatNotes: 'Typically 16 digits.',
      ),
    ),
    BankInfo(
      bankName: 'Nainital Bank',
      type: 'PVB',
      shortCode: 'NTBL',
      ifscPrefix: 'NTBL',
      logoImageUrl: 'https://nainitalbank.bank.in/logo.png',
      accountValidation: AccountValidation(
        minLength: 15,
        maxLength: 15,
        formatNotes: 'Typically 15 digits.',
      ),
    ),
  ];

  static BankInfo? getBankByName(String bankName) {
    try {
      // First try to match by full bank name
      return banks.firstWhere(
        (bank) => bank.bankName.toLowerCase() == bankName.toLowerCase(),
      );
    } catch (e) {
      // If not found, try to match by short code
      try {
        return banks.firstWhere(
          (bank) => bank.shortCode.toLowerCase() == bankName.toUpperCase(),
        );
      } catch (e2) {
        return null;
      }
    }
  }
  
  static BankInfo? getBankByShortCode(String shortCode) {
    try {
      return banks.firstWhere(
        (bank) => bank.shortCode.toUpperCase() == shortCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static bool validateIFSC(String ifsc) {
    if (ifsc.length != ifscLength) return false;
    final regex = RegExp(ifscRegex);
    return regex.hasMatch(ifsc.toUpperCase());
  }

  static String? validateAccountNumber(String accountNumber, String bankName) {
    final bank = getBankByName(bankName);
    if (bank == null) {
      return 'Bank not found. Please select a valid bank.';
    }

    // Remove spaces and non-digits
    final cleanAccountNumber = accountNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanAccountNumber.length < bank.accountValidation.minLength ||
        cleanAccountNumber.length > bank.accountValidation.maxLength) {
      return 'Account number for ${bank.bankName} should be ${bank.accountValidation.minLength}-${bank.accountValidation.maxLength} digits.';
    }

    return null;
  }

  static String? validateIFSCForBank(String ifsc, String bankName) {
    if (!validateIFSC(ifsc)) {
      return 'IFSC code must be 11 characters in format: AAAA0XXXXXX (4 letters, 0, 6 alphanumeric)';
    }

    final bank = getBankByName(bankName);
    if (bank == null) {
      return null; // Bank validation already handled
    }

    final ifscUpper = ifsc.toUpperCase();
    if (!ifscUpper.startsWith(bank.ifscPrefix)) {
      return 'IFSC code should start with ${bank.ifscPrefix} for ${bank.bankName}';
    }

    return null;
  }
}



