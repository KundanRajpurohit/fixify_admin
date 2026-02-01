import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../dio/resulr.dart';
import '../models/earnings_model.dart';
import '../models/notification_model.dart';

class UserService {
  final Dio _dio;

  UserService(this._dio);

  // Save user ID and token to SharedPreferences
  Future<void> _saveUserData(String userId, String userToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_token', userToken);
  }

  // Save authorization token to SharedPreferences
  Future<void> _saveAuthToken(String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authorization_token', authToken);
  }

  // Get user ID from SharedPreferences
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Get user token from SharedPreferences
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }

  // Get authorization token from SharedPreferences
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authorization_token');
  }

  // Clear all user data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_token');
    await prefs.remove('authorization_token');
  }

  // Clear all SharedPreferences data (complete logout)
  Future<void> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('🧹 [UserService] All SharedPreferences cleared successfully');
    } catch (e) {
      print('❌ [UserService] Error clearing SharedPreferences: $e');
    }
  }

  // Set default address
  Future<ApiResult<Map<String, dynamic>>> setDefaultAddress({
    required String address,
    required String state,
    required String city,
    required String landmark,
    required String pincode,
  }) async {
    try {
      print('🚀 [UserService] Starting setDefaultAddress API call');
      print('📝 [UserService] Request data:');
      print('   - address: $address');
      print('   - state: $state');
      print('   - city: $city');
      print('   - landmark: $landmark');
      print('   - pincode: $pincode');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerAddDefaultAddress}',
      );
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerAddDefaultAddress}',
      );

      final formData = FormData.fromMap({
        'address': address,
        'state': state,
        'city': city,
        'landmark': landmark,
        'pincode': pincode,
      });

      print('📤 [UserService] Sending request...');
      final response = await _dio.post(
        ApiConfig.partnerAddDefaultAddress,
        data: formData,
      );

      print('📥 [UserService] Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Response status: ${data['status']}');
        print('📋 [UserService] Response message: ${data['message']}');

        if (data['status'] == true) {
          // Save user ID and token from response
          final userData = data['data'];
          print('💾 [UserService] Saving user data:');
          print('   - User ID: ${userData['userid']}');
          print('   - User Token: ${userData['token']}');

          await _saveUserData(userData['userid'], userData['token']);
          print('✅ [UserService] User data saved successfully');
          return right(data);
        } else {
          print('❌ [UserService] API returned status: false');
          print('❌ [UserService] Error message: ${data['message']}');
          return left(
            ServerFailure(data['message'] ?? 'Failed to save address', 400),
          );
        }
      } else {
        print('❌ [UserService] HTTP Error: ${response.statusCode}');
        print('❌ [UserService] Response: ${response.data}');
        return left(
          ServerFailure('Failed to save address', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Unexpected error: $e');
      print('❌ [UserService] Error type: ${e.runtimeType}');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Verify OTP
  Future<ApiResult<Map<String, dynamic>>> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    try {
      print('🔐 [UserService] Starting verifyOtp API call');
      print('📝 [UserService] Request data:');
      print('   - mobile: $mobile');
      print('   - otp: $otp');
      print('🌐 [UserService] API endpoint: ${ApiConfig.verifyOtp}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.verifyOtp}',
      );

      final formData = FormData.fromMap({'mobile': mobile, 'otp': otp});

      print('📤 [UserService] Sending OTP verification request...');
      final response = await _dio.post(ApiConfig.verifyOtp, data: formData);

      print('📥 [UserService] OTP Verification Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] OTP verification successful');
        print('📋 [UserService] Response message: ${data['message']}');

        // Check if status is true and token exists (for both "Login successful" and "OTP Verified" messages)
        if ((data['status'] == true || data['status'] == 'true') &&
            data['token'] != null) {
          print('🎉 [UserService] OTP verified successfully!');
          print('🔑 [UserService] Authorization token: ${data['token']}');

          // Save authorization token
          await _saveAuthToken(data['token']);
          print('💾 [UserService] Authorization token saved successfully');
          return right(data);
        } else {
          print(
            '❌ [UserService] OTP verification failed - message: ${data['message']}',
          );
          return left(
            ServerFailure(data['message'] ?? 'OTP verification failed', 400),
          );
        }
      } else {
        print(
          '❌ [UserService] OTP Verification HTTP Error: ${response.statusCode}',
        );
        print('❌ [UserService] OTP Verification Response: ${response.data}');
        return left(
          ServerFailure('Failed to verify OTP', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] OTP Verification DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] OTP Verification Unexpected error: $e');
      print('❌ [UserService] OTP Verification Error type: ${e.runtimeType}');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get all FAQs
  Future<ApiResult<Map<String, dynamic>>> getAllFAQs() async {
    try {
      print('❓ [UserService] Starting getAllFAQs API call');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}/all-faqs');

      final response = await _dio.get('/all-faqs');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] FAQs retrieved successfully');
        print('📊 [UserService] FAQs response: ${response.data}');
        return right(response.data);
      } else {
        print('❌ [UserService] FAQs API failed');
        return left(
          ServerFailure('Failed to retrieve FAQs', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] FAQs API exception: ${e.message}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] FAQs exception: $e');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Fetch list of services
  Future<ApiResult<List<String>>> fetchServices() async {
    try {
      print('🔍 [UserService] Starting fetchServices API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerListServices}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerListServices}',
      );

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.partnerListServices}'),
      );

      print('📥 [UserService] Services Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> servicesData = data['data'];
          final List<String> services =
              servicesData
                  .map((service) => service['title'] as String)
                  .toList();
          print('✅ [UserService] Services fetched successfully: $services');
          return right(services);
        } else {
          print('❌ [UserService] Services fetch failed - invalid response');
          return left(
            ServerFailure(
              data['message'] ?? 'Failed to fetch services',
              response.statusCode,
            ),
          );
        }
      } else {
        print('❌ [UserService] Services HTTP Error: ${response.statusCode}');
        return left(
          ServerFailure('Failed to fetch services', response.statusCode),
        );
      }
    } catch (e) {
      print('❌ [UserService] Services fetch error: $e');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Registration
  Future<ApiResult<Map<String, dynamic>>> partnerRegister({
    required String name,
    required String mobile,
    required String email,
    String? services,
    File? image,
    String? deviceToken,
    String? platform,
  }) async {
    try {
      print('👤 [UserService] Starting partnerRegister API call');
      print('📝 [UserService] Request data:');
      print('   - name: $name');
      print('   - mobile: $mobile');
      print('   - email: $email');
      print('   - services: ${services ?? "null"}');
      print('   - image: ${image?.path ?? "null"}');
      print('   - deviceToken: ${deviceToken ?? "null"}');
      print('   - platform: ${platform ?? "null"}');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerRegister}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerRegister}',
      );

      final formData = FormData.fromMap({
        'name': name,
        'mobile': mobile,
        'email': email,
        if (services != null) 'services': services,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'devicetoken': deviceToken,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
        if (image != null)
          'image': await MultipartFile.fromFile(
            image.path,
            filename: image.path.split(Platform.pathSeparator).last,
          ),
      });

      print('📤 [UserService] Sending partner registration request...');
      final response = await _dio.post(
        ApiConfig.partnerRegister,
        data: formData,
      );

      print('📥 [UserService] Partner Registration Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner registration successful');
        print('📋 [UserService] Response message: ${data['message']}');
        return right(data);
      } else {
        print(
          '❌ [UserService] Partner Registration HTTP Error: ${response.statusCode}',
        );
        print(
          '❌ [UserService] Partner Registration Response: ${response.data}',
        );
        return left(
          ServerFailure(
            'Failed to register partner',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] Partner Registration DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner Registration Unexpected error: $e');
      print(
        '❌ [UserService] Partner Registration Error type: ${e.runtimeType}',
      );
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Add Default Address
  Future<ApiResult<Map<String, dynamic>>> partnerAddDefaultAddress({
    required String address,
    required String state,
    required String city,
    required String landmark,
    required String pincode,
  }) async {
    try {
      print('📍 [UserService] Starting partnerAddDefaultAddress API call');
      print('📝 [UserService] Request data:');
      print('   - address: $address');
      print('   - state: $state');
      print('   - city: $city');
      print('   - landmark: $landmark');
      print('   - pincode: $pincode');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerAddDefaultAddress}',
      );
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerAddDefaultAddress}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      print(
        '🔑 [UserService] Using authorization token: ${authToken.substring(0, 10)}...',
      );

      final formData = FormData.fromMap({
        'address': address,
        'state': state,
        'city': city,
        'landmark': landmark,
        'pincode': pincode,
      });

      print('📤 [UserService] Sending partner add default address request...');
      final response = await _dio.post(
        ApiConfig.partnerAddDefaultAddress,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      print('📥 [UserService] Partner Add Default Address Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner add default address successful');
        print('📋 [UserService] Response message: ${data['message']}');

        // Save user ID and token from response if available
        if (data['data'] != null) {
          final userData = data['data'];
          if (userData['userid'] != null && userData['token'] != null) {
            await _saveUserData(userData['userid'], userData['token']);
            print('💾 [UserService] User data saved successfully');
          }
        }

        return right(data);
      } else {
        print(
          '❌ [UserService] Partner Add Default Address HTTP Error: ${response.statusCode}',
        );
        print(
          '❌ [UserService] Partner Add Default Address Response: ${response.data}',
        );
        return left(
          ServerFailure(
            'Failed to add default address',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      print(
        '❌ [UserService] Partner Add Default Address DioException occurred:',
      );
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner Add Default Address Unexpected error: $e');
      print(
        '❌ [UserService] Partner Add Default Address Error type: ${e.runtimeType}',
      );
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Upload Documents
  Future<ApiResult<Map<String, dynamic>>> partnerUploadDocuments({
    File? nationalId,
    File? proofNationalId,
    File? servicesLicense,
  }) async {
    try {
      print('📄 [UserService] Starting partnerUploadDocuments API call');
      print('📝 [UserService] Request files:');
      print('   - national_id: ${nationalId?.path ?? "null"}');
      print('   - proof_national_id: ${proofNationalId?.path ?? "null"}');
      print('   - services_license: ${servicesLicense?.path ?? "null"}');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerUploadDocuments}',
      );
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerUploadDocuments}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      print(
        '🔑 [UserService] Using authorization token: ${authToken.substring(0, 10)}...',
      );

      final formData = FormData();

      if (nationalId != null) {
        formData.files.add(
          MapEntry(
            'national_id',
            await MultipartFile.fromFile(
              nationalId.path,
              filename: nationalId.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      if (proofNationalId != null) {
        formData.files.add(
          MapEntry(
            'proof_national_id',
            await MultipartFile.fromFile(
              proofNationalId.path,
              filename: proofNationalId.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      if (servicesLicense != null) {
        formData.files.add(
          MapEntry(
            'services_license',
            await MultipartFile.fromFile(
              servicesLicense.path,
              filename: servicesLicense.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      print('📤 [UserService] Sending partner upload documents request...');
      final response = await _dio.post(
        ApiConfig.partnerUploadDocuments,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      print('📥 [UserService] Partner Upload Documents Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner upload documents successful');
        print('📋 [UserService] Response message: ${data['message']}');
        return right(data);
      } else {
        print(
          '❌ [UserService] Partner Upload Documents HTTP Error: ${response.statusCode}',
        );
        print(
          '❌ [UserService] Partner Upload Documents Response: ${response.data}',
        );
        return left(
          ServerFailure(
            'Failed to upload documents',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] Partner Upload Documents DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner Upload Documents Unexpected error: $e');
      print(
        '❌ [UserService] Partner Upload Documents Error type: ${e.runtimeType}',
      );
      return left(UnknownFailure(e.toString()));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getVendorList() async {
    try {
      print('🏪 [UserService] Starting getVendorList API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerVendorList}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerVendorList,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      print('📥 [UserService] Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Vendor list fetched successfully');
        return right(response.data);
      } else {
        print('⚠️ [UserService] Failed to fetch vendor list');
        return left(
          ServerFailure(
            'Failed to fetch vendor list',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] DioException occurred');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Unknown error: $e');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Login
  Future<ApiResult<Map<String, dynamic>>> partnerLogin({
    required String mobile,
    String? deviceToken,
    String? platform,
  }) async {
    try {
      print('🔐 [UserService] Starting partnerLogin API call');
      print('📝 [UserService] Request data:');
      print('   - mobile: $mobile');
      print('   - deviceToken: ${deviceToken ?? "null"}');
      print('   - platform: ${platform ?? "null"}');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerLogin}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerLogin}',
      );

      final formData = FormData.fromMap({
        'mobile': mobile,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'devicetoken': deviceToken,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      });

      print('📤 [UserService] Sending partner login request...');
      final response = await _dio.post(ApiConfig.partnerLogin, data: formData);

      print('📥 [UserService] Partner Login Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner login response received');
        print('📋 [UserService] Response status: ${data['status']}');
        print('📋 [UserService] Response message: ${data['message']}');

        // Return the response as-is, let the caller handle different scenarios
        return right(data);
      } else {
        print(
          '❌ [UserService] Partner Login HTTP Error: ${response.statusCode}',
        );
        print('❌ [UserService] Partner Login Response: ${response.data}');
        return left(
          ServerFailure('Failed to login', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] Partner Login DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');

      // Handle error responses
      if (e.response != null && e.response!.statusCode == 200) {
        // Sometimes API returns status: false with 200 status code
        final data = e.response!.data;
        return right(data);
      }

      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner Login Unexpected error: $e');
      print('❌ [UserService] Partner Login Error type: ${e.runtimeType}');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Send OTP
  Future<ApiResult<Map<String, dynamic>>> partnerSendOtp({
    required String mobile,
  }) async {
    try {
      print('📱 [UserService] Starting partnerSendOtp API call');
      print('📝 [UserService] Request data:');
      print('   - mobile: $mobile');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerSendOtp}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerSendOtp}',
      );

      final formData = FormData.fromMap({'mobile': mobile});

      print('📤 [UserService] Sending partner OTP request...');
      final response = await _dio.post(
        ApiConfig.partnerSendOtp,
        data: formData,
      );

      print('📥 [UserService] Partner OTP Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner OTP sent successfully');
        print('📋 [UserService] Response message: ${data['message']}');
        print('🔢 [UserService] OTP: ${data['otp']}');
        return right(response.data);
      } else {
        print('❌ [UserService] Partner OTP HTTP Error: ${response.statusCode}');
        print('❌ [UserService] Partner OTP Response: ${response.data}');
        return left(
          ServerFailure('Failed to send OTP', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] Partner OTP DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner OTP Unexpected error: $e');
      print('❌ [UserService] Partner OTP Error type: ${e.runtimeType}');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Verify OTP
  Future<ApiResult<Map<String, dynamic>>> partnerVerifyOtp({
    required String mobile,
    required String otp,
  }) async
  {
    try {
      print('🔐 [UserService] Starting partnerVerifyOtp API call');
      print('📝 [UserService] Request data:');
      print('   - mobile: $mobile');
      print('   - otp: $otp');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerVerifyOtp}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerVerifyOtp}',
      );

      final formData = FormData.fromMap({'mobile': mobile, 'otp': otp});

      print('📤 [UserService] Sending partner OTP verification request...');
      final response = await _dio.post(
        ApiConfig.partnerVerifyOtp,
        data: formData,
      );

      print('📥 [UserService] Partner OTP Verification Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner OTP verification successful');
        print('📋 [UserService] Response message: ${data['message']}');

        if (data['token'] != null) {
          print('🔑 [UserService] Authorization token: ${data['token']}');
          await _saveAuthToken(data['token']);
          print('💾 [UserService] Authorization token saved successfully');
        }

        return right(data);
      } else {
        print(
          '❌ [UserService] Partner OTP Verification HTTP Error: ${response.statusCode}',
        );
        print(
          '❌ [UserService] Partner OTP Verification Response: ${response.data}',
        );
        return left(
          ServerFailure('Failed to verify OTP', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] Partner OTP Verification DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner OTP Verification Unexpected error: $e');
      print(
        '❌ [UserService] Partner OTP Verification Error type: ${e.runtimeType}',
      );
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Partner Profile
  Future<ApiResult<Map<String, dynamic>>> getPartnerProfile() async {
    try {
      print('👤 [UserService] Starting getPartnerProfile API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerProfile}');
      print(
        '🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.partnerProfile}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      print(
        '🔑 [UserService] Using authorization token: ${authToken.substring(0, 10)}...',
      );

      final response = await _dio.get(
        ApiConfig.partnerProfile,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      print('📥 [UserService] Partner Profile Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] Partner profile retrieved successfully');
        print('📋 [UserService] Response message: ${data['message']}');
        return right(data);
      } else {
        print(
          '❌ [UserService] Partner Profile HTTP Error: ${response.statusCode}',
        );
        print('❌ [UserService] Partner Profile Response: ${response.data}');
        return left(
          ServerFailure('Failed to get profile', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] Partner Profile DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Partner Profile Unexpected error: $e');
      print('❌ [UserService] Partner Profile Error type: ${e.runtimeType}');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Update Partner Profile
  Future<ApiResult<Map<String, dynamic>>> updatePartnerProfile({
    String? name,
    String? mobile,
    File? image,
  }) async {
    try {
      print('✏️ [UserService] Starting updatePartnerProfile API call');
      print('📝 [UserService] Request data:');
      print('   - name: $name');
      print('   - mobile: $mobile');
      print('   - image: ${image?.path ?? "null"}');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerUpdateProfile}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      final formData = FormData();

      if (name != null) {
        formData.fields.add(MapEntry('name', name));
      }
      if (mobile != null) {
        formData.fields.add(MapEntry('mobile', mobile));
      }
      if (image != null) {
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        ApiConfig.partnerUpdateProfile,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Profile updated successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to update profile', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Update Mobile Number
  Future<ApiResult<Map<String, dynamic>>> updateMobile({
    required String mobile,
  }) async {
    try {
      print('📱 [UserService] Starting updateMobile API call');
      print('📝 [UserService] Request data:');
      print('   - mobile: $mobile');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerUpdateMobile}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'mobile': mobile});

      final response = await _dio.post(
        ApiConfig.partnerUpdateMobile,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Mobile update request sent successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to update mobile', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Verify Mobile OTP
  Future<ApiResult<Map<String, dynamic>>> verifyMobileOtp({
    required String otp,
  }) async {
    try {
      print('🔐 [UserService] Starting verifyMobileOtp API call');
      print('📝 [UserService] Request data:');
      print('   - otp: $otp');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerMobileOtpVerify}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'otp': otp});

      final response = await _dio.post(
        ApiConfig.partnerMobileOtpVerify,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Mobile OTP verified successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to verify OTP', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Upload Partner Image
  Future<ApiResult<Map<String, dynamic>>> uploadPartnerImage(File image) async {
    try {
      print('📸 [UserService] Starting uploadPartnerImage API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerUploadImage}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await _dio.post(
        ApiConfig.partnerUploadImage,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Image uploaded successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to upload image', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Partner Logout
  Future<ApiResult<Map<String, dynamic>>> partnerLogout() async {
    try {
      print('🚪 [UserService] Starting partnerLogout API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerLogout}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        // Even if no token, clear preferences
        await clearAllPreferences();
        return left(const UnauthorizedFailure());
      }

      try {
        final response = await _dio.post(ApiConfig.partnerLogout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ [UserService] Logout successful');
          await clearAllPreferences();
          return right(response.data);
        } else {
          // Still clear preferences even if API fails
          await clearAllPreferences();
          return left(
            ServerFailure('Failed to logout', response.statusCode ?? 500),
          );
        }
      } on DioException catch (e) {
        // If 401 or any error, still clear preferences
        await clearAllPreferences();
        if (e.response?.statusCode == 401) {
          print(
            '🔒 [UserService] Logout returned 401, but preferences cleared',
          );
          return right({
            'status': true,
            'message': 'Logged out (token expired)',
          });
        }
        return left(_handleDioError(e));
      }
    } catch (e) {
      // Always clear preferences on any error
      await clearAllPreferences();
      return left(UnknownFailure(e.toString()));
    }
  }
  Future<ApiResult<Map<String, dynamic>>> addAdditionalItem({
  required String bookingToken,
  required String item,
  required int price,
  required int quantity,
}) async {
  try {
    print('➕ [UserService] Starting addAdditionalItem API call');
    print('🌐 [UserService] API endpoint: ${ApiConfig.partnerAddAdditionalItem}');
    print('🧾 [UserService] Booking token: $bookingToken');
    print('📦 [UserService] Item: $item | Price: $price | Qty: $quantity');

    final authToken = await getAuthToken();
    if (authToken == null) {
      print('❌ [UserService] No authorization token found');
      return left(const UnauthorizedFailure());
    }

    final response = await _dio.post(
      ApiConfig.partnerAddAdditionalItem,
      data: FormData.fromMap({
        'bookingtoken': bookingToken,
        'item': item,
        'price': price,
        'quantity': quantity,
      }),
      options: Options(
        headers: {'Authorization': 'Bearer $authToken'},
      ),
    );

    print('📥 [UserService] API Response Status: ${response.statusCode}');
    print('📦 [UserService] API Response Body: ${response.data}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('✅ [UserService] Additional item added successfully');
      return right(response.data);
    } else {
      print(
        '⚠️ [UserService] Failed to add additional item: Status ${response.statusCode}',
      );
      return left(
        ServerFailure(
          'Failed to add additional item',
          response.statusCode ?? 500,
        ),
      );
    }
  } on DioException catch (e) {
    print('❌ [UserService] DioException occurred');
    return left(_handleDioError(e));
  } catch (e) {
    print('❌ [UserService] Unknown error: $e');
    return left(UnknownFailure(e.toString()));
  }
}


  Future<ApiResult<Map<String, dynamic>>> startJob({
    required String bookingToken,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }
      final response = await _dio.post(
        '/partner/pose/start',
        data: FormData.fromMap({'bookingtoken': bookingToken}),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken', // your stored token
          },
        ),
      );

      return right(response.data);
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

 Future<ApiResult<Map<String, dynamic>>> endJob({
    required String bookingToken,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }
      final response = await _dio.post(
        '/partner/pose/end',
        data: FormData.fromMap({'bookingtoken': bookingToken}),
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken', // your stored token
          },
        ),
      );

      return right(response.data);
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get All Jobs
  Future<ApiResult<Map<String, dynamic>>> getAllJobs() async {
    try {
      print('📦 [UserService] Starting getAllJobs API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerAllJobs}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerAllJobs,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      print('📥 [UserService] API Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Successfully fetched all jobs');
        return right(response.data);
      } else {
        print(
          '⚠️ [UserService] Failed to fetch jobs: Status ${response.statusCode}',
        );
        return left(
          ServerFailure('Failed to fetch jobs', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] DioException occurred');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Unknown error: $e');
      return left(UnknownFailure(e.toString()));
    }
  }

  // job detail
  Future<ApiResult<Map<String, dynamic>>> getJobDetails(String token) async {
    try {
      print('📄 [UserService] Starting getJobDetails API call');
      print('🔑 [UserService] Token: $token');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerJobDetails(token)}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerJobDetails(token),
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      print('📥 [UserService] Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Job details fetched successfully');
        return right(response.data);
      } else {
        print('⚠️ [UserService] Failed: Status ${response.statusCode}');
        return left(
          ServerFailure(
            'Failed to fetch job details',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ [UserService] DioException occurred: ${e.message}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Unknown error: $e');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Upcoming Jobs
  Future<ApiResult<Map<String, dynamic>>> getUpcomingJobs() async {
    try {
      print('📦 [UserService] Starting getUpcomingJobs API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerUpcomingJobs,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch upcoming jobs',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Cancelled Jobs
  Future<ApiResult<Map<String, dynamic>>> getCancelledJobs() async {
    try {
      print('📦 [UserService] Starting getCancelledJobs API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerCancelledJobs,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch cancelled jobs',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Ongoing Jobs
  Future<ApiResult<Map<String, dynamic>>> getOngoingJobs() async {
    try {
      print('📦 [UserService] Starting getOngoingJobs API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerOngoingJobs,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch ongoing jobs',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Past Jobs
  Future<ApiResult<Map<String, dynamic>>> getPastJobs() async {
    try {
      print('📦 [UserService] Starting getPastJobs API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerPastJobs,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch past jobs',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Assign Upcoming Jobs (All Assigned Jobs)
  Future<ApiResult<Map<String, dynamic>>> getAssignUpcomingJobs() async {
    try {
      print('📦 [UserService] Starting getAssignUpcomingJobs API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerAssignUpcomingJobs,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch assigned jobs',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Accept Job
  Future<ApiResult<Map<String, dynamic>>> acceptJob(String jobToken) async {
    try {
      print('✅ [UserService] Starting acceptJob API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'job_token': jobToken});

      final response = await _dio.post(
        ApiConfig.partnerAcceptJob,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to accept job', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Assign Job
  Future<ApiResult<Map<String, dynamic>>> assignJob(String jobToken) async {
    try {
      print('📋 [UserService] Starting assignJob API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'job_token': jobToken});

      final response = await _dio.post(
        ApiConfig.partnerAssignJob,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to assign job', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Verify Job OTP
  Future<ApiResult<Map<String, dynamic>>> verifyJobOtp({
    required String jobToken,
    required String mobile,
    required String otp,
  }) async {
    try {
      print('🔐 [UserService] Starting verifyJobOtp API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'job_token': jobToken,
        'mobile': mobile,
        'otp': otp,
      });

      final response = await _dio.post(
        ApiConfig.partnerVerifyJobOtp,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to verify OTP', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Job Completed
  Future<ApiResult<Map<String, dynamic>>> jobCompleted(String jobToken) async {
    try {
      print('✅ [UserService] Starting jobCompleted API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'job_token': jobToken});

      final response = await _dio.post(
        ApiConfig.partnerJobCompleted,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to complete job', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Submit Job Report
  Future<ApiResult<Map<String, dynamic>>> submitJobReport({
    required String jobToken,
    required String prNotes,
    required List<File> prWorkImgs,
  }) async {
    try {
      print('📝 [UserService] Starting submitJobReport API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'job_token': jobToken,
        'pr_notes': prNotes,
      });

      // Add multiple images
      for (var img in prWorkImgs) {
        formData.files.add(
          MapEntry(
            'pr_work_imgs[]',
            await MultipartFile.fromFile(
              img.path,
              filename: img.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      final response = await _dio.post(
        ApiConfig.partnerSubmitJobReport,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to submit job report',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Rating Customer
  Future<ApiResult<Map<String, dynamic>>> ratingCustomer({
    required String jobToken,
    required String review,
    required String comment,
  }) async {
    try {
      print('⭐ [UserService] Starting ratingCustomer API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'job_token': jobToken,
        'review': review,
        'comment': comment,
      });

      final response = await _dio.post(
        ApiConfig.partnerRatingCustomer,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(
          ServerFailure('Failed to submit rating', response.statusCode ?? 500),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Update Notification Setting
  Future<ApiResult<Map<String, dynamic>>> updateNotification(
    bool enabled,
  ) async {
    try {
      print('🔔 [UserService] Starting updateNotification API call');
      print('📝 [UserService] Notification enabled: $enabled');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerUpdateNotification}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'notification': enabled ? '1' : '0'});

      final response = await _dio.post(
        ApiConfig.partnerUpdateNotification,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Notification setting updated successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to update notification',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Page Detail (Privacy Policy / Terms of Service)
  Future<ApiResult<Map<String, dynamic>>> getPageDetail(String slug) async {
    try {
      print('📄 [UserService] Starting getPageDetail API call');
      print('📝 [UserService] Slug: $slug');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerPageDetail}/$slug',
      );

      final response = await _dio.get('${ApiConfig.partnerPageDetail}/$slug');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Page detail retrieved successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to get page detail',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get All Bank Accounts
  Future<ApiResult<List<dynamic>>> getAllBankAccounts() async {
    try {
      print('🏦 [UserService] Starting getAllBankAccounts API call');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerBankAll}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(ApiConfig.partnerBankAll);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Bank accounts retrieved successfully');
        final data = response.data['data'] as List<dynamic>? ?? [];
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to get bank accounts',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Add Bank Account
  Future<ApiResult<Map<String, dynamic>>> addBankAccount({
    required String accountHolderName,
    required String bank,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      print('➕ [UserService] Starting addBankAccount API call');
      print('📝 [UserService] Request data:');
      print('   - account_holder_name: $accountHolderName');
      print('   - bank: $bank');
      print('   - account_number: $accountNumber');
      print('   - ifsc_code: $ifscCode');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerBankStore}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'account_holder_name': accountHolderName,
        'bank': bank,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      });

      final response = await _dio.post(
        ApiConfig.partnerBankStore,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Bank account added successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to add bank account',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Update Bank Account
  Future<ApiResult<Map<String, dynamic>>> updateBankAccount({
    required int id,
    required String accountHolderName,
    required String bank,
    required String accountNumber,
    required String ifscCode,
  }) async {
    try {
      print('✏️ [UserService] Starting updateBankAccount API call');
      print('📝 [UserService] Request data:');
      print('   - id: $id');
      print('   - account_holder_name: $accountHolderName');
      print('   - bank: $bank');
      print('   - account_number: $accountNumber');
      print('   - ifsc_code: $ifscCode');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerBankUpdate}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'id': id.toString(),
        'account_holder_name': accountHolderName,
        'bank': bank,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      });

      final response = await _dio.post(
        ApiConfig.partnerBankUpdate,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Bank account updated successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to update bank account',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Delete Bank Account
  Future<ApiResult<Map<String, dynamic>>> deleteBankAccount(int id) async {
    try {
      print('🗑️ [UserService] Starting deleteBankAccount API call');
      print('📝 [UserService] Bank account id: $id');
      print('🌐 [UserService] API endpoint: ${ApiConfig.partnerBankDelete}');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'id': id.toString()});

      final response = await _dio.post(
        ApiConfig.partnerBankDelete,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Bank account deleted successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to delete bank account',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Weekly Availability
  Future<ApiResult<Map<String, dynamic>>> getWeeklyAvailability() async {
    try {
      print('📅 [UserService] Starting getWeeklyAvailability API call');
      print(
        '🌐 [UserService] API endpoint: ${ApiConfig.partnerGetAvailability}',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(ApiConfig.partnerGetAvailability);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Weekly availability retrieved successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to get availability',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Update Day Availability
  Future<ApiResult<Map<String, dynamic>>> updateDayAvailability(
    String day,
    bool enabled,
  ) async {
    try {
      print('📅 [UserService] Starting updateDayAvailability API call');
      print('📝 [UserService] Day: $day, Enabled: $enabled');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      // Map day names to API endpoints
      final dayEndpoints = {
        'Monday': ApiConfig.partnerAvailabilityMon,
        'Tuesday': ApiConfig.partnerAvailabilityTue,
        'Wednesday': ApiConfig.partnerAvailabilityWed,
        'Thursday': ApiConfig.partnerAvailabilityThu,
        'Friday': ApiConfig.partnerAvailabilityFri,
        'Saturday': ApiConfig.partnerAvailabilitySat,
        'Sunday': ApiConfig.partnerAvailabilitySun,
      };

      // Map day names to API field names
      final dayFields = {
        'Monday': 'mon',
        'Tuesday': 'tue',
        'Wednesday': 'wed',
        'Thursday': 'thu',
        'Friday': 'fri',
        'Saturday': 'sat',
        'Sunday': 'sun',
      };

      final endpoint = dayEndpoints[day];
      final fieldName = dayFields[day];

      if (endpoint == null || fieldName == null) {
        return left(ServerFailure('Invalid day: $day', 400));
      }

      print('🌐 [UserService] API endpoint: $endpoint');

      final formData = FormData.fromMap({fieldName: enabled ? '1' : '0'});

      final response = await _dio.post(endpoint, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Day availability updated successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to update availability',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Dashboard Stats
  Future<ApiResult<Map<String, dynamic>>> getDashboardStats() async {
    try {
      print('📊 [UserService] Starting getDashboardStats API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerDashboard,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Dashboard stats fetched successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch dashboard stats',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Go Online/Offline
  Future<ApiResult<Map<String, dynamic>>> goOnline(bool isOnline) async {
    try {
      print('🌐 [UserService] Starting goOnline API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({'go_online': isOnline ? '1' : '0'});

      final response = await _dio.post(
        ApiConfig.partnerGoOnline,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Go online status updated successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to update online status',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Go Online Status
  Future<ApiResult<Map<String, dynamic>>> getGoOnlineStatus() async {
    try {
      print('📡 [UserService] Starting getGoOnlineStatus API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerGetGoOnline,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Go online status fetched successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch online status',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Data by Custom Date Range
  Future<ApiResult<Map<String, dynamic>>> getDataByCustomDate({
    required String startDate,
    required String endDate,
  }) async {
    try {
      print('📅 [UserService] Starting getDataByCustomDate API call');
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerGetDataByCustomDate,
        queryParameters: {'start_date': startDate, 'end_date': endDate},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Custom date data fetched successfully');
        return right(response.data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch custom date data',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Booking Transaction Daily
  Future<ApiResult<BookingTransactionDailyResponse>>
  getBookingTransactionDaily({required String date}) async {
    try {
      print('💰 [UserService] Starting getBookingTransactionDaily API call');
      print('📝 [UserService] Date: $date');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerBookingTransactionDaily,
        queryParameters: {'date': date},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Daily transaction data fetched successfully');
        final data = BookingTransactionDailyResponse.fromJson(response.data);
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch daily transaction data',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Booking Transaction Weekly
  Future<ApiResult<BookingTransactionWeeklyResponse>>
  getBookingTransactionWeekly({String? date}) async {
    try {
      print('💰 [UserService] Starting getBookingTransactionWeekly API call');
      print('📝 [UserService] Date: $date');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final Map<String, dynamic> queryParams =
          date != null && date.isNotEmpty ? {'date': date} : {};
      final response = await _dio.get(
        ApiConfig.partnerBookingTransactionWeekly,
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Weekly transaction data fetched successfully');
        final data = BookingTransactionWeeklyResponse.fromJson(response.data);
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch weekly transaction data',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Booking Transaction Monthly
  Future<ApiResult<BookingTransactionMonthlyResponse>>
  getBookingTransactionMonthly({
    required String month,
    required String year,
  }) async {
    try {
      print('💰 [UserService] Starting getBookingTransactionMonthly API call');
      print('📝 [UserService] Month: $month, Year: $year');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerBookingTransactionMonth,
        queryParameters: {'month': month, 'year': year},
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Monthly transaction data fetched successfully');
        final data = BookingTransactionMonthlyResponse.fromJson(response.data);
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch monthly transaction data',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Transaction History
  Future<ApiResult<TransactionHistoryResponse>> getTransactionHistory() async {
    try {
      print('💰 [UserService] Starting getTransactionHistory API call');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerTransactionHistory,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Transaction history fetched successfully');
        final data = TransactionHistoryResponse.fromJson(response.data);
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch transaction history',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Checkout Index (Bank Accounts and Rules)
  Future<ApiResult<CheckoutIndexResponse>> getCheckoutIndex() async {
    try {
      print('💰 [UserService] Starting getCheckoutIndex API call');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerCheckoutIndex,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Checkout index data fetched successfully');
        final data = CheckoutIndexResponse.fromJson(response.data);
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch checkout index',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Submit Withdrawal Request
  Future<ApiResult<Map<String, dynamic>>> submitWithdrawalRequest({
    required String accountNumber,
    required String withdrawAmountRequest,
  }) async {
    try {
      print('💰 [UserService] Starting submitWithdrawalRequest API call');
      print(
        '📝 [UserService] Account: $accountNumber, Amount: $withdrawAmountRequest',
      );

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'account_number': accountNumber,
        'withdraw_amount_request': withdrawAmountRequest,
      });

      final response = await _dio.post(
        ApiConfig.partnerCheckoutStore,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Withdrawal request submitted successfully');
        return right(response.data);
      } else {
        final message =
            response.data['message'] ?? 'Failed to submit withdrawal request';
        return left(ServerFailure(message, response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final message =
            e.response?.data['message'] ??
            'Failed to submit withdrawal request';
        return left(ServerFailure(message, e.response?.statusCode ?? 400));
      }
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get Notifications
  Future<ApiResult<NotificationResponse>> getNotifications() async {
    try {
      print('🔔 [UserService] Starting getNotifications API call');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.partnerNotifications,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Notifications fetched successfully');
        final data = NotificationResponse.fromJson(response.data);
        return right(data);
      } else {
        return left(
          ServerFailure(
            'Failed to fetch notifications',
            response.statusCode ?? 500,
          ),
        );
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Mark Notification as Read
  Future<ApiResult<Map<String, dynamic>>> markNotificationAsRead({
    required String notificationToken,
  }) async {
    try {
      print('🔔 [UserService] Starting markNotificationAsRead API call');
      print('📝 [UserService] Token: $notificationToken');

      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final formData = FormData.fromMap({
        'notification_token': notificationToken,
      });

      final response = await _dio.post(
        ApiConfig.partnerMarkNotificationAsRead,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Notification marked as read successfully');
        return right(response.data);
      } else {
        final message =
            response.data['message'] ?? 'Failed to mark notification as read';
        return left(ServerFailure(message, response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 422) {
        final message =
            e.response?.data['message'] ??
            'Failed to mark notification as read';
        return left(ServerFailure(message, e.response?.statusCode ?? 400));
      }
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  ApiFailure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerFailure('Request timeout', 408);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message =
            error.response?.data['message'] ??
            error.response?.statusMessage ??
            'Server error';

        if (statusCode == 401) {
          // Clear preferences on 401 (fire and forget)
          clearAllPreferences().catchError((e) {
            print(
              '❌ [UserService] Error clearing preferences in _handleDioError: $e',
            );
          });
          return const UnauthorizedFailure();
        }

        return ServerFailure(message, statusCode);

      case DioExceptionType.cancel:
        return const UnknownFailure('Request cancelled');

      case DioExceptionType.connectionError:
        return const NetworkFailure();

      default:
        return UnknownFailure(error.message ?? 'Unknown error');
    }
  }
}
