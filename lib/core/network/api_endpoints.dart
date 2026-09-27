class ApiEndpoints {
  static const String auth = '/auth';
  static const String authSendOtp = '/auth/send-otp';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authLoginEmail = '/auth/login-email';
  static const String authChangePassword = '/auth/change-password';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String vendorsMe = '/vendors/me';

  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';

  static const String transactions = '/transactions';

  static const String withdrawals = '/withdrawals';
  static const String withdrawalsPreview = '/withdrawals/preview';
}
