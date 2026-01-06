// lib/data/services/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/token.dart';
import '../models/portfolio_data.dart';
import '../models/wallet.dart';

class LocalStorageService {
  static const String _watchlistKey = 'watchlist';
  static const String _portfolioKey = 'portfolio_data';
  static const String _walletsKey = 'wallets';
  static const String _manualHoldingsKey = 'manual_holdings';
  
  // Token/Watchlist methods
  
  Future<void> saveWatchlist(List<Token> tokens) async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistData = tokens.map((token) => token.toJson()).toList();
    await prefs.setString(_watchlistKey, jsonEncode(watchlistData));
  }
  
  Future<List<Token>> getWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final watchlistJson = prefs.getString(_watchlistKey);
    
    if (watchlistJson == null) {
      return [];
    }
    
    final watchlistData = List<Map<String, dynamic>>.from(jsonDecode(watchlistJson));
    return watchlistData.map((json) => Token.fromJson(json)).toList();
  }
  
  Future<void> cachePortfolioData(PortfolioData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_portfolioKey, jsonEncode(data.toJson()));
  }
  
  Future<PortfolioData?> getCachedPortfolioData() async {
    final prefs = await SharedPreferences.getInstance();
    final portfolioJson = prefs.getString(_portfolioKey);
    
    if (portfolioJson == null) return null;
    
    try {
      return PortfolioData.fromJson(jsonDecode(portfolioJson));
    } catch (e) {
      // If there's an error parsing cached data, return null
      return null;
    }
  }
  
  Future<void> clearCachedPortfolioData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_portfolioKey);
  }
  
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchlistKey);
    await prefs.remove(_portfolioKey);
    await prefs.remove(_walletsKey);
    await prefs.remove(_manualHoldingsKey);
  }
  
  Future<void> addToken(Token token) async {
    final tokens = await getWatchlist();
    
    // Check if token already exists
    final existingIndex = tokens.indexWhere((t) => t.id == token.id);
    
    if (existingIndex >= 0) {
      // Update existing token
      tokens[existingIndex] = token;
    } else {
      // Add new token
      tokens.add(token);
    }
    
    await saveWatchlist(tokens);
  }
  
  Future<void> removeToken(int tokenId) async {
    print('LocalStorageService.removeToken called with tokenId: $tokenId');
    final tokens = await getWatchlist();
    print('Current watchlist count: ${tokens.length}');
    print('Token IDs in watchlist: ${tokens.map((t) => t.id).toList()}');
    tokens.removeWhere((t) => t.id == tokenId);
    print('After removal, watchlist count: ${tokens.length}');
    await saveWatchlist(tokens);
    
    // Also remove manual holdings for this token
    await removeManualHoldings(tokenId);
    
    // Clear cached portfolio data so it doesn't return stale data
    await clearCachedPortfolioData();
    print('Token removal complete');
  }
  
  Future<void> updateTokenHoldings(int tokenId, double holdings) async {
    final tokens = await getWatchlist();
    final index = tokens.indexWhere((t) => t.id == tokenId);
    
    if (index >= 0) {
      final oldToken = tokens[index];
      tokens[index] = Token(
        id: oldToken.id,
        symbol: oldToken.symbol,
        name: oldToken.name,
        logo: oldToken.logo,
        currentPrice: oldToken.currentPrice,
        priceChange24h: oldToken.priceChange24h,
        percentChange24h: oldToken.percentChange24h,
        holdings: holdings,
        exchange: oldToken.exchange,
        marketCap: oldToken.marketCap,
        volume24h: oldToken.volume24h,
      );
      await saveWatchlist(tokens);
    }
  }
  
  // Wallet methods
  
  Future<List<Wallet>> getWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final walletsJson = prefs.getString(_walletsKey);
    
    if (walletsJson == null) {
      return [];
    }
    
    final walletsData = List<Map<String, dynamic>>.from(jsonDecode(walletsJson));
    return walletsData.map((json) => Wallet.fromJson(json)).toList();
  }
  
  Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    final walletsData = wallets.map((wallet) => wallet.toJson()).toList();
    await prefs.setString(_walletsKey, jsonEncode(walletsData));
  }
  
  Future<void> addWallet(Wallet wallet) async {
    final wallets = await getWallets();
    
    // Check if wallet already exists
    final existingIndex = wallets.indexWhere(
      (w) => w.address == wallet.address && w.chain == wallet.chain,
    );
    
    if (existingIndex >= 0) {
      // Update existing wallet
      wallets[existingIndex] = wallet;
    } else {
      // Add new wallet
      wallets.add(wallet);
    }
    
    await saveWallets(wallets);
  }
  
  Future<void> updateWallet(Wallet wallet) async {
    final wallets = await getWallets();
    final index = wallets.indexWhere(
      (w) => w.address == wallet.address && w.chain == wallet.chain,
    );
    
    if (index >= 0) {
      wallets[index] = wallet;
      await saveWallets(wallets);
    }
  }
  
  Future<void> removeWallet(String address, String chain) async {
    final wallets = await getWallets();
    wallets.removeWhere((w) => w.address == address && w.chain == chain);
    await saveWallets(wallets);
  }
  
  // Manual holdings methods (separate from wallet holdings)
  
  Future<Map<int, double>> getManualHoldings() async {
    final prefs = await SharedPreferences.getInstance();
    final holdingsJson = prefs.getString(_manualHoldingsKey);
    
    if (holdingsJson == null) {
      return {};
    }
    
    final holdingsData = Map<String, dynamic>.from(jsonDecode(holdingsJson));
    return holdingsData.map((key, value) => MapEntry(int.parse(key), (value as num).toDouble()));
  }
  
  Future<void> saveManualHoldings(Map<int, double> holdings) async {
    final prefs = await SharedPreferences.getInstance();
    final holdingsData = holdings.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_manualHoldingsKey, jsonEncode(holdingsData));
  }
  
  Future<void> setManualHoldings(int tokenId, double holdings) async {
    final allHoldings = await getManualHoldings();
    allHoldings[tokenId] = holdings;
    await saveManualHoldings(allHoldings);
  }
  
  Future<void> removeManualHoldings(int tokenId) async {
    final allHoldings = await getManualHoldings();
    allHoldings.remove(tokenId);
    await saveManualHoldings(allHoldings);
  }
  
  Future<double> getManualHoldingsForToken(int tokenId) async {
    final allHoldings = await getManualHoldings();
    return allHoldings[tokenId] ?? 0;
  }
}