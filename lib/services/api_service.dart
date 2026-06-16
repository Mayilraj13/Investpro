import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_config.dart';
import '../data/models/stock_model.dart';
import '../data/models/market_models.dart';

/// API Service for InvestPro.
///
/// Primary (and only) data source: the local Python proxy
/// at [ApiConfig.baseUrl]. No mock/fallback data — the app
/// shows a stale-data banner when the proxy is unreachable
/// and keeps displaying the last successful response.
class ApiService {
  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: ApiConfig.apiTimeoutSeconds),
            receiveTimeout: const Duration(seconds: ApiConfig.apiTimeoutSeconds),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'InvestPro/2.0',
            },
          ),
        );

  // ─── Core HTTP helpers ──────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  // ─── Quote parsing ──────────────────────────────────────────────────────

  StockModel? _quoteToModel(dynamic data, String symbol) {
    if (data == null) return null;
    try {
      final d = data is Map<String, dynamic>
          ? data
          : jsonDecode(data) as Map<String, dynamic>;
      return StockModel(
        symbol: (d['symbol'] ?? symbol).toString().toUpperCase(),
        name: d['name'] ?? symbol,
        exchange: d['exchange'] ?? 'NSE',
        sector: d['sector'] ?? '',
        industry: d['industry'] ?? '',
        currentPrice: (d['currentPrice'] ?? 0).toDouble(),
        previousClose: (d['previousClose'] ?? 0).toDouble(),
        open: (d['open'] ?? 0).toDouble(),
        high: (d['high'] ?? 0).toDouble(),
        low: (d['low'] ?? 0).toDouble(),
        change: (d['change'] ?? 0).toDouble(),
        changePercent: (d['changePercent'] ?? 0).toDouble(),
        marketCap: (d['marketCap'] ?? 0).toDouble(),
        volume: (d['volume'] ?? 0).toDouble(),
        avgVolume: (d['avgVolume'] ?? 0).toDouble(),
        dividendYield: d['dividendYield']?.toDouble(),
        peRatio: d['peRatio']?.toDouble(),
        eps: d['eps']?.toDouble(),
        pbRatio: d['pbRatio']?.toDouble(),
        roe: d['roe']?.toDouble(),
        roce: d['roce']?.toDouble(),
        debtToEquity: d['debtToEquity']?.toDouble(),
        profitMargin: d['profitMargin']?.toDouble(),
        revenueGrowth: d['revenueGrowth']?.toDouble(),
        profitGrowth: d['profitGrowth']?.toDouble(),
        description: d['description'],
        ceo: d['ceo'],
        website: d['website'],
        high52Week: d['high52Week']?.toDouble(),
        low52Week: d['low52Week']?.toDouble(),
      );
    } catch (e) {
      debugPrint('Error parsing quote for $symbol: $e');
      return null;
    }
  }

  // ─── InvestPro Proxy Endpoints ──────────────────────────────────────────

  /// Fetch a single stock quote from the proxy.
  Future<StockModel?> fetchStockQuote(String symbol) async {
    try {
      final response = await _dio.get('/quote/$symbol');
      return _quoteToModel(response.data, symbol);
    } catch (e) {
      debugPrint('Proxy error for $symbol: $e');
      return null;
    }
  }

  /// Fetch all default stock quotes (15 major Indian stocks).
  Future<List<StockModel>> fetchDefaultQuotes() async {
    try {
      final response = await _dio.get('/default-quotes');
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as Map? ?? {};
        final stocks = <StockModel>[];
        for (final entry in results.entries) {
          final model = _quoteToModel(entry.value, entry.key);
          if (model != null) stocks.add(model);
        }
        return stocks;
      }
    } catch (e) {
      debugPrint('Proxy default-quotes error: $e');
    }
    return [];
  }

  /// Fetch multiple stock quotes for a given list of symbols.
  Future<List<StockModel>> fetchMultipleQuotes(List<String> symbols) async {
    try {
      final response = await _dio.post('/quotes', data: {'symbols': symbols});
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as Map? ?? {};
        final stocks = <StockModel>[];
        for (final entry in results.entries) {
          final model = _quoteToModel(entry.value, entry.key);
          if (model != null) stocks.add(model);
        }
        return stocks;
      }
    } catch (e) {
      debugPrint('Proxy multi-quote error: $e');
    }
    return [];
  }

  /// Search stocks by keyword.
  Future<List<StockModel>> searchStocks(String keyword) async {
    if (keyword.length < 2) return [];
    try {
      final response = await _dio.get('/search', queryParameters: {'q': keyword});
      if (response.statusCode == 200 && response.data != null) {
        final results = response.data['results'] as List? ?? [];
        return results.map((r) {
          final d = r as Map<String, dynamic>;
          return StockModel(
            symbol: (d['symbol'] ?? '').toString().toUpperCase(),
            name: d['name'] ?? '',
            exchange: d['exchange'] ?? 'NSE',
            sector: d['sector'] ?? 'General',
            industry: d['industry'] ?? '',
            currentPrice: (d['currentPrice'] ?? 0).toDouble(),
            previousClose: 0,
            open: 0,
            high: 0,
            low: 0,
            change: (d['change'] ?? 0).toDouble(),
            changePercent: (d['changePercent'] ?? 0).toDouble(),
            marketCap: 0,
            volume: 0,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Proxy search error: $e');
    }
    return [];
  }

  /// Fetch historical OHLCV price data for charting.
  Future<List<PricePoint>> fetchHistoricalPrices(
      String symbol, String period) async {
    try {
      final response = await _dio.get('/history/$symbol',
          queryParameters: {'period': period});
      if (response.statusCode == 200 && response.data != null) {
        final prices = response.data['prices'] as List? ?? [];
        return prices.map((p) {
          final d = p as Map<String, dynamic>;
          return PricePoint(
            date: DateTime.tryParse(d['date'] ?? '') ?? DateTime.now(),
            open: (d['open'] ?? 0).toDouble(),
            high: (d['high'] ?? 0).toDouble(),
            low: (d['low'] ?? 0).toDouble(),
            close: (d['close'] ?? 0).toDouble(),
            volume: (d['volume'] ?? 0).toDouble(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Proxy history error for $symbol: $e');
    }
    return [];
  }

  /// Fetch market overview (Nifty, Sensex, Bank Nifty indices).
  Future<MarketOverviewModel> fetchMarketOverview() async {
    try {
      final response = await _dio.get('/market-overview');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final indices = data['indices'] as Map? ?? {};
        final nifty = indices['NIFTY 50'] as Map?;
        final sensex = indices['SENSEX'] as Map?;
        final bankNifty = indices['BANK NIFTY'] as Map?;
        final isOpen = data['isMarketOpen'] as bool? ?? true;

        return MarketOverviewModel(
          indexName: 'Nifty 50',
          currentValue: (nifty?['currentValue'] ?? 0).toDouble(),
          change: (nifty?['change'] ?? 0).toDouble(),
          changePercent: (nifty?['changePercent'] ?? 0).toDouble(),
          isMarketOpen: isOpen,
          dayHigh: (nifty?['dayHigh'] ?? 0).toDouble(),
          dayLow: (nifty?['dayLow'] ?? 0).toDouble(),
          sensexValue: (sensex?['currentValue'] ?? 0).toDouble(),
          sensexChange: (sensex?['changePercent'] ?? 0).toDouble(),
          bankNiftyValue: (bankNifty?['currentValue'] ?? 0).toDouble(),
          bankNiftyChange: (bankNifty?['changePercent'] ?? 0).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Proxy market-overview error: $e');
    }
    // Return zeroed overview when proxy is unreachable
    return MarketOverviewModel(
      indexName: 'Nifty 50',
      currentValue: 0,
      change: 0,
      changePercent: 0,
    );
  }

  /// Fetch market news from the proxy.
  Future<List<NewsModel>> fetchNews() async {
    try {
      final response = await _dio.get('/news');
      if (response.statusCode == 200 && response.data != null) {
        final newsItems = response.data['news'] as List? ?? [];
        return newsItems.map((item) {
          final d = item as Map<String, dynamic>;
          return NewsModel(
            id: d['id'] ?? '',
            title: d['title'] ?? '',
            summary: d['summary'] ?? d['title'] ?? '',
            source: d['source'] ?? 'Market News',
            imageUrl: d['imageUrl'],
            url: d['url'],
            publishedAt:
                DateTime.tryParse(d['publishedAt'] ?? '') ?? DateTime.now(),
            category: d['category'] ?? 'market',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Proxy news error: $e');
    }
    return [];
  }
}
