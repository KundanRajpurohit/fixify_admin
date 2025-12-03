// import 'package:fixify/config/app_colors.dart';
// import 'package:fixify/models/service_model.dart';
// import 'package:fixify/providers/home_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class ServiceCard extends ConsumerWidget {
//   final Service service;
//   const ServiceCard({super.key, required this.service});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Service image
//           Expanded(
//             flex: 2,
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(12),
//                   topRight: Radius.circular(12),
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.all(Radius.circular(12)),
//                 child: Image.asset(
//                   service.imagePath,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//           ),

//           // Service details
//           Expanded(
//             flex: 1,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     service.name,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Text(
//                         '₹${service.price.toInt()}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const Spacer(),
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.star,
//                             size: 14,
//                             color: Colors.amber,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${service.rating} (${service.reviewCount} Reviews)',
//                             style: const TextStyle(
//                               fontSize: 11,
//                               color: Colors.grey,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 10),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 32,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         // Add to cart
//                         ref.read(cartItemsProvider.notifier).state = [
//                           ...ref.read(cartItemsProvider),
//                           service,
//                         ];
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text('${service.name} added to cart'),
//                             backgroundColor: const Color(0xFF217043),
//                           ),
//                         );
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.secondary.withOpacity(0.4),
//                         foregroundColor: const Color(0xFF2E7D32),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           side: const BorderSide(
//                               color: AppColors.secondary, width: 2      ),
//                         ),
//                         elevation: 0,
//                       ),
//                       child: const Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.shopping_cart, size: 16),
//                           SizedBox(width: 4),
//                           Text(
//                             'Add to Cart',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
