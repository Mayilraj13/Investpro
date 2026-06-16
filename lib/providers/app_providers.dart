import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/stock_model.dart';
import '../data/models/portfolio_model.dart';
import '../data/models/watchlist_model.dart';
import '../data/models/market_models.dart';
import '../services/api_service.dart';
import '../core/constants/api_config.dart';

// ─── API Service Provider ───────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─── Default Indian Stock Symbols ──────────────────────────────────────

const List<String> _defaultSymbols = [
  'RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'ICICIBANK',
  'SBIN', 'BHARTIARTL', 'HINDUNILVR', 'BAJFINANCE',
  'WIPRO', 'ITC', 'ASIANPAINT', 'HCLTECH', 'MARUTI', 'TATAMOTORS',
];

// ─── Market Data State ─────────────────────────────────────────────────

class MarketDataState {
  final List<StockModel> stocks;
  final PortfolioModel portfolio;
  final MarketOverviewModel marketOverview;
  final List<NewsModel> news;
  final bool isLoading;
  final bool isStale; // true = showing fallback data, not fresh
  final String? errorMessage;
  final DateTime? lastUpdated;

  MarketDataState({
    required this.stocks,
    required this.portfolio,
    required this.marketOverview,
    required this.news,
    this.isLoading = false,
    this.isStale = false,
    this.errorMessage,
    this.lastUpdated,
  });

