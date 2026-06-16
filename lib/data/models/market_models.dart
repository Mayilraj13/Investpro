class NewsModel {
  final String id;
  final String title;
  final String summary;
  final String source;
  final String? imageUrl;
  final String? url;
  final List<String>? relatedStocks;
  final DateTime publishedAt;
  final String category;

  NewsModel({
    required this.id,
    required this.title,
    this.summary = '',
    this.source = '',
    this.imageUrl,
    this.url,
    this.relatedStocks,
    DateTime? publishedAt,
    this.category = 'general',
  }) : publishedAt = publishedAt ?? DateTime.now();

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      source: json['source'] ?? '',
      imageUrl: json['image_url'],
      url: json['url'],
      relatedStocks: (json['related_stocks'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : DateTime.now(),
      category: json['category'] ?? 'general',
    );
  }
}

class MarketOverviewModel {
  final String indexName;
  final double currentValue;
  final double change;
  final double changePercent;
  final bool isMarketOpen;
  final double dayHigh;
  final double dayLow;
  final double advanceDecline;
  final double sensexValue;
  final double sensexChange;
  final double bankNiftyValue;
  final double bankNiftyChange;

  MarketOverviewModel({
    required this.indexName,
    required this.currentValue,
    this.change = 0,
    this.changePercent = 0,
    this.isMarketOpen = true,
    this.dayHigh = 0,
    this.dayLow = 0,
    this.advanceDecline = 0,
    this.sensexValue = 0,
    this.sensexChange = 0,
    this.bankNiftyValue = 0,
    this.bankNiftyChange = 0,
  });
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // price_alert, news, order, portfolio
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    this.body = '',
    this.type = 'general',
    this.isRead = false,
    DateTime? createdAt,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
