// import 'package:fixify/config/app_colors.dart';
// import 'package:fixify/models/product_model.dart';
// import 'package:fixify/providers/cart_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:page_transition/page_transition.dart';
// import '../screens/product_details_screen.dart';

// class ProductServiceCard extends ConsumerWidget {
//   final ProductModel product;
//   const ProductServiceCard({super.key, required this.product});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final cartState = ref.watch(cartProvider);
//     final isInCart = cartState.isInCart(product.token);
//     final quantity = cartState.getQuantity(product.token);
//     final isProductLoading = cartState.isProductLoading(product.token);

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Product image
//           Expanded(
//             flex: 2,
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   PageTransition(
//                     type: PageTransitionType.rightToLeft,
//                     duration: const Duration(milliseconds: 300),
//                     child: ProductDetailsScreen(
//                       productId: product.id,
//                       productTitle: product.title,
//                     ),
//                   ),
//                 );
//               },
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     topRight: Radius.circular(12),
//                   ),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.all(Radius.circular(12)),
//                   child: Image.network(
//                     product.image,
//                     fit: BoxFit.fill,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         color: Colors.grey.shade200,
//                         child: const Icon(
//                           Icons.image,
//                           size: 40,
//                           color: Colors.grey,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Product details
//           Expanded(
//             flex: 1,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product.title,
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
//                         '₹${product.price}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const Spacer(),
//                       Row(
//                         children: [
//                           ...List.generate(5, (index) {
//                             return Icon(
//                               Icons.star,
//                               size: 12,
//                               color: index <
//                                       double.parse(product.starRating).floor()
//                                   ? Colors.amber
//                                   : Colors.grey.shade300,
//                             );
//                           }),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${product.starRating} (${product.review})',
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
//                   _buildCartButton(
//                     context,
//                     ref,
//                     isInCart,
//                     quantity,
//                     isProductLoading,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCartButton(BuildContext context, WidgetRef ref, bool isInCart,
//       int quantity, bool isLoading) {
//     if (!isInCart) {
//       // Add to Cart Button
//       return GestureDetector(
//         onTap: isLoading
//             ? null
//             : () async {
//                 await _addToCart(context, ref);
//               },
//         child: Container(
//           width: double.infinity,
//           height: 32,
//           decoration: BoxDecoration(
//             color: isLoading ? Colors.grey.shade300 : const Color(0xFFF2FBF6),
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(
//               color: AppColors.borderColor,
//               width: 2,
//             ),
//           ),
//           child: isLoading
//               ? const Center(
//                   child: SizedBox(
//                     width: 12,
//                     height: 12,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Colors.white,
//                     ),
//                   ),
//                 )
//               : Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset(
//                       'assets/images/shopping-cart 1.png',
//                       width: 16,
//                       height: 16,
//                     ),
//                     const SizedBox(width: 4),
//                     const Text(
//                       'Add to Cart',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF2E7D32),
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       );
//     } else {
//       // Quantity Counter
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//         decoration: BoxDecoration(
//           color: const Color(0xFFF2FBF6), // light green background
//           borderRadius: BorderRadius.circular(40),
//           border: Border.all(
//             color: const Color(0xFFCCEAD8), // subtle green border
//             width: 1.2,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.max,
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // ------------------- MINUS BUTTON -------------------
//             GestureDetector(
//               onTap: isLoading
//                   ? null
//                   : () async {
//                       if (quantity > 1) {
//                         final success = await ref
//                             .read(cartProvider.notifier)
//                             .decreaseQuantity(product.token);
//                         if (!success && context.mounted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Failed to update quantity'),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       } else {
//                         _showRemoveConfirmation(
//                           context,
//                           ref,
//                         );
//                       }
//                     },
//               child: Container(
//                 width: 20,
//                 height: 20,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFE46A2F), // orange circle
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Center(
//                   child: Icon(Icons.remove, color: Colors.white, size: 20),
//                 ),
//               ),
//             ),

//             const SizedBox(width: 16),

//             // ------------------- CENTER TEXT -------------------
//             isLoading
//                 ? const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: Color(0xFF225F3D),
//                     ),
//                   )
//                 : Text(
//                     quantity.toString().padLeft(2, '0'),
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF225F3D), // dark green text
//                     ),
//                   ),

//             const SizedBox(width: 16),

//             // ------------------- PLUS BUTTON -------------------
//             GestureDetector(
//               onTap: isLoading
//                   ? null
//                   : () async {
//                       await ref
//                           .read(cartProvider.notifier)
//                           .increaseQuantity(product.token);
//                     },
//               child: Container(
//                 width: 20,
//                 height: 20,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF225F3D), // green circle
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Center(
//                   child: Icon(Icons.add, color: Colors.white, size: 20),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
//     final success = await ref.read(cartProvider.notifier).addToCart(
//           product: product,
//           quantity: 1,
//           type: 'product',
//         );

//     if (!success && context.mounted) {
//       final cartState = ref.read(cartProvider);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(cartState.error ?? 'Failed to add to cart'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }

//   void _showRemoveConfirmation(BuildContext context, WidgetRef ref) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Remove Item'),
//         content: Text('Remove ${product.title} from cart?'),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);

//               final success = await ref
//                   .read(cartProvider.notifier)
//                   .removeItem(product.token);

//               if (success && context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('${product.title} removed from cart'),
//                     backgroundColor: Colors.red,
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
//               }
//             },
//             child: const Text(
//               'Remove',
//               style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
