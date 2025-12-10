// API Configuration
class ApiConfig {
  static const String baseUrl = 'https://admin.fixify.expert/api';

  // Partner endpoints
  static const String partnerLogin = '/partner/login';
  static const String partnerRegister = '/partner/register';
  static const String partnerProfile = '/partner/profile';
  static const String partnerUpdateProfile = '/partner/update-profile';
  static const String partnerUploadImage = '/partner/upload-image';
  static const String partnerLogout = '/partner/logout';
  static const String partnerUpdateNotification = '/partner/update-notification';
  static const String partnerAddDefaultAddress = '/partner/add-default-address';
  static const String partnerUploadDocuments = '/partner/upload-documents';
  static const String partnerSendOtp = '/partner/send-otp';
  static const String partnerVerifyOtp = '/partner/verify-otp';
  static const String verifyOtp = '/partner/verify-otp';
  static const String partnerPageDetail = '/partner/page-detail';
  
  // Bank Account endpoints
  static const String partnerBankAll = '/partner/bank/all';
  static const String partnerBankStore = '/partner/bank/store';
  static const String partnerBankUpdate = '/partner/bank/update';
  static const String partnerBankDelete = '/partner/bank/delete';
  
  // Availability endpoints
  static const String partnerGetAvailability = '/partner/get-availability';
  static const String partnerAvailabilityMon = '/partner/availability/mon';
  static const String partnerAvailabilityTue = '/partner/availability/tue';
  static const String partnerAvailabilityWed = '/partner/availability/wed';
  static const String partnerAvailabilityThu = '/partner/availability/thu';
  static const String partnerAvailabilityFri = '/partner/availability/fri';
  static const String partnerAvailabilitySat = '/partner/availability/sat';
  static const String partnerAvailabilitySun = '/partner/availability/sun';

  // Google Places API
  static const String googlePlacesApiKey = 'AIzaSyBbcUzWiQgeXfzUrFgbOMyOzCLU1nbaJBE';
}
