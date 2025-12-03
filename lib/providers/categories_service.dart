import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../config/api_config.dart';
import '../dio/resulr.dart';

// Category model
class CategoryModel {
  final int id;
  final String title;
  final String image;
  final String token;

  CategoryModel({
    required this.id,
    required this.title,
    required this.image,
    required this.token,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'token': token,
    };
  }
}

// Categories service
class CategoriesService {
  final Dio _dio;

  CategoriesService(this._dio);

  // Get all categories
  Future<ApiResult<List<CategoryModel>>> getCategories() async {
    try {
      print('📋 [CategoriesService] Starting getCategories API call');
      print(
          '🔗 [CategoriesService] Full URL: ${ApiConfig.baseUrl}${ApiConfig.categories}');

      final response = await _dio.get(ApiConfig.categories);

      print('📥 [CategoriesService] Categories Response received:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        print('✅ [CategoriesService] Response status: ${data['status']}');
        print('📋 [CategoriesService] Response message: ${data['message']}');

        if (data['status'] == 200) {
          print('📋 [CategoriesService] Parsing categories data...');
          final categoriesList = data['categories'] as List;
          final categories = categoriesList
              .map((category) => CategoryModel.fromJson(category))
              .toList();

          print('✅ [CategoriesService] Parsed ${categories.length} categories');
          return right(categories);
        } else {
          print('❌ [CategoriesService] API returned status: ${data['status']}');
          print('❌ [CategoriesService] Error message: ${data['message']}');
          return left(ServerFailure(
              data['message'] ?? 'Failed to fetch categories', 400));
        }
      } else {
        print('❌ [CategoriesService] HTTP Error: ${response.statusCode}');
        print('❌ [CategoriesService] Response: ${response.data}');
        return left(ServerFailure(
            'Failed to fetch categories', response.statusCode ?? 500));
      }
    } on DioException catch (e) {
      print('❌ [CategoriesService] DioException occurred:');
      print('   - Type: ${e.type}');
      print('   - Message: ${e.message}');
      print('   - Response: ${e.response?.data}');
      print('   - Status Code: ${e.response?.statusCode}');
      return left(_handleDioError(e));
    } catch (e) {
      print('❌ [CategoriesService] Unexpected error: $e');
      print('❌ [CategoriesService] Error type: ${e.runtimeType}');
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

// Provider for Dio
final dioProvider = Provider<Dio>((ref) {
  // This will be injected from the main app
  throw UnimplementedError('Dio must be provided');
});

// Provider for CategoriesService
final categoriesServiceProvider = Provider<CategoriesService>((ref) {
  final dio = ref.watch(dioProvider);
  return CategoriesService(dio);
});
