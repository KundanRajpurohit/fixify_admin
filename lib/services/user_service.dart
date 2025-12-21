import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/api_config.dart';
import '../dio/resulr.dart';
import '../models/booking_model.dart';

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
      print('🌐 [UserService] API endpoint: ${ApiConfig.defaultAddress}');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.defaultAddress}');
      
      final formData = FormData.fromMap({
        'address': address,
        'state': state,
        'city': city,
        'landmark': landmark,
        'pincode': pincode,
      });
      
      print('📤 [UserService] Sending request...');
      final response = await _dio.post(
        ApiConfig.defaultAddress,
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
          return left(ServerFailure(data['message'] ?? 'Failed to save address', 400));
        }
      } else {
        print('❌ [UserService] HTTP Error: ${response.statusCode}');
        print('❌ [UserService] Response: ${response.data}');
        return left(ServerFailure('Failed to save address', response.statusCode ?? 500));
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
  
  // Send OTP
  Future<ApiResult<Map<String, dynamic>>> sendOtp({
    required String mobile,
    required String userId,
  }) async {
    try {
      print('📱 [UserService] Starting sendOtp API call');
      print('📝 [UserService] Request data:');
      print('   - mobile: $mobile');
      print('   - userId: $userId');
      print('🌐 [UserService] API endpoint: ${ApiConfig.sendOtp}');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.sendOtp}');
      
      final formData = FormData.fromMap({
        'mobile': mobile,
        'userid': userId,
      });
      
      print('📤 [UserService] Sending OTP request...');
      final response = await _dio.post(
        ApiConfig.sendOtp,
        data: formData,
      );
      
      print('📥 [UserService] OTP Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] OTP sent successfully');
        print('📋 [UserService] Response message: ${data['message']}');
        print('🔢 [UserService] OTP: ${data['otp']}');
        return right(response.data);
      } else {
        print('❌ [UserService] OTP HTTP Error: ${response.statusCode}');
        print('❌ [UserService] OTP Response: ${response.data}');
        return left(ServerFailure('Failed to send OTP', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      print('❌ [UserService] OTP DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] OTP Unexpected error: $e');
      print('❌ [UserService] OTP Error type: ${e.runtimeType}');
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
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.verifyOtp}');
      
      final formData = FormData.fromMap({
        'mobile': mobile,
        'otp': otp,
      });
      
      print('📤 [UserService] Sending OTP verification request...');
      final response = await _dio.post(
        ApiConfig.verifyOtp,
        data: formData,
      );
      
      print('📥 [UserService] OTP Verification Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [UserService] OTP verification successful');
        print('📋 [UserService] Response message: ${data['message']}');
        
        if (data['message'] == 'Login successful') {
          print('🎉 [UserService] Login successful!');
          print('🔑 [UserService] Authorization token: ${data['token']}');
          
          // Save authorization token
          await _saveAuthToken(data['token']);
          print('💾 [UserService] Authorization token saved successfully');
          return right(data);
        } else {
          print('❌ [UserService] Login failed - message: ${data['message']}');
          return left(ServerFailure(data['message'] ?? 'OTP verification failed', 400));
        }
      } else {
        print('❌ [UserService] OTP Verification HTTP Error: ${response.statusCode}');
        print('❌ [UserService] OTP Verification Response: ${response.data}');
        return left(ServerFailure('Failed to verify OTP', response.statusCode ?? 500));
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
  
  // Get user profile
  Future<ApiResult<Map<String, dynamic>>> getUserProfile() async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      final response = await _dio.get(
        ApiConfig.userProfile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to get profile', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Update user profile
  Future<ApiResult<Map<String, dynamic>>> updateUserProfile({
    required String name,
    required String email,
    required String address,
    required String state,
    required String city,
    required String landmark,
    required String pincode,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      final formData = FormData.fromMap({
        'name': name,
        'email': email,
        'address': address,
        'state': state,
        'city': city,
        'landmark': landmark,
        'pincode': pincode,
      });
      
      final response = await _dio.post(
        ApiConfig.updateProfile,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to update profile', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Update user name only
  Future<ApiResult<Map<String, dynamic>>> updateUserName({
    required String name,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      print('👤 [UserService] Starting updateUserName API call');
      print('📝 [UserService] Request data:');
      print('   - name: $name');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.updateProfile}');
      
      final formData = FormData.fromMap({
        'name': name,
      });
      
      final response = await _dio.post(
        ApiConfig.updateProfile,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      print('📥 [UserService] Update Name Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to update name', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Upload profile image
  Future<ApiResult<Map<String, dynamic>>> uploadProfileImage({
    required File file,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiConfig.profileImageUpload,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure(
          'Failed to upload profile image',
          response.statusCode ?? 500,
        ));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Remove profile image
  Future<ApiResult<Map<String, dynamic>>> removeProfileImage() async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }

      final response = await _dio.get(
        ApiConfig.profileImageRemove,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure(
          'Failed to remove profile image',
          response.statusCode ?? 500,
        ));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  // Logout
  Future<ApiResult<Map<String, dynamic>>> logout() async {
    try {
      print('🚪 [UserService] Starting logout API call');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.logout}');
      
      // Get authorization token
      final authToken = await getAuthToken();
      if (authToken == null) {
        print('❌ [UserService] No authorization token found');
        // Clear all data even if no token (user might be in inconsistent state)
        await clearAllPreferences();
        return left(const UnauthorizedFailure());
      }
      
      print('🔑 [UserService] Using authorization token: ${authToken.substring(0, 10)}...');
      
      final response = await _dio.post(
        ApiConfig.logout,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Logout successful');
        print('📊 [UserService] Logout response: ${response.data}');
        // Clear all user data on successful logout
        await clearAllPreferences();
        return right(response.data);
      } else {
        print('❌ [UserService] Logout API failed, but clearing local data anyway');
        // Clear all data even if API fails (user wants to logout)
        await clearAllPreferences();
        return left(ServerFailure('Failed to logout', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      print('❌ [UserService] Logout API exception, but clearing local data anyway');
      // Clear all data even if API throws exception (user wants to logout)
      await clearAllPreferences();
      
      // If it's a 401 error (Unauthenticated), treat it as successful logout
      if (e.response?.statusCode == 401) {
        print('✅ [UserService] 401 error - treating as successful logout since user is already unauthenticated');
        return right({'status': true, 'message': 'Logged out successfully'});
      }
      
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Logout exception: $e');
      // Clear all data even if unexpected error (user wants to logout)
      await clearAllPreferences();
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Delete account
  Future<ApiResult<Map<String, dynamic>>> deleteAccount() async {
    try {
      final response = await _dio.post(ApiConfig.deleteAccount);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await clearUserData();
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to delete account', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Get page detail (Privacy Policy, Terms, etc.)
  Future<ApiResult<Map<String, dynamic>>> getPageDetail(String slug) async {
    try {
      print('📄 [UserService] Starting getPageDetail API call');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}/page-detail/$slug');
      print('📄 [UserService] Slug: $slug');
      
      final response = await _dio.get('/page-detail/$slug');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [UserService] Page detail retrieved successfully');
        print('📊 [UserService] Page detail response: ${response.data}');
        return right(response.data);
      } else {
        print('❌ [UserService] Page detail API failed');
        return left(ServerFailure('Failed to retrieve page detail', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      print('❌ [UserService] Page detail API exception: ${e.message}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] Page detail exception: $e');
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
        return left(ServerFailure('Failed to retrieve FAQs', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      print('❌ [UserService] FAQs API exception: ${e.message}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [UserService] FAQs exception: $e');
      return left(UnknownFailure(e.toString()));
    }
  }

  // Get all addresses
  Future<ApiResult<UserAddressResponse>> getAllAddresses() async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      print('📍 [UserService] Starting getAllAddresses API call');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.showAllAddress}');
      
      final headers = {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.showAllAddress}'),
        headers: headers,
      );
      
      print('📥 [UserService] Addresses Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('   - Response Data: $jsonData');
        
        if (jsonData['status'] == true) {
          final addressResponse = UserAddressResponse.fromJson(jsonData);
          return right(addressResponse);
        } else {
          return left(ServerFailure(jsonData['message'] ?? 'Failed to get addresses', 400));
        }
      } else {
        print('❌ [UserService] Get addresses failed with status: ${response.statusCode}');
        print('❌ [UserService] Response body: ${response.body}');
        return left(ServerFailure('Failed to get addresses', response.statusCode));
      }
    } catch (e) {
      print('❌ [UserService] Get addresses exception: $e');
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Add new address
  Future<ApiResult<Map<String, dynamic>>> addAddress({
    required String userId,
    required String address,
    required String state,
    required String city,
    required String landmark,
    required String pincode,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      print('➕ [UserService] Starting addAddress API call');
      print('📝 [UserService] Request data:');
      print('   - userId: $userId');
      print('   - address: $address');
      print('   - state: $state');
      print('   - city: $city');
      print('   - landmark: $landmark');
      print('   - pincode: $pincode');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.addAddress}');
      
      final formData = FormData.fromMap({
        'userid': userId,
        'address': address,
        'state': state,
        'city': city,
        'landmark': landmark,
        'pincode': pincode,
      });
      
      final response = await _dio.post(
        ApiConfig.addAddress,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      print('📥 [UserService] Add Address Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to add address', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Edit address
  Future<ApiResult<Map<String, dynamic>>> editAddress({
    required String token,
    required String address,
    required String state,
    required String city,
    required String landmark,
    required String pincode,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      print('✏️ [UserService] Starting editAddress API call');
      print('📝 [UserService] Request data:');
      print('   - token: $token');
      print('   - address: $address');
      print('   - state: $state');
      print('   - city: $city');
      print('   - landmark: $landmark');
      print('   - pincode: $pincode');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.editAddress}');
      
      final formData = FormData.fromMap({
        'token': token,
        'address': address,
        'state': state,
        'city': city,
        'landmark': landmark,
        'pincode': pincode,
      });
      
      final response = await _dio.post(
        ApiConfig.editAddress,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      print('📥 [UserService] Edit Address Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to edit address', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Update default address
  Future<ApiResult<Map<String, dynamic>>> updateDefaultAddress({
    required String token,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      print('⭐ [UserService] Starting updateDefaultAddress API call');
      print('📝 [UserService] Request data:');
      print('   - token: $token');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.updateDefaultAddress}');
      
      final formData = FormData.fromMap({
        'token': token,
      });
      
      final response = await _dio.post(
        ApiConfig.updateDefaultAddress,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      print('📥 [UserService] Update Default Address Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to update default address', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      return left(_handleDioError(e));
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
  
  // Delete address
  Future<ApiResult<Map<String, dynamic>>> deleteAddress({
    required String token,
  }) async {
    try {
      final authToken = await getAuthToken();
      if (authToken == null) {
        return left(const UnauthorizedFailure());
      }
      
      print('🗑️ [UserService] Starting deleteAddress API call');
      print('📝 [UserService] Request data:');
      print('   - token: $token');
      print('🔗 [UserService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.deleteAddress}');
      
      final formData = FormData.fromMap({
        'token': token,
      });
      
      final response = await _dio.post(
        ApiConfig.deleteAddress,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        ),
      );
      
      print('📥 [UserService] Delete Address Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return right(response.data);
      } else {
        return left(ServerFailure('Failed to delete address', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
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
        final message = error.response?.data['message'] ??
            error.response?.statusMessage ??
            'Server error';
            
        if (statusCode == 401) {
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
