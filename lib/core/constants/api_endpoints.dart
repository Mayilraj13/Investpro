class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh';
  static const String biometricLogin = '/auth/biometric';

  // User
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/update';
  static const String kycStatus = '/user/kyc-status';

  // Stocks
  static const String stocks = '/stocks';
  static const String stockDetails = '/stocks/';
  static const String stockChart = '/stocks/chart/';
  static const String stockSearch = '/stocks/search';
  static const String marketDepth = '/stocks/market-depth/';
  static const String analystRatings = '/stocks/analyst-ratings/';

  // Market
  static const String marketOverview = '/market/overview';
  static const String topGainers = '/market/top-gainers';
  static const String topLosers = '/market/top-losers';
  static const String trendingStocks = '/market/trending';
  static const String marketNews = '/market/news';

  // Portfolio
  static const String portfolio = '/portfolio';
  static const String portfolioHoldings = '/portfolio/holdings';
  static const String transactionHistory = '/portfolio/transactions';
  static const String assetAllocation = '/portfolio/allocation';

  // Watchlist
  static const String watchlist = '/watchlist';
  static const String watchlistCreate = '/watchlist/create';
  static const String watchlistDelete = '/watchlist/';
  static const String watchlistAddStock = '/watchlist/add-stock';
  static const String watchlistRemoveStock = '/watchlist/remove-stock';
  static const String priceAlert = '/watchlist/price-alert';

  // Mutual Funds
  static const String mutualFunds = '/mutual-funds';
  static const String mutualFundDetails = '/mutual-funds/';
  static const String topFunds = '/mutual-funds/top';
  static const String sipCalculator = '/mutual-funds/sip-calculator';

  // Wallet
  static const String wallet = '/wallet';
  static const String addMoney = '/wallet/add';
  static const String withdrawMoney = '/wallet/withdraw';
  static const String bankAccounts = '/wallet/bank-accounts';
  static const String transactionHistoryWallet = '/wallet/transactions';

  // Notifications
  static const String notifications = '/notifications';
  static const String registerFcm = '/notifications/fcm-token';
}
