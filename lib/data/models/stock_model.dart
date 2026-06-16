class StockModel {
  final String symbol;
  final String name;
  final String exchange;
  final String sector;
  final String industry;
  final double currentPrice;
  final double previousClose;
  final double open;
  final double high;
  final double low;
  final double change;
  final double changePercent;
  final double marketCap;
  final double volume;
  final double avgVolume;
  final double? dividendYield;
  final double? peRatio;
  final double? eps;
  final double? pbRatio;
  final double? roe;
  final double? roce;
  final double? debtToEquity;
  final double? profitMargin;
  final double? revenueGrowth;
  final double? profitGrowth;
  final String? description;
  final String? ceo;
  final String? website;
  final DateTime? listingDate;
  final double? high52Week;
  final double? low52Week;
  final bool isInWatchlist;
  final List<PricePoint>? historicalPrices;

  StockModel({
    required this.symbol,
    required this.name,
    this.exchange = 'NSE',
    this.sector = '',
    this.industry = '',
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.change,
    required this.changePercent,
    required this.marketCap,
    required this.volume,
    this.avgVolume = 0,
    this.dividendYield,
    this.peRatio,
    this.eps,
    this.pbRatio,
    this.roe,
    this.roce,
    this.debtToEquity,
    this.profitMargin,
    this.revenueGrowth,
    this.profitGrowth,
    this.description,
    this.ceo,
    this.website,
    this.listingDate,
    this.high52Week,
    this.low52Week,
    this.isInWatchlist = false,
    this.historicalPrices,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      exchange: json['exchange'] ?? 'NSE',
      sector: json['sector'] ?? '',
      industry: json['industry'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      previousClose: (json['previous_close'] ?? 0).toDouble(),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['change_percent'] ?? 0).toDouble(),
      marketCap: (json['market_cap'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
      avgVolume: (json['avg_volume'] ?? 0).toDouble(),
      dividendYield: (json['dividend_yield'] ?? 0).toDouble(),
      peRatio: (json['pe_ratio'] ?? 0).toDouble(),
      eps: (json['eps'] ?? 0).toDouble(),
      pbRatio: (json['pb_ratio'] ?? 0).toDouble(),
      roe: (json['roe'] ?? 0).toDouble(),
      roce: (json['roce'] ?? 0).toDouble(),
      debtToEquity: (json['debt_to_equity'] ?? 0).toDouble(),
      profitMargin: (json['profit_margin'] ?? 0).toDouble(),
      revenueGrowth: (json['revenue_growth'] ?? 0).toDouble(),
      profitGrowth: (json['profit_growth'] ?? 0).toDouble(),
      description: json['description'],
      ceo: json['ceo'],
      website: json['website'],
      listingDate: json['listing_date'] != null
          ? DateTime.parse(json['listing_date'])
          : null,
      high52Week: (json['high_52_week'] ?? 0).toDouble(),
      low52Week: (json['low_52_week'] ?? 0).toDouble(),
      isInWatchlist: json['is_in_watchlist'] ?? false,
      historicalPrices: (json['historical_prices'] as List?)
          ?.map((e) => PricePoint.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'exchange': exchange,
        'sector': sector,
        'industry': industry,
        'current_price': currentPrice,
        'previous_close': previousClose,
        'open': open,
        'high': high,
        'low': low,
        'change': change,
        'change_percent': changePercent,
        'market_cap': marketCap,
        'volume': volume,
        'avg_volume': avgVolume,
        'dividend_yield': dividendYield,
        'pe_ratio': peRatio,
        'eps': eps,
        'pb_ratio': pbRatio,
        'roe': roe,
        'roce': roce,
        'debt_to_equity': debtToEquity,
        'profit_margin': profitMargin,
        'revenue_growth': revenueGrowth,
        'profit_growth': profitGrowth,
        'description': description,
        'ceo': ceo,
        'website': website,
        'listing_date': listingDate?.toIso8601String(),
        'high_52_week': high52Week,
        'low_52_week': low52Week,
        'is_in_watchlist': isInWatchlist,
        'historical_prices':
            historicalPrices?.map((e) => e.toJson()).toList(),
      };
}

class PricePoint {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  PricePoint({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
      };
}

class MarketDepth {
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;

  MarketDepth({required this.bids, required this.asks});
}

class DepthLevel {
  final double price;
  final int quantity;
  final int orders;

  DepthLevel({
    required this.price,
    required this.quantity,
    this.orders = 1,
  });
}

class AnalystRating {
  final int strongBuy;
  final int buy;
  final int hold;
  final int sell;
  final int strongSell;
  final double targetPrice;

  AnalystRating({
    this.strongBuy = 0,
    this.buy = 0,
    this.hold = 0,
    this.sell = 0,
    this.strongSell = 0,
    this.targetPrice = 0,
  });

  int get total => strongBuy + buy + hold + sell + strongSell;

  double get buyPercent =>
      total > 0 ? ((strongBuy + buy) / total * 100) : 0;
}
