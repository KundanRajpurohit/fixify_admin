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
  static const String partnerUpdateNotification =
      '/partner/update-notification';
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

  //Jobs endpoints
  static const String partnerAllJobs = '/partner/all-jobs';
  static const String partnerUpcomingJobs = '/partner/upcoming-jobs';
  static const String partnerCancelledJobs = '/partner/cancelled-jobs';
  static const String partnerOngoingJobs = '/partner/ongoing-jobs';
  static const String partnerPastJobs = '/partner/past-jobs';
  static const String partnerAssignUpcomingJobs = '/partner/assign-upcoming-jobs';
  static const String partnerAcceptJob = '/partner/accept-job';
  static const String partnerAssignJob = '/partner/assign-job';
  static const String partnerVerifyJobOtp = '/partner/verify-job-otp';
  static const String partnerJobCompleted = '/partner/job-completed';
  static const String partnerSubmitJobReport = '/partner/submit-job-report';
  static const String partnerRatingCustomer = '/partner/rating-customer';
  static String partnerJobDetails(String token) =>
    '/partner/single-job-details/$token';



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
  static const String partnerGetDataByCustomDate = '/partner/get-data-by-custom-date';
  static const String partnerVendorList = '/partner/vendor-list';

  // Earnings and Transaction endpoints
  static const String partnerBookingTransactionDaily = '/partner/booking-transaction-daily';
  static const String partnerBookingTransactionWeekly = '/partner/booking-transaction-weekly';
  static const String partnerBookingTransactionMonth = '/partner/booking-transaction-month';
  static const String partnerTransactionHistory = '/partner/transaction-history';

  // Withdrawal endpoints
  static const String partnerCheckoutIndex = '/partner/checkout-index';
  static const String partnerCheckoutStore = '/partner/checkout-store';

  // Notification endpoints
  static const String partnerNotifications = '/partner/notifications';
  static const String partnerMarkNotificationAsRead = '/partner/notifications/mark-as-read';

  // Mobile update endpoints
  static const String partnerUpdateMobile = '/partner/update-mobile';
  static const String partnerMobileOtpVerify = '/partner/mobile-otp-verify';



  // Google Places API
  static const String googlePlacesApiKey =
      'AIzaSyBbcUzWiQgeXfzUrFgbOMyOzCLU1nbaJBE';
}