import 'package:fixify_admin/providers/location_provider.dart';
import 'package:fixify_admin/screens/dashboard/job_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddAdditionalServiceSheet extends ConsumerStatefulWidget {
  final String token;

  const AddAdditionalServiceSheet({super.key, required this.token});

  @override
  ConsumerState<AddAdditionalServiceSheet> createState() =>
      _AddAdditionalServiceSheetState();

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: Color(0xFF2F6B3F)),
      ),
    );
  }
}

class _AddAdditionalServiceSheetState
    extends ConsumerState<AddAdditionalServiceSheet> {
  TextEditingController serviceNameController = TextEditingController();

  TextEditingController priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title
            const Text(
              'Add Additional Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 8),

            /// Subtitle
            Text(
              'Add extra services to this ongoing job based on the customer’s updated requirements.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 20),

            /// Service Name
            const Text(
              'Service',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: serviceNameController,
              decoration: AddAdditionalServiceSheet._inputDecoration(
                'Service Name...',
              ),
            ),

            const SizedBox(height: 16),

            /// Service Charge
            const Text(
              'Service Charge',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: AddAdditionalServiceSheet._inputDecoration(
                'e.g. ₹199',
              ),
            ),

            const SizedBox(height: 24),

            /// Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await ref
                          .read(userServiceProvider)
                          .addAdditionalItem(
                            bookingToken: widget.token,
                            item: serviceNameController.text,
                            price: int.parse(priceController.text),
                            quantity: 1,
                          );

                      result.fold((failure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        );
                      }, (data) {});

                      Navigator.pop(
                        context,
                        AdditionalService(
                          name: serviceNameController.text,
                          description: 'Additonal Service',
                          price: int.parse(priceController.text),
                        ),
                      );
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
