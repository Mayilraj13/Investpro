import 'package:flutter/painting.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'InvestPro';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'https://api.investpro.app/v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String onboardingKey = 'onboarding_complete';
  static const String watchlistKey = 'watchlist_data';
  static const String portfolioKey = 'portfolio_data';

  // Pagination
  static const int pageSize = 20;
  static const int searchDebounceMs = 300;

  // Animation
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration fastAnimation = Duration(milliseconds: 150);

  // Formatting
  static const String currencySymbol = '\u20B9';
  static const String percentageSymbol = '%';

  // Colors
  static const Color profitColor = Color(0xFF00C853);
  static const Color lossColor = Color(0xFFFF1744);
  static const Color neutralColor = Color(0xFF9E9E9E);
}