  MarketDataState copyWith({
    List<StockModel>? stocks,
    PortfolioModel? portfolio,
    MarketOverviewModel? marketOverview,
    List<NewsModel>? news,
    bool? isLoading,
    bool? isStale,
    String? errorMessage,
    DateTime? lastUpdated,
    bool clearError = false,
  }) {
    return MarketDataState(
      stocks: stocks ?? this.stocks,
      portfolio: portfolio ?? this.portfolio,
      marketOverview: marketOverview ?? this.marketOverview,
      news: news ?? this.news,
      isLoading: isLoading ?? this.isLoading,
      isStale: isStale ?? this.isStale,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ─── Market Data Notifier ───────────────────────────────────────────────

class MarketDataNotifier extends StateNotifier<MarketDataState> {
  final ApiService _apiService;
  final Ref _ref;
  Timer? _refreshTimer;

  /// Start with completely empty state — no mock data, no fake prices.
  /// isStale starts true because we haven't fetched anything yet.
  MarketDataNotifier(this._apiService, this._ref)
      : super(MarketDataState(
          stocks: [],
          portfolio: PortfolioModel(),
          marketOverview: MarketOverviewModel(
            indexName: 'Nifty 50',
            currentValue: 0,
            change: 0,
            changePercent: 0,
          ),
          news: [],
          isStale: true,
        )) {
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(seconds: ApiConfig.refreshIntervalSeconds),
      (_) {
        if (mounted && !state.isLoading) {
          refresh();
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Called once on app start to load initial real data.
  Future<void> loadInitialData() async {
    await refresh();
  }

  /// Refresh ALL market data from the real-time proxy.
  /// On failure, keeps showing the previous data and sets isStale = true.
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Fetch stock quotes + market overview + news in parallel
      final results = await Future.wait([
        _apiService.fetchDefaultQuotes(),
        _apiService.fetchMarketOverview(),
        _apiService.fetchNews(),
      ]);

      final List<StockModel> fetchedStocks = results[0] as List<StockModel>;
      final MarketOverviewModel fetchedOverview =
          results[1] as MarketOverviewModel;
      final List<NewsModel> fetchedNews = results[2] as List<NewsModel>;

      // Check if we actually got real data (prices > 0)
      final hasRealData =
          fetchedStocks.isNotEmpty &&
          fetchedStocks.any((s) => s.currentPrice > 0);

      if (!hasRealData) {
        state = state.copyWith(
          isLoading: false,
          isStale: true,
          errorMessage: 'Could not fetch fresh data from server',
        );
        return;
      }

      // Update watchlist prices with real data
      _updateWatchlistPrices(fetchedStocks);

      // Recalculate portfolio with real prices (keeps existing holdings)
      final updatedPortfolio = _calculatePortfolio(fetchedStocks);

      state = MarketDataState(
        stocks: fetchedStocks,
        portfolio: updatedPortfolio,
        marketOverview: fetchedOverview,
        news: fetchedNews.isNotEmpty ? fetchedNews : state.news,
        isLoading: false,
        isStale: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error refreshing market data: $e');
      state = state.copyWith(
        isLoading: false,
        isStale: true,
        errorMessage: e.toString(),
      );
    }
  }

  void _updateWatchlistPrices(List<StockModel> realTimeStocks) {
    final watchlistNotifier = _ref.read(watchlistProvider.notifier);
    final watchlist = _ref.read(watchlistProvider);

    final updatedStocks = watchlist.stocks.map((wStock) {
      final realStock = realTimeStocks.firstWhere(
        (s) => s.symbol.toUpperCase() == wStock.symbol.toUpperCase(),
        orElse: () => StockModel(
          symbol: wStock.symbol,
          name: wStock.companyName,
          currentPrice: wStock.currentPrice,
          previousClose: wStock.currentPrice,
          open: wStock.currentPrice,
          high: wStock.currentPrice,
          low: wStock.currentPrice,
          change: 0,
          changePercent: 0,
          marketCap: 0,
          volume: 0,
        ),
      );
      return WatchlistStock(
        symbol: wStock.symbol,
        companyName: wStock.companyName,
        currentPrice: realStock.currentPrice,
        change: realStock.change,
        changePercent: realStock.changePercent,
      );
    }).toList();

    watchlistNotifier.state = WatchlistModel(
      id: watchlist.id,
      name: watchlist.name,
      stocks: updatedStocks,
    );
  }

  PortfolioModel _calculatePortfolio(List<StockModel> realTimeStocks) {
    // If user has no holdings, return empty portfolio
    if (state.portfolio.holdings.isEmpty) {
      return PortfolioModel();
    }

    final List<Holding> updatedHoldings = [];
    double totalInvestment = 0;
    double currentValue = 0;

    for (var holding in state.portfolio.holdings) {
      final realTimeStock = realTimeStocks.firstWhere(
        (s) => s.symbol.toUpperCase() == holding.symbol.toUpperCase(),
        orElse: () => StockModel(
          symbol: holding.symbol,
          name: holding.companyName,
          currentPrice: holding.currentPrice,
          previousClose: holding.currentPrice,
          open: holding.currentPrice,
          high: holding.currentPrice,
          low: holding.currentPrice,
          change: 0,
          changePercent: 0,
          marketCap: 0,
          volume: 0,
        ),
      );

      final double currentPrice = realTimeStock.currentPrice;
      final double dayChange = realTimeStock.change;
      final double dayChangePercent = realTimeStock.changePercent;

      final double totalInvest = holding.quantity * holding.averagePrice;
      final double currentVal = holding.quantity * currentPrice;
      final double totalReturns = currentVal - totalInvest;
      final double returnsPercent =
          totalInvest > 0 ? (totalReturns / totalInvest * 100) : 0.0;

      totalInvestment += totalInvest;
      currentValue += currentVal;

      updatedHoldings.add(Holding(
        symbol: holding.symbol,
        companyName: holding.companyName,
        quantity: holding.quantity,
        averagePrice: holding.averagePrice,
        currentPrice: currentPrice,
        totalInvestment: totalInvest,
        currentValue: currentVal,
        dayChange: dayChange,
        dayChangePercent: dayChangePercent,
        totalReturns: totalReturns,
        returnsPercent: returnsPercent,
        weight: holding.weight,
      ));
    }

    final double totalReturns = currentValue - totalInvestment;
    final double returnsPercentage =
        totalInvestment > 0 ? (totalReturns / totalInvestment * 100) : 0.0;

    return PortfolioModel(
      totalInvestment: totalInvestment,
      currentValue: currentValue,
      totalReturns: totalReturns,
      returnsPercentage: returnsPercentage,
      holdings: updatedHoldings,
      transactions: state.portfolio.transactions,
    );
  }
}

// ─── Provider Definitions ───────────────────────────────────────────────

final marketDataNotifierProvider =
    StateNotifierProvider<MarketDataNotifier, MarketDataState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final notifier = MarketDataNotifier(apiService, ref);
  Future.microtask(() => notifier.loadInitialData());
  return notifier;
});

// Slice providers
final stockListProvider = Provider<List<StockModel>>((ref) {
  return ref.watch(marketDataNotifierProvider).stocks;
});

final stockBySymbolProvider =
    Provider.family<StockModel?, String>((ref, symbol) {
  final stocks = ref.watch(stockListProvider);
  try {
    return stocks
        .firstWhere((s) => s.symbol.toUpperCase() == symbol.toUpperCase());
  } catch (_) {
    return null;
  }
});

final topGainersProvider = Provider<List<StockModel>>((ref) {
  final List<StockModel> stocks = [...ref.watch(stockListProvider)];
  stocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
  return stocks.take(5).toList();
});

final topLosersProvider = Provider<List<StockModel>>((ref) {
  final List<StockModel> stocks = [...ref.watch(stockListProvider)];
  stocks.sort((a, b) => a.changePercent.compareTo(b.changePercent));
  return stocks.take(5).toList();
});

final trendingStocksProvider = Provider<List<StockModel>>((ref) {
  final List<StockModel> stocks = [...ref.watch(stockListProvider)];
  stocks.sort((a, b) {
    final double bScore = b.volume * b.changePercent.abs();
    final double aScore = a.volume * a.changePercent.abs();
    return bScore.compareTo(aScore);
  });
  return stocks.take(8).toList();
});

final marketOverviewProvider = Provider<MarketOverviewModel>((ref) {
  return ref.watch(marketDataNotifierProvider).marketOverview;
});

final portfolioProvider = Provider<PortfolioModel>((ref) {
  return ref.watch(marketDataNotifierProvider).portfolio;
});

final holdingsProvider = Provider<List<Holding>>((ref) {
  return ref.watch(marketDataNotifierProvider).portfolio.holdings;
});

final transactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(marketDataNotifierProvider).portfolio.transactions;
});

final newsProvider = Provider<List<NewsModel>>((ref) {
  return ref.watch(marketDataNotifierProvider).news;
});

final isDataStaleProvider = Provider<bool>((ref) {
  return ref.watch(marketDataNotifierProvider).isStale;
});

final lastUpdatedProvider = Provider<DateTime?>((ref) {
  return ref.watch(marketDataNotifierProvider).lastUpdated;
});

// Asynchronous Stock Details Provider
final stockQuoteProvider =
    FutureProvider.family<StockModel?, String>((ref, symbol) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchStockQuote(symbol);
});

