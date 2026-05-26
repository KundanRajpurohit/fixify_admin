class CheckoutData {
  final String subscriptionType;
  final double conveyance;
  final double subtotal;
  final double totalAmount;
  final int totalItems;
  final List<CheckoutItem> checkoutItems;

  CheckoutData({
    required this.subscriptionType,
    required this.conveyance,
    required this.subtotal,
    required this.totalAmount,
    required this.totalItems,
    required this.checkoutItems,
  });

  factory CheckoutData.fromJson(Map<String, dynamic> json) {
    final items =
        (json['checkout_items'] as List<dynamic>?)
            ?.map((item) => CheckoutItem.fromJson(item))
            .toList() ??
        [];

    return CheckoutData(
      subscriptionType: json['subscriptionType'] ?? '',
      conveyance: (json['conveyance'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      totalItems: json['total_items'] ?? 0,
      checkoutItems: items,
    );
  }
}

class CheckoutItem {
  final int cartId;
  final String cartToken;
  final String productToken;
  final String type;
  final String title;
  final double price;
  final int quantity;
  final double subtotal;
  final String images;

  CheckoutItem({
    required this.cartId,
    required this.cartToken,
    required this.productToken,
    required this.type,
    required this.title,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.images,
  });

  factory CheckoutItem.fromJson(Map<String, dynamic> json) {
    return CheckoutItem(
      cartId: json['cart_id'] ?? 0,
      cartToken: json['cart_token'] ?? '',
      productToken: json['product_token'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      images: json['images'] ?? '',
    );
  }
}

class BookingOrderResponse {
  final String bookingId;
  final String orderId;
  final double totalAmount;
  final List<BookingCartItem> cartItems;

  BookingOrderResponse({
    required this.bookingId,
    required this.orderId,
    required this.totalAmount,
    required this.cartItems,
  });

  factory BookingOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final cartItems =
        (data['cart_items'] as List<dynamic>?)
            ?.map((item) => BookingCartItem.fromJson(item))
            .toList() ??
        [];

    return BookingOrderResponse(
      bookingId: data['bookingid'] ?? '',
      orderId: data['order_id'] ?? '',
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
      cartItems: cartItems,
    );
  }
}

class BookingCartItem {
  final String productToken;
  final String? productName;
  final String price;
  final int quantity;
  final double subtotal;
  final String token;

  BookingCartItem({
    required this.productToken,
    this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.token,
  });

  factory BookingCartItem.fromJson(Map<String, dynamic> json) {
    return BookingCartItem(
      productToken: json['product_token'] ?? '',
      productName: json['product_name'],
      price: json['price'] ?? '',
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      token: json['token'] ?? '',
    );
  }
}

class TransactionResponse {
  final String orderId;
  final String bookingId;
  final String price;
  final String transactionId;
  final String transactionStatus;
  final String paymentStatus;
  final String paymentMode;
  final String bookingStatus;
  final String assignedProfessional;
  final String contact;
  final double amount;

  TransactionResponse({
    required this.orderId,
    required this.bookingId,
    required this.price,
    required this.transactionId,
    required this.transactionStatus,
    required this.paymentStatus,
    required this.paymentMode,
    required this.bookingStatus,
    required this.assignedProfessional,
    required this.contact,
    required this.amount,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return TransactionResponse(
      orderId: data['order_id'] ?? '',
      bookingId: data['bookingid'] ?? '',
      price: data['price'] ?? '',
      transactionId: data['transaction_id'] ?? '',
      transactionStatus: data['transaction_status'] ?? '',
      paymentStatus: data['payment_status'] ?? '',
      paymentMode: data['payment_mode'] ?? '',
      bookingStatus: data['booking_status'] ?? '',
      assignedProfessional: data['assigned_professinoal'] ?? '',
      contact: data['contact'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
    );
  }
}

class UserAddress {
  final String address;
  final String city;
  final String state;
  final String landmark;
  final String pincode;
  final String token;
  final String status;
  final String createdAt;

  UserAddress({
    required this.address,
    required this.city,
    required this.state,
    required this.landmark,
    required this.pincode,
    required this.token,
    required this.status,
    required this.createdAt,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      landmark: json['landmark'] ?? '',
      pincode: json['pincode'] ?? '',
      token: json['token'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  String get fullAddress => '$address, $city, $state - $pincode';
}

class UserAddressResponse {
  final String userId;
  final String name;
  final String mobile;
  final String email;
  final UserAddress? defaultAddress;
  final List<UserAddress> addresses;

  UserAddressResponse({
    required this.userId,
    required this.name,
    required this.mobile,
    required this.email,
    this.defaultAddress,
    required this.addresses,
  });

  factory UserAddressResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final defaultAddr = json['defaultAddress'];
    final addressesList =
        (json['addresses'] as List<dynamic>?)
            ?.map((addr) => UserAddress.fromJson(addr))
            .toList() ??
        [];

    return UserAddressResponse(
      userId: user['userid'] ?? '',
      name: user['name'] ?? '',
      mobile: user['mobile'] ?? '',
      email: user['email'] ?? '',
      defaultAddress:
          defaultAddr != null ? UserAddress.fromJson(defaultAddr) : null,
      addresses: addressesList,
    );
  }
}

// Booking List Models
class BookingListResponse {
  final bool status;
  final String message;
  final int totalBookings;
  final List<BookingItem> bookings;

  BookingListResponse({
    required this.status,
    required this.message,
    required this.totalBookings,
    required this.bookings,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    final bookingsList = json['data'] as List?;
    List<BookingItem> parsedBookings =
        bookingsList != null
            ? bookingsList.map((i) => BookingItem.fromJson(i)).toList()
            : [];

    return BookingListResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      totalBookings: json['total_bookings'] ?? 0,
      bookings: parsedBookings,
    );
  }
}

class BookingItem {
  final String bookingId;
  final String orderId;
  final double price;
  final double conveyance;
  final String bookingStatus; // past, ongoing, upcoming
  final String paymentStatus;
  final String transactionStatus;
  final String scheduleType;
  final String scheduledTime;
  final String createdAt;
  final List<BookingDetail> bookingDetails;

  BookingItem({
    required this.bookingId,
    required this.orderId,
    required this.price,
    required this.conveyance,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.transactionStatus,
    required this.scheduleType,
    required this.scheduledTime,
    required this.createdAt,
    required this.bookingDetails,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final detailsList = json['booking_details'] as List?;
    List<BookingDetail> parsedDetails =
        detailsList != null
            ? detailsList.map((i) => BookingDetail.fromJson(i)).toList()
            : [];

    return BookingItem(
      bookingId: json['booking_id'] ?? '',
      orderId: json['order_id'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      conveyance: (json['conveyance'] as num?)?.toDouble() ?? 0.0,
      bookingStatus: json['booking_status'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      scheduleType: json['schedule_type'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '',
      createdAt: json['created_at'] ?? '',
      bookingDetails: parsedDetails,
    );
  }
}

class BookingDetail {
  final String productId;
  final String productName;
  final String productImage;
  final String quantity;

  BookingDetail({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
  });

  factory BookingDetail.fromJson(Map<String, dynamic> json) {
    return BookingDetail(
      productId: json['productid'] ?? '',
      productName: json['product_name'] ?? '',
      productImage: json['product_image'] ?? '',
      quantity: json['quantity'] ?? '1',
    );
  }
}
