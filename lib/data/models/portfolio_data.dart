import 'token.dart';

class PortfolioData {
  final double totalValue;
  final double totalChange24h;
  final double percentChange24h;
  final List<Token> tokens;
  final DateTime lastUpdated;

  PortfolioData({
    required this.totalValue,
    required this.totalChange24h,
    required this.percentChange24h,
    required this.tokens,
    required this.lastUpdated,
  });

  factory PortfolioData.fromJson(Map<String, dynamic> json) {
    return PortfolioData(
      totalValue: json['totalValue'].toDouble(),
      totalChange24h: json['totalChange24h'].toDouble(),
      percentChange24h: json['percentChange24h'].toDouble(),
      tokens: (json['tokens'] as List)
          .map((token) => Token.fromJson(token))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalValue': totalValue,
      'totalChange24h': totalChange24h,
      'percentChange24h': percentChange24h,
      'tokens': tokens.map((token) => token.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}