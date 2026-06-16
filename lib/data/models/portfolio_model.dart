class PortfolioModel {
  final double totalInvestment;
  final double currentValue;
  final double totalReturns;
  final double returnsPercentage;
  final String? userId;
  final List<Holding> holdings;
  final List<Transaction> transactions;
  final AssetAllocation assetAllocation;

  PortfolioModel({
    this.totalInvestment = 0,
    this.currentValue = 0,
    this.totalReturns = 0,
    this.returnsPercentage = 0,
    this.userId,
    this.holdings = const [],
    this.transactions = const [],
    AssetAllocation? assetAllocation,
  }) : assetAllocation = assetAllocation ?? AssetAllocation();

  double get todayProfitLoss => holdings.fold(0.0, (sum, h) => sum + h.todayProfitLoss);
  double get todayProfitLossPercent =>
      totalInvestment > 0 ? (todayProfitLoss / totalInvestment * 100) : 0;

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      totalInvestment: (json['total_investment'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      totalReturns: (json['total_returns'] ?? 0).toDouble(),
      returnsPercentage: (json['returns_percentage'] ?? 0).toDouble(),
      userId: json['user_id'],
      holdings: (json['holdings'] as List?)
              ?.map((e) => Holding.fromJson(e))
              .toList() ??
          [],
      transactions: (json['transactions'] as List?)
              ?.map((e) => Transaction.fromJson(e))
              .toList() ??
          [],
      assetAllocation: json['asset_allocation'] != null
          ? AssetAllocation.fromJson(json['asset_allocation'])
          : AssetAllocation(),
    );
  }
}

class Holding {
  final String symbol;
  final String companyName;
  final int quantity;
  final double averagePrice;
  final double currentPrice;
  final double totalInvestment;
  final double currentValue;
  final double dayChange;
  final double dayChangePercent;
  final double totalReturns;
  final double returnsPercent;
  final double weight;

  Holding({
    required this.symbol,
    required this.companyName,
    this.quantity = 0,
    this.averagePrice = 0,
    this.currentPrice = 0,
    this.totalInvestment = 0,
    this.currentValue = 0,
    this.dayChange = 0,
    this.dayChangePercent = 0,
    this.totalReturns = 0,
    this.returnsPercent = 0,
    this.weight = 0,
  });

  double get todayProfitLoss => dayChange * quantity;
  double get profitLoss => (currentPrice - averagePrice) * quantity;

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      symbol: json['symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      averagePrice: (json['average_price'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      totalInvestment: (json['total_investment'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      dayChange: (json['day_change'] ?? 0).toDouble(),
      dayChangePercent: (json['day_change_percent'] ?? 0).toDouble(),
      totalReturns: (json['total_returns'] ?? 0).toDouble(),
      returnsPercent: (json['returns_percent'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
    );
  }
}

class Transaction {
  final String id;
  final String symbol;
  final String companyName;
  final String type; // buy, sell
  final int quantity;
  final double price;
  final double totalAmount;
  final DateTime date;
  final String status; // completed, pending, failed

  Transaction({
    required this.id,
    required this.symbol,
    this.companyName = '',
    required this.type,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    DateTime? date,
    this.status = 'completed',
  }) : date = date ?? DateTime.now();

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      symbol: json['symbol'] ?? '',
      companyName: json['company_name'] ?? '',
      type: json['type'] ?? 'buy',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      status: json['status'] ?? 'completed',
    );
  }
}

class AssetAllocation {
  final double equity;
  final double mutualFunds;
  final double fixedDeposits;
  final double bonds;
  final double cash;
  final double others;

  AssetAllocation({
    this.equity = 0,
    this.mutualFunds = 0,
    this.fixedDeposits = 0,
    this.bonds = 0,
    this.cash = 0,
    this.others = 0,
  });

  double get total => equity + mutualFunds + fixedDeposits + bonds + cash + others;

  factory AssetAllocation.fromJson(Map<String, dynamic> json) {
    return AssetAllocation(
      equity: (json['equity'] ?? 0).toDouble(),
      mutualFunds: (json['mutual_funds'] ?? 0).toDouble(),
      fixedDeposits: (json['fixed_deposits'] ?? 0).toDouble(),
      bonds: (json['bonds'] ?? 0).toDouble(),
      cash: (json['cash'] ?? 0).toDouble(),
      others: (json['others'] ?? 0).toDouble(),
    );
  }
}
