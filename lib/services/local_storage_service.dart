import 'package:hive_flutter/hive_flutter.dart';
import '../data/models/user_model.dart';
import '../data/models/stock_model.dart';
import '../data/models/portfolio_model.dart';
import '../data/models/watchlist_model.dart';
import '../core/constants/app_constants.dart';

class LocalStorageService {
  static late Box _settingsBox;
  static late Box _userBox;
  static late Box _stocksBox;
  static late Box _portfolioBox;
  static late Box _watchlistBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox('settings');
    _userBox = await Hive.openBox('user');
    _stocksBox = await Hive.openBox('stocks');
    _portfolioBox = await Hive.openBox('portfolio');
    _watchlistBox = await Hive.openBox('watchlist');
  }

  // Settings
  static bool get isDarkMode => _settingsBox.get(AppConstants.themeKey, defaultValue: false);
  static set isDarkMode(bool value) => _settingsBox.put(AppConstants.themeKey, value);

  static bool get isOnboardingComplete =>
      _settingsBox.get(AppConstants.onboardingKey, defaultValue: false);
  static set isOnboardingComplete(bool value) =>
      _settingsBox.put(AppConstants.onboardingKey, value);

  // User
  static Future<void> saveUser(UserModel user) async {
    await _userBox.put('current_user', user.toJson());
  }

  static UserModel? getSavedUser() {
    final data = _userBox.get('current_user');
    if (data != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  static Future<void> clearUser() async {
    await _userBox.clear();
  }

  // Stocks Cache
  static Future<void> cacheStocks(List<StockModel> stocks) async {
    await _stocksBox.put('all_stocks',
        stocks.map((s) => s.toJson()).toList());
  }

  static List<StockModel>? getCachedStocks() {
    final data = _stocksBox.get('all_stocks');
    if (data != null) {
      return (data as List).map((e) => StockModel.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return null;
  }

  static Future<void> cacheStockDetail(String symbol, StockModel stock) async {
    await _stocksBox.put('stock_$symbol', stock.toJson());
  }

  static StockModel? getCachedStockDetail(String symbol) {
    final data = _stocksBox.get('stock_$symbol');
    if (data != null) {
      return StockModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  // Portfolio
  static Future<void> savePortfolio(PortfolioModel portfolio) async {
    await _portfolioBox.put('portfolio', {
      'total_investment': portfolio.totalInvestment,
      'current_value': portfolio.currentValue,
      'total_returns': portfolio.totalReturns,
      'returns_percentage': portfolio.returnsPercentage,
    });
  }

  // Watchlist
  static Future<void> saveWatchlist(WatchlistModel watchlist) async {
    await _watchlistBox.put('watchlist', {
      'id': watchlist.id,
      'name': watchlist.name,
      'stocks': watchlist.stocks.map((s) => {
        'symbol': s.symbol,
        'company_name': s.companyName,
        'current_price': s.currentPrice,
        'change': s.change,
        'change_percent': s.changePercent,
      }).toList(),
    });
  }

  static WatchlistModel? getSavedWatchlist() {
    final data = _watchlistBox.get('watchlist');
    if (data != null) {
      return WatchlistModel(
        id: data['id'] ?? '',
        name: data['name'] ?? 'Default',
        stocks: (data['stocks'] as List?)?.map((e) =>
            WatchlistStock(
              symbol: e['symbol'] ?? '',
              companyName: e['company_name'] ?? '',
              currentPrice: (e['current_price'] ?? 0).toDouble(),
              change: (e['change'] ?? 0).toDouble(),
              changePercent: (e['change_percent'] ?? 0).toDouble(),
            )
        ).toList() ?? [],
      );
    }
    return null;
  }

  // Clear All
  static Future<void> clearAll() async {
    await _userBox.clear();
    await _stocksBox.clear();
    await _portfolioBox.clear();
    await _watchlistBox.clear();
  }
}
