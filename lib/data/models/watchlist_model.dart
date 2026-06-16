class WatchlistModel {
  final String id;
  final String name;
  final List<WatchlistStock> stocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  WatchlistModel({
    required this.id,
    this.name = 'Default',
    this.stocks = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    return WatchlistModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Default',
      stocks: (json['stocks'] as List?)
              ?.map((e) => WatchlistStock.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
}

class WatchlistStock {
  final String symbol;
  final String companyName;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double? targetPrice;
  final DateTime addedAt;

  WatchlistStock({
    required this.symbol,
    required this.companyName,
    this.currentPrice = 0,
    this.change = 0,
    this.changePercent = 0,
    this.targetPrice,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory WatchlistStock.fromJson(Map<String, dynamic> json) {
    return WatchlistStock(
      symbol: json['symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      changePercent: (json['change_percent'] ?? 0).toDouble(),
      targetPrice: (json['target_price'] ?? 0).toDouble(),
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'])
          : DateTime.now(),
    );
  }
}

class PriceAlert {
  final String id;
  final String symbol;
  final String companyName;
  final double targetPrice;
  final String condition; // above, below
  final bool isActive;
  final DateTime createdAt;

  PriceAlert({
    required this.id,
    required this.symbol,
    this.companyName = '',
    required this.targetPrice,
    this.condition = 'above',
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
