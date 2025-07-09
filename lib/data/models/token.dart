// lib/data/models/token.dart

class Token {
  final int id;
  final String symbol;
  final String name;
  final String? logo;
  final double currentPrice;
  final double priceChange24h;
  final double percentChange24h;
  final double? holdings;
  final String? exchange;
  final double? marketCap;
  final double? volume24h;
  final double? volumeChange24h;
  final List<PricePoint>? hourlyPriceHistory;
  final List<PricePoint>? dailyPriceHistory;

  Token({
    required this.id,
    required this.symbol,
    required this.name,
    this.logo,
    required this.currentPrice,
    required this.priceChange24h,
    required this.percentChange24h,
    this.holdings,
    this.exchange,
    this.marketCap,
    this.volume24h,
    this.volumeChange24h,
    this.hourlyPriceHistory,
    this.dailyPriceHistory,
  });

  double get totalValue => (holdings ?? 0) * currentPrice;

  factory Token.fromApiResponse(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    final percentChange = (json['price_24h_change'] as num?)?.toDouble() ?? 0.0;
    final previousPrice = percentChange != 0 ? price / (1 + (percentChange / 100)) : price;
    final priceChange = price - previousPrice;
    
    // Parse hourly price history (24h_price_history)
    List<PricePoint>? hourlyHistory;
    if (json['24h_price_history'] != null) {
      hourlyHistory = (json['24h_price_history'] as List)
          .map((point) => PricePoint(
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                    ((point[0] as num) * 1000).toInt()),
                price: (point[1] as num).toDouble(),
              ))
          .toList();
    }
    
    // Parse daily price history
    List<PricePoint>? dailyHistory;
    if (json['daily_price_history'] != null) {
      dailyHistory = (json['daily_price_history'] as List)
          .map((point) {
            try {
              return PricePoint(
                timestamp: DateTime.parse(point[0] as String),
                price: (point[1] as num).toDouble(),
              );
            } catch (e) {
              print('Error parsing price point: $point, error: $e');
              return null;
            }
          })
          .where((point) => point != null)
          .cast<PricePoint>()
          .toList();
    }
    
    return Token(
      id: json['token_id'] ?? json['id'],
      symbol: json['ticker'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'],
      currentPrice: price,
      priceChange24h: priceChange,
      percentChange24h: percentChange,
      holdings: (json['holdings'] as num?)?.toDouble(),
      exchange: json['exchange'],
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      volume24h: (json['volume'] as num?)?.toDouble(),
      volumeChange24h: (json['volume_24h_change'] as num?)?.toDouble(),
      hourlyPriceHistory: hourlyHistory,
      dailyPriceHistory: dailyHistory,
    );
  }

  factory Token.fromJson(Map<String, dynamic> json) {
    // Parse saved price history if available
    List<PricePoint>? hourlyHistory;
    if (json['hourlyPriceHistory'] != null) {
      hourlyHistory = (json['hourlyPriceHistory'] as List)
          .map((point) => PricePoint.fromJson(point))
          .toList();
    }
    
    List<PricePoint>? dailyHistory;
    if (json['dailyPriceHistory'] != null) {
      dailyHistory = (json['dailyPriceHistory'] as List)
          .map((point) => PricePoint.fromJson(point))
          .toList();
    }
    
    return Token(
      id: json['id'],
      symbol: json['symbol'],
      name: json['name'],
      logo: json['logo'],
      currentPrice: (json['currentPrice'] as num).toDouble(),
      priceChange24h: (json['priceChange24h'] as num).toDouble(),
      percentChange24h: (json['percentChange24h'] as num).toDouble(),
      holdings: (json['holdings'] as num?)?.toDouble(),
      exchange: json['exchange'],
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      volume24h: (json['volume24h'] as num?)?.toDouble(),
      volumeChange24h: (json['volumeChange24h'] as num?)?.toDouble(),
      hourlyPriceHistory: hourlyHistory,
      dailyPriceHistory: dailyHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'logo': logo,
      'currentPrice': currentPrice,
      'priceChange24h': priceChange24h,
      'percentChange24h': percentChange24h,
      'holdings': holdings,
      'exchange': exchange,
      'marketCap': marketCap,
      'volume24h': volume24h,
      'volumeChange24h': volumeChange24h,
      'hourlyPriceHistory': hourlyPriceHistory?.map((p) => p.toJson()).toList(),
      'dailyPriceHistory': dailyPriceHistory?.map((p) => p.toJson()).toList(),
    };
  }
  
  Map<String, dynamic> toApiRequest() {
    return {
      'token_id': id,
      'price': currentPrice,
      'holdings': holdings ?? 0,
      'exchange': exchange,
    };
  }
}

class PricePoint {
  final DateTime timestamp;
  final double price;

  PricePoint({
    required this.timestamp,
    required this.price,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      timestamp: DateTime.parse(json['timestamp']),
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
    };
  }
}