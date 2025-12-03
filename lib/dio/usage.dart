// // api_provider.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'api_provider.g.dart';

// @riverpod
// TokenManager tokenManager(TokenManagerRef ref) => TokenManager();

// @riverpod
// ApiHandler apiHandler(ApiHandlerRef ref) {
//   return ApiHandler(
//     baseUrl: 'https://api.example.com',
//     tokenManager: ref.watch(tokenManagerProvider),
//     onSessionExpired: () {
//       // Navigate to login or show dialog
//       ref.invalidateSelf();
//     },
//   );
// }

// // Repository example
// @riverpod
// class UserRepository extends _$UserRepository {
//   @override
//   FutureOr<void> build() {}

//   Future<ApiResult<User>> getUser(int id) async {
//     final api = ref.read(apiHandlerProvider);
//     return api.get<User>(
//       endpoint: '/users/$id',
//       parser: (json) => User.fromJson(json),
//     );
//   }

//   Future<ApiResult<User>> updateUser(int id, Map<String, dynamic> data) async {
//     final api = ref.read(apiHandlerProvider);
//     return api.put<User>(
//       endpoint: '/users/$id',
//       data: data,
//       parser: (json) => User.fromJson(json),
//     );
//   }
// }


// // Example usage in a Flutter widget
// user_screen.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class UserScreen extends ConsumerWidget {
//   const UserScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('User Profile')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             final repo = ref.read(userRepositoryProvider.notifier);
//             final result = await repo.getUser(1);

//             // Pattern matching with Either
//             result.fold(
//               (failure) {
//                 // Handle error
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text(failure.message)),
//                 );
//               },
//               (user) {
//                 // Handle success
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Welcome ${user.name}')),
//                 );
//               },
//             );
//           },
//           child: const Text('Load User'),
//         ),
//       ),
//     );
//   }
// }

// // Alternative: Switch expression pattern matching
// void handleResult(ApiResult<User> result) {
//   switch (result) {
//     case Left(value: final failure):
//       print('Error: ${failure.message}');
//       if (failure is UnauthorizedFailure) {
//         // Navigate to login
//       }
//     case Right(value: final user):
//       print('Success: ${user.name}');
//   }
// }



// user_notifier.dart
// @riverpod
// class UserNotifier extends _$UserNotifier {
//   @override
//   FutureOr<User?> build() => null;

//   Future<void> loadUser(int id) async {
//     state = const AsyncLoading();
    
//     final repo = ref.read(userRepositoryProvider.notifier);
//     final result = await repo.getUser(id);

//     state = result.fold(
//       (failure) => AsyncError(failure, StackTrace.current),
//       (user) => AsyncData(user),
//     );
//   }
// }

// In UI
// class UserWidget extends ConsumerWidget {
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userState = ref.watch(userNotifierProvider);

//     return userState.when(
//       data: (user) => user != null 
//           ? Text(user.name)
//           : const Text('No user'),
//       loading: () => const CircularProgressIndicator(),
//       error: (error, _) => Text('Error: ${(error as ApiFailure).message}'),
//     );
//   }
// }
