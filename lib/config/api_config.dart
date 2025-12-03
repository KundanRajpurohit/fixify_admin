// API Configuration
class ApiConfig {
  static const String baseUrl = 'https://admin.fixify.expert/api';
  
  // User endpoints
  static const String defaultAddress = '/user/default-address';
  static const String sendOtp = '/user/send-otp';
  static const String verifyOtp = '/user/verify-otp';
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile/update';
  static const String profileImageUpload = '/user/profile-image/upload';
  static const String profileImageRemove = '/user/profile-image/remove';
  static const String logout = '/user/logout';
  static const String deleteAccount = '/user/delete-account';
  
  // Address management endpoints
  static const String showAllAddress = '/user/show-all-address';
  static const String addAddress = '/user/add-address';
  static const String editAddress = '/user/edit-address';
  static const String updateDefaultAddress = '/user/update-default-address';
  static const String deleteAddress = '/user/delete-address';
  
  // Categories endpoints
  static const String categories = '/categories';
  static const String productsByCategoryId = '/products-by-category-id';
  static const String productsBySubCategoryId = '/products-by-sub-category-id';
  static const String productDetailsById = '/product-details-by-id';
  static const String topServices = '/top-services';


  // Notifications endpoints
  static const String getNotification = '/get-notification';
  static const String markNotificationRead = '/notifications/read';

  //cart endpoints
  static const String addToCart = '/add-to-cart';
  static const String showCart = '/get-cart-data';
  
  // Subscription endpoints
  static const String subscriptionAll = '/subscription/all';
  static const String subscriptionActivePlan = '/subscription-active-plan';
  static const String subscriptionOrderId = '/subscription/order-id';
  static const String subscriptionTransactionStore = '/subscription/transaction-store';
  static const String subscriptionTransactionFailed = '/subscription/transaction-failed';
  
  // Search endpoints
  static const String search = '/search';
  static const String storeSearch = '/store-search';
  static const String getSearch = '/get-search';

  // Offers
  static const String latestOfferBanner = '/get-latest-offer-banner';
  
  // Booking endpoints
  static const String bookingCheckout = '/booking/checkout';
  static const String bookingOrderId = '/booking/order-id';
  static const String bookingTransactionStore = '/booking/transaction-store';
  static const String bookingTransactionFailed = '/booking/transaction-failed';
  static const String bookingCancel = '/booking/cancel';
  static const String bookingAll = '/booking/all';
  static const String bookingReschedule = '/booking/reschedule';
  
  // Coupon endpoints
  static const String getAllCoupons = '/get-all-coupons';
  
  // Google Places API
  static const String googlePlacesApiKey = 'AIzaSyBbcUzWiQgeXfzUrFgbOMyOzCLU1nbaJBE';
}
