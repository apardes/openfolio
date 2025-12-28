// lib/data/models/wallet.dart

class Wallet {
  final String address;
  final String chain;
  final String? name;
  final double nativeBalance;
  final double? stakeBalance;
  final int? tokenId; // Openfolio token ID for native balance
  final List<WalletToken> tokens;
  final DateTime? lastUpdated;

  Wallet({
    required this.address,
    required this.chain,
    this.name,
    this.nativeBalance = 0,
    this.stakeBalance,
    this.tokenId,
    this.tokens = const [],
    this.lastUpdated,
  });

  double get totalNativeBalance => nativeBalance + (stakeBalance ?? 0);

  String get displayName => name ?? _truncateAddress(address);

  String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String get chainSymbol {
    switch (chain.toUpperCase()) {
      case 'BTC':
        return 'BTC';
      case 'ETH':
        return 'ETH';
      case 'SOL':
        return 'SOL';
      default:
        return chain.toUpperCase();
    }
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      address: json['address'],
      chain: json['chain'],
      name: json['name'],
      nativeBalance: _parseDouble(json['native_balance']),
      stakeBalance: _parseDoubleNullable(json['stake_balance']),
      tokenId: json['token_id'],
      tokens: json['tokens'] != null
          ? (json['tokens'] as List)
              .map((t) => WalletToken.fromJson(t))
              .toList()
          : [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  factory Wallet.fromApiResponse(Map<String, dynamic> json, String address, String chain) {
    return Wallet(
      address: address,
      chain: chain,
      name: json['name'],
      nativeBalance: _parseDouble(json['native_balance']),
      stakeBalance: _parseDoubleNullable(json['stake_balance']),
      tokenId: json['token_id'],
      tokens: json['tokens'] != null
          ? (json['tokens'] as List)
              .map((t) => WalletToken.fromJson(t))
              .toList()
          : [],
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'chain': chain,
      'name': name,
      'native_balance': nativeBalance,
      'stake_balance': stakeBalance,
      'token_id': tokenId,
      'tokens': tokens.map((t) => t.toJson()).toList(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  Wallet copyWith({
    String? address,
    String? chain,
    String? name,
    double? nativeBalance,
    double? stakeBalance,
    int? tokenId,
    List<WalletToken>? tokens,
    DateTime? lastUpdated,
  }) {
    return Wallet(
      address: address ?? this.address,
      chain: chain ?? this.chain,
      name: name ?? this.name,
      nativeBalance: nativeBalance ?? this.nativeBalance,
      stakeBalance: stakeBalance ?? this.stakeBalance,
      tokenId: tokenId ?? this.tokenId,
      tokens: tokens ?? this.tokens,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class WalletToken {
  final String ticker;
  final String address;
  final double balance;
  final int? tokenId; // Openfolio token ID, null if not mapped

  WalletToken({
    required this.ticker,
    required this.address,
    required this.balance,
    this.tokenId,
  });

  factory WalletToken.fromJson(Map<String, dynamic> json) {
    return WalletToken(
      ticker: json['ticker'] ?? '',
      address: json['address'] ?? '',
      balance: _parseDouble(json['balance']),
      tokenId: json['token_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticker': ticker,
      'address': address,
      'balance': balance,
      'token_id': tokenId,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}