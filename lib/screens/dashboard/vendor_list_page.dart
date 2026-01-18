import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fixify_admin/components/custom_app_bar.dart';
import 'package:fixify_admin/models/vendor_model.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen> {
  bool _isLoading = false;
  List<VendorModel> _vendors = [];

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);

    final userService = ref.read(userServiceProvider);
    final result = await userService.getVendorList();

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
        final list =
            (data['data'] as List).map((e) => VendorModel.fromJson(e)).toList();

        setState(() {
          _vendors = list;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: CustomAppBar(title: ref.t('profile.our_vendors'), showbackButton: true),

      body:
          _isLoading
              ?  Center(child: CircularProgressIndicator())
              : _vendors.isEmpty
              ?  Center(
                child: Text(
                  ref.t('dashboard.no_vendors_found'),
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _vendors.length,
                itemBuilder: (context, index) {
                  final vendor = _vendors[index];
                  return _buildVendorCard(vendor);
                },
              ),
    );
  }

  Widget _buildVendorCard(VendorModel vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Vendor Name
          Text(
            vendor.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          /// Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                vendor.address,
                style: TextStyle(fontSize: 14, color: Color(0xff4B5563)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// Mobile + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vendor.mobile,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              // TextButton(
              //   onPressed: () {
              //     // later: assign vendor / call vendor
              //   },
              //   child: const Text(
              //     'Select',
              //     style: TextStyle(fontWeight: FontWeight.w600),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
