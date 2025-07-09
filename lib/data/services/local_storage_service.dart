// lib/data/services/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/token.dart';
import '../models/portfolio_data.dart';

class LocalStorageService {
  static const String _watchlistKey = 'watchlist';
  static const String _portfolioKey = 'portfolio_data';
  
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
  
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_watchlistKey);
    await prefs.remove(_portfolioKey);
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
    final tokens = await getWatchlist();
    tokens.removeWhere((t) => t.id == tokenId);
    await saveWatchlist(tokens);
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
}