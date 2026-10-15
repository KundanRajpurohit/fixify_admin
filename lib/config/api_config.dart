// API Configuration
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String baseUrl = kDebugMode ? testurl : liveurl;
  static const String liveurl = 'https://admin.fixify.expert/api';
  static const String testurl = 'https://admin.fixify.expert/api';

  // Partner endpoints
  static const String partnerLogin = '/partner/login';
  static const String partnerRegister = '/partner/register';
  static const String partnerRefreshToken = '/partner/refresh-token';
  static const String partnerProfile = '/partner/profile';
  static const String partnerUpdateProfile = '/partner/update-profile';
  static const String partnerUploadImage = '/partner/upload-image';
  static const String partnerLogout = '/partner/logout';
  static const String partnerUpdateNotification =
      '/partner/update-notification';
  static const String partnerAddDefaultAddress = '/partner/add-default-address';
  static const String partnerUploadDocuments = '/partner/v4/upload-documents';
  static const String partnerUpdateLocation = '/partner/v4/update-location';
  static const String partnerSendOtp = '/partner/send-otp';
  static const String partnerVerifyOtp = '/partner/verify-otp';
  static const String verifyOtp = '/partner/verify-otp';
  static const String partnerPageDetail = '/partner/page-detail';
  static const String partnerAddAdditionalItem = '/partner/add-additional-item';

  // Bank Account endpoints
  static const String partnerBankAll = '/partner/bank/all';
  static const String partnerBankStore = '/partner/bank/store';
  static const String partnerBankUpdate = '/partner/bank/update';
  static const String partnerBankDelete = '/partner/bank/delete';

  //Jobs endpoints
  static const String partnerAllJobs = '/partner/v4/all-jobs';
  static const String partnerUpcomingJobs = '/partner/v4/upcoming-jobs';
  static const String partnerCancelledJobs = '/partner/v4/cancelled-jobs';
  static const String partnerOngoingJobs = '/partner/v4/all-ongoing-jobs';
  static const String partnerPastJobs = '/partner/v4/all-completed-jobs';
  static const String partnerAssignUpcomingJobs = '/partner/v4/all-assign-jobs';
  static const String partnerAcceptJob = '/partner/accept-job';
  static const String partnerAssignJob = '/partner/assign-job';
  static const String partnerVerifyJobOtp = '/partner/verify-job-otp';
  static const String partnerJobCompleted = '/partner/job-completed';
  static const String partnerSubmitJobReport = '/partner/submit-job-report';
  static const String partnerPostPaymentQrCode =
      '/partner/v4/post-payment/qr-code';
  static const String partnerPostPaymentQrStatus =
      '/partner/v4/post-payment/qr-status';
  static const String partnerPostPaymentCash = '/partner/v4/post-payment/cash';
  static const String partnerRatingCustomer = '/partner/rating-customer';
  static const String call = '/call';

  static String partnerJobDetails(String token) =>
      '/partner/v4/single-job/$token';

  // Availability endpoints
  static const String partnerGetAvailability = '/partner/get-availability';
  static const String partnerAvailabilityMon = '/partner/availability/mon';
  static const String partnerAvailabilityTue = '/partner/availability/tue';
  static const String partnerAvailabilityWed = '/partner/availability/wed';
  static const String partnerAvailabilityThu = '/partner/availability/thu';
  static const String partnerAvailabilityFri = '/partner/availability/fri';
  static const String partnerAvailabilitySat = '/partner/availability/sat';
  static const String partnerAvailabilitySun = '/partner/availability/sun';

  // Dashboard endpoints
  static const String partnerDashboard = '/partner/deshbord';
  static const String partnerGoOnline = '/partner/go-online';
  static const String partnerGetGoOnline = '/partner/get-go-online';
  static const String partnerGetDataByCustomDate =
      '/partner/get-data-by-custom-date';
  static const String partnerVendorList = '/partner/vendor-list';

  // Earnings and Transaction endpoints
  static const String partnerBookingTransactionDaily =
      '/partner/booking-transaction-daily';
  static const String partnerBookingTransactionWeekly =
      '/partner/booking-transaction-weekly';
  static const String partnerBookingTransactionMonth =
      '/partner/booking-transaction-month';
  static const String partnerTransactionHistory =
      '/partner/transaction-history';

  // Withdrawal endpoints
  static const String partnerCheckoutIndex = '/partner/checkout-index';
  static const String partnerCheckoutStore = '/partner/checkout-store';

  // Notification endpoints
  static const String partnerNotifications = '/partner/notifications';
  static const String partnerMarkNotificationAsRead =
      '/partner/notifications/mark-as-read';

  // Mobile update endpoints
  static const String partnerUpdateMobile = '/partner/update-mobile';
  static const String partnerMobileOtpVerify = '/partner/mobile-otp-verify';

  // Services endpoints
  static const String partnerListServices = '/partner/list-services';

  // Google Places API
  static const String googlePlacesApiKey =
      'AIzaSyBbcUzWiQgeXfzUrFgbOMyOzCLU1nbaJBE';
}
