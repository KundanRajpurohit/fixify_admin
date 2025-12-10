import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/models/bank_model.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class AddEditBankAccountScreen extends ConsumerStatefulWidget {
  final BankAccount? bankAccount;

  const AddEditBankAccountScreen({
    super.key,
    this.bankAccount,
  });

  @override
  ConsumerState<AddEditBankAccountScreen> createState() =>
      _AddEditBankAccountScreenState();
}

class _AddEditBankAccountScreenState extends ConsumerState<AddEditBankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();

  String? _selectedBank;
  BankInfo? _selectedBankInfo;
  bool _isSubmitting = false;


  @override
  void initState() {
    super.initState();
    if (widget.bankAccount != null) {
      _accountHolderNameController.text = widget.bankAccount!.accountHolderName;
      _accountNumberController.text = widget.bankAccount!.accountNumber;
      _ifscCodeController.text = widget.bankAccount!.ifscCode;
      _selectedBank = widget.bankAccount!.bankName;
      _selectedBankInfo = BankValidationRules.getBankByName(_selectedBank!);
    }
  }

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(bool isEdit) {
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
              Text(
                isEdit ? 'Bank Account Updated' : 'Bank Account Added',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your bank details have been submitted and are now under review. We\'ll notify you once they are verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                    Navigator.of(context).pop(true); // Return true to indicate success
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Bank Accounts' : 'Go to Bank Accounts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final isEdit = widget.bankAccount != null;

      if (isEdit && widget.bankAccount?.id != null) {
        // Update existing bank account
        final result = await userService.updateBankAccount(
          id: widget.bankAccount!.id!,
          accountHolderName: _accountHolderNameController.text.trim(),
          bank: _selectedBank!,
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscCodeController.text.trim().toUpperCase(),
        );

        result.fold(
          (failure) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update bank account: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          (data) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
              _showSuccessDialog(true);
            }
          },
        );
      } else {
        // Add new bank account
        final result = await userService.addBankAccount(
          accountHolderName: _accountHolderNameController.text.trim(),
          bank: _selectedBank!,
          accountNumber: _accountNumberController.text.trim(),
          ifscCode: _ifscCodeController.text.trim().toUpperCase(),
        );

        result.fold(
          (failure) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add bank account: ${failure.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          (data) {
            if (mounted) {
              setState(() {
                _isSubmitting = false;
              });
              _showSuccessDialog(false);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.bankAccount != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.4),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit New Bank Account' : 'Add New Bank Account',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.notifications,
                      color: Color(0xFF217043),
                      size: 22,
                    ),
                    onPressed: () {
                      // Handle notifications
                    },
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                      _buildTextField(
                        label: 'Account Holder Name',
                        controller: _accountHolderNameController,
                        hint: 'Enter Account Holder Name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter account holder name';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildBankDropdown(),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'Account Number',
                        controller: _accountNumberController,
                        hint: 'Enter Account Number',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter account number';
                          }
                          if (_selectedBank == null) {
                            return 'Please select a bank first';
                          }
                          final error = BankValidationRules.validateAccountNumber(
                            value.trim(),
                            _selectedBank!,
                          );
                          return error;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: 'IFSC Code',
                        controller: _ifscCodeController,
                        hint: 'Enter IFSC Code',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                          UpperCaseTextFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter IFSC code';
                          }
                          if (_selectedBank == null) {
                            return 'Please select a bank first';
                          }
                          final error = BankValidationRules.validateIFSCForBank(
                            value.trim(),
                            _selectedBank!,
                          );
                          return error;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Submit Button
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
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEdit ? 'Save Bank Details' : 'Add Bank Details',
                        style: const TextStyle(
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FormField<BankInfo>(
          initialValue: _selectedBankInfo,
          validator: (value) {
            if (value == null) {
              return 'Please select a bank';
            }
            return null;
          },
          builder: (FormFieldState<BankInfo> field) {
            return DropdownSearch<BankInfo>(
              selectedItem: _selectedBankInfo,
              items: BankValidationRules.banks,
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search bank...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                menuProps: const MenuProps(
                  backgroundColor: Colors.white,
                  elevation: 8,
                ),
              ),
              itemAsString: (BankInfo bank) => bank.bankName,
              filterFn: (BankInfo bank, String filter) {
                return bank.bankName.toLowerCase().contains(filter.toLowerCase()) ||
                    bank.shortCode.toLowerCase().contains(filter.toLowerCase());
              },
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Search and select bank',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  errorText: field.errorText,
                ),
              ),
              onChanged: (BankInfo? bank) {
                field.didChange(bank);
                setState(() {
                  if (bank != null) {
                    _selectedBank = bank.bankName;
                    _selectedBankInfo = bank;
                    // Clear account number and IFSC when bank changes
                    _accountNumberController.clear();
                    _ifscCodeController.clear();
                  }
                });
              },
            );
          },
        ),
        if (_selectedBankInfo != null) ...[
          const SizedBox(height: 8),
          Text(
            'Account number should be ${_selectedBankInfo!.accountValidation.minLength}-${_selectedBankInfo!.accountValidation.maxLength} digits',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'IFSC should start with ${_selectedBankInfo!.ifscPrefix}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }
}

// Custom TextInputFormatter to convert to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}