// Search
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredStocksProvider =
    FutureProvider.family<List<StockModel>, String>((ref, query) async {
  if (query.length < 2) return [];
  final apiService = ref.read(apiServiceProvider);
  return apiService.searchStocks(query);
});

// Chart
final selectedPeriodProvider =
    StateProvider.family<String, String>((ref, symbol) => '1M');

final stockChartProvider =
    FutureProvider.family<List<PricePoint>, (String, String)>(
        (ref, arg) async {
  final symbol = arg.$1;
  final period = arg.$2;
  final apiService = ref.read(apiServiceProvider);
  return apiService.fetchHistoricalPrices(symbol, period);
});

// ─── Watchlist ──────────────────────────────────────────────────────────

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, WatchlistModel>((ref) {
  return WatchlistNotifier();
});

class WatchlistNotifier extends StateNotifier<WatchlistModel> {
  /// Start with real stock symbols and 0 prices.
  /// Prices get updated on first successful refresh() call.
  WatchlistNotifier()
      : super(WatchlistModel(
            id: 'wl1', name: 'My Watchlist', stocks: _initialStocks));

  static final List<WatchlistStock> _initialStocks = [
    WatchlistStock(
        symbol: 'RELIANCE',
        companyName: 'Reliance Industries',
        currentPrice: 0,
        change: 0,
        changePercent: 0),
    WatchlistStock(
        symbol: 'HDFCBANK',
        companyName: 'HDFC Bank Ltd',
        currentPrice: 0,
        change: 0,
        changePercent: 0),
    WatchlistStock(
        symbol: 'TCS',
        companyName: 'TCS Ltd',
        currentPrice: 0,
        change: 0,
        changePercent: 0),
    WatchlistStock(
        symbol: 'SBIN',
        companyName: 'State Bank of India',
        currentPrice: 0,
        change: 0,
        changePercent: 0),
  ];

  void addStock(WatchlistStock stock) {
    if (!state.stocks.any((s) => s.symbol == stock.symbol)) {
      state = WatchlistModel(
        id: state.id,
        name: state.name,
        stocks: [...state.stocks, stock],
      );
    }
  }

  void removeStock(String symbol) {
    state = WatchlistModel(
      id: state.id,
      name: state.name,
      stocks: state.stocks.where((s) => s.symbol != symbol).toList(),
    );
  }

  bool isInWatchlist(String symbol) {
    return state.stocks.any((s) => s.symbol == symbol);
  }

  void toggleStock(String symbol, String companyName) {
    if (isInWatchlist(symbol)) {
      removeStock(symbol);
    } else {
      addStock(WatchlistStock(symbol: symbol, companyName: companyName));
    }
  }
}
