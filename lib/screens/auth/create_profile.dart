import 'dart:io';

import 'package:fixify_admin/config/app_colors.dart';
import 'package:fixify_admin/helpers/translate_helper.dart';
import 'package:fixify_admin/providers/auth_provider.dart';
import 'package:fixify_admin/screens/auth/country_picker_screen.dart';
import 'package:fixify_admin/screens/auth/otp_verification_screen.dart';
import 'package:fixify_admin/services/device_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:page_transition/page_transition.dart';
import '../../providers/location_provider.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isPhotoUpdating = false;
  File? _profileImage;

  // Local-only contact info (no provider / API)
  String _selectedFlag = '🇮🇳';
  String _selectedDialCode = '+91';
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

  // Services state
  List<String> _services = [];
  String? _selectedService;
  bool _isLoadingServices = false;

  @override
  void initState() {
    super.initState();
    // Load services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServices();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final result = await userService.fetchServices();

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoadingServices = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${ref.t('auth.failed_to_load_services')}: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (services) {
          setState(() {
            _services = services;
            _isLoadingServices = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingServices = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${ref.t('auth.error_loading_services')}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate email format
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(ref.t('auth.please_enter_valid_email')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate phone number
    final phoneNumber = _phoneNumberController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(ref.t('auth.please_enter_phone')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userService = ref.read(userServiceProvider);
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();
      
      // Use phone number as entered (API expects just the number without dial code)
      final mobileNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), ''); // Remove any non-digits

      // Validate service selection
      if (_selectedService == null || _selectedService!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(ref.t('auth.please_select_service')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get device info
      final deviceInfo = await DeviceInfoService.getCachedDeviceInfo();
      final deviceToken = deviceInfo['deviceToken'];
      final platform = deviceInfo['platform'];

      print('📝 [CreateProfile] Registering partner:');
      print('   - name: $fullName');
      print('   - mobile: $mobileNumber');
      print('   - email: $email');
      print('   - services: $_selectedService');
      print('   - deviceToken: ${deviceToken != null ? "${deviceToken.substring(0, 20)}..." : "null"}');
      print('   - platform: $platform');

      final result = await userService.partnerRegister(
        name: fullName,
        mobile: mobileNumber,
        email: email,
        services: _selectedService,
        image: _profileImage,
        deviceToken: deviceToken,
        platform: platform,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
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
            _isLoading = false;
          });

          print('✅ [CreateProfile] Registration successful');
          print('📊 [CreateProfile] Response: $data');

          // Store mobile number and OTP in auth provider for OTP verification
          final currentState = ref.read(authProvider);
          ref.read(authProvider.notifier).state = currentState.copyWith(
            phoneNumber: data['mobile']?.toString() ?? mobileNumber,
            countryCode: _selectedDialCode,
            otp: data['otp']?.toString(), // Store OTP if provided in response
          );

          // Navigate to OTP verification screen
          Navigator.push(
            context,
            PageTransition(
              type: PageTransitionType.fade,
              duration: const Duration(milliseconds: 500),
              child: const OTPVerificationScreen(
                isCreateAccount: true,
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          ref.t('auth.create_account'),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
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
                // No-op (no API / navigation for now)
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(height: 220, color: AppColors.secondary.withOpacity(0.4)),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileFormCard(),
                    const SizedBox(height: 20),
                    _buildContactInformationCard(
                      _phoneNumberController,
                      _emailController,
                    ),
                    const SizedBox(height: 20),
                    _buildServicesCard(),
                    SizedBox(height:15.h),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                ref.t('common.continue'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ).animate().scale(duration: 200.ms, delay: 200.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                    child:
                        _profileImage == null
                            ? const Icon(
                              Icons.person,
                              size: 54,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  if (_isPhotoUpdating)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 6,
                    right: 0,
                    child: GestureDetector(
                      onTap:
                          _isPhotoUpdating ? null : () => _showImageOptions(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF217043),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            ref.t('auth.first_name'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: ref.t('auth.enter_first_name'),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF217043)),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return ref.t('auth.please_enter_first_name');
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          Text(
            ref.t('auth.last_name'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: ref.t('auth.enter_last_name'),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF217043)),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return ref.t('auth.please_enter_last_name');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactInformationCard(
    TextEditingController phoneController,
    TextEditingController emailController,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ref.t('auth.contact_information'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ref.t('auth.phone_number'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openCountryPicker,
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedFlag,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDialCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: TextFormField(
                    controller: phoneController,

                    decoration: InputDecoration(
                      hintText: '00 000 00000', // Phone format hint
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ref.t('auth.please_enter_phone');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ref.t('auth.email'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: ref.t('auth.enter_email'),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return ref.t('auth.please_enter_email');
              }
              if (!value.contains('@')) {
                return ref.t('auth.please_enter_valid_email');
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.t('auth.service_profession'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: InputDecoration(
                hintText: ref.t('auth.select_service'),
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                // contentPadding: const EdgeInsets.symmetric(
                //   horizontal: 16,
                //   vertical: 16,
                // ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF217043),
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                prefixIcon: const Icon(
                  Icons.work_outline,
                  color: Color(0xFF217043),
                  size: 22,
                ),
              ),
              items: _services.map((service) {
                return DropdownMenuItem<String>(
                  value: service,
                  child: Text(
                    service,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isLoadingServices
                  ? null
                  : (value) {
                      setState(() {
                        _selectedService = value;
                      });
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return ref.t('auth.please_select_service');
                }
                return null;
              },
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
                size: 24,
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              isExpanded: true,
              menuMaxHeight: 300,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(ref.t('auth.choose_from_gallery')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(ref.t('auth.take_a_photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: Text(
                    ref.t('auth.remove_photo'),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeProfilePhoto();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      setState(() {
        _isPhotoUpdating = true;
      });

      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (file != null) {
        setState(() {
          _profileImage = File(file.path);
        });
      }

      if (!mounted) return;

      setState(() {
        _isPhotoUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            file == null
                ? ref.t('auth.no_image_selected')
                : ref.t('auth.profile_photo_updated'),
          ),
          backgroundColor: file == null ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPhotoUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text(ref.t('auth.image_selection_failed')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeProfilePhoto() {
    setState(() {
      _profileImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text(ref.t('auth.profile_photo_removed')),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openCountryPicker() async {
    final selected = await Navigator.push<Country>(
      context,
      PageTransition(
        type: PageTransitionType.bottomToTop,
        duration: const Duration(milliseconds: 300),
        child: const CountryPickerScreen(),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedDialCode = selected.dialCode;
        _selectedFlag = selected.flag;
      });
    }
  }
}
