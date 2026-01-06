// lib/data/repositories/portfolio_repository.dart

import '../models/token.dart';
import '../models/portfolio_data.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';

class PortfolioRepository {
  final LocalStorageService _localStorage = LocalStorageService();
  final ApiService _apiService = ApiService();
  
  /// Get portfolio data with optional wallet holdings
  /// walletHoldings is a map of token_id -> balance from tracked wallets
  /// walletTokenInfo is a map of token_id -> token info for tokens only in wallets
  Future<PortfolioData> getPortfolioData({
    Map<int, double>? walletHoldings,
    Map<int, Map<String, dynamic>>? walletTokenInfo,
  }) async {
    try {
      // Get watchlist from local storage
      final watchlistTokens = await _localStorage.getWatchlist();
      
      print('=== Portfolio Data Flow ===');
      print('Watchlist tokens: ${watchlistTokens.length}');
      
      // Debug: print manual holdings from watchlist
      print('=== Manual holdings from watchlist ===');
      for (final token in watchlistTokens) {
        print('${token.symbol} (id=${token.id}): manual holdings = ${token.holdings}');
      }
      
      // Debug: print wallet holdings passed in
      print('=== Wallet holdings passed in (by token ID) ===');
      if (walletHoldings != null && walletHoldings.isNotEmpty) {
        walletHoldings.forEach((tokenId, balance) {
          print('Token ID $tokenId: wallet holdings = $balance');
        });
      } else {
        print('No wallet holdings passed');
      }
      
      // Find wallet-only tokens (tokens in wallets but not in watchlist)
      // Only include if they have a balance > 0
      final watchlistIds = watchlistTokens.map((t) => t.id).toSet();
      final walletOnlyTokenIds = <int>{};
      if (walletHoldings != null) {
        for (final tokenId in walletHoldings.keys) {
          if (!watchlistIds.contains(tokenId) && walletHoldings[tokenId]! > 0) {
            walletOnlyTokenIds.add(tokenId);
          }
        }
      }
      
      print('=== Wallet-only tokens (not in watchlist, balance > 0) ===');
      print('Count: ${walletOnlyTokenIds.length}');
      walletOnlyTokenIds.forEach((id) => print('  Token ID: $id'));
      
      // Prepare token list for API - combine watchlist + wallet-only tokens
      final tokenListForApi = <Map<String, dynamic>>[];
      final manualHoldingsMap = <int, double>{};
      final walletHoldingsMap = <int, double>{};
      
      // Add watchlist tokens
      for (final token in watchlistTokens) {
        double manualHoldings = token.holdings ?? 0;
        double walletBalance = walletHoldings?[token.id] ?? 0;
        double totalHoldings = manualHoldings + walletBalance;
        
        manualHoldingsMap[token.id] = manualHoldings;
        walletHoldingsMap[token.id] = walletBalance;
        
        print('${token.symbol} (id=${token.id}): manual=$manualHoldings + wallet=$walletBalance = total=$totalHoldings');
        
        tokenListForApi.add({
          'token_id': token.id,
          'price': token.currentPrice,
          'holdings': totalHoldings,
          'exchange': token.exchange,
        });
      }
      
      // Add wallet-only tokens (only those with balance > 0)
      for (final tokenId in walletOnlyTokenIds) {
        final walletBalance = walletHoldings![tokenId]!;
        manualHoldingsMap[tokenId] = 0;
        walletHoldingsMap[tokenId] = walletBalance;
        
        print('Wallet-only token (id=$tokenId): wallet=$walletBalance');
        
        tokenListForApi.add({
          'token_id': tokenId,
          'price': 0, // Will be fetched from API
          'holdings': walletBalance,
          'exchange': null,
        });
      }
      
      if (tokenListForApi.isEmpty) {
        return PortfolioData(
          totalValue: 0,
          totalChange24h: 0,
          percentChange24h: 0,
          tokens: [],
          lastUpdated: DateTime.now(),
        );
      }
      
      // Fetch latest prices from API
      final apiResponse = await _apiService.getPortfolioData(tokenListForApi);
      
      print('API Response: ${apiResponse.length} tokens returned');
      
      // If API returns empty response, use cached data with saved tokens
      if (apiResponse.isEmpty) {
        print('Warning: API returned empty response for tokens');
        return PortfolioData(
          totalValue: 0,
          totalChange24h: 0,
          percentChange24h: 0,
          tokens: watchlistTokens,
          lastUpdated: DateTime.now(),
        );
      }
      
      // Convert API response to Token objects
      final tokens = <Token>[];
      
      // Create a map of saved tokens for quick lookup
      final savedTokenMap = <int, Token>{};
      for (final token in watchlistTokens) {
        savedTokenMap[token.id] = token;
      }
      
      for (final apiData in apiResponse) {
        final tokenId = apiData['token_id'] ?? apiData['id'];
        
        final manualHoldings = manualHoldingsMap[tokenId] ?? 0.0;
        final walletBalance = walletHoldingsMap[tokenId] ?? 0.0;
        final totalHoldings = manualHoldings + walletBalance;
        
        // Find the matching saved token (may be null for wallet-only tokens)
        final savedToken = savedTokenMap[tokenId];
        
        print('Creating token (id=$tokenId) with manual=$manualHoldings, wallet=$walletBalance, total=$totalHoldings');
        
        // Create token from API response with separate holdings
        final token = Token.fromApiResponse({
          ...apiData,
          'holdings': totalHoldings,
          'manual_holdings': manualHoldings,
          'wallet_holdings': walletBalance,
          'exchange': savedToken?.exchange ?? apiData['exchange'],
          'ticker': apiData['ticker'] ?? savedToken?.symbol ?? '',
          'name': apiData['name'] ?? savedToken?.name ?? '',
          'logo': apiData['logo'] ?? savedToken?.logo,
        });
        
        // Only add tokens that have valid data
        if (token.symbol.isNotEmpty && token.name.isNotEmpty) {
          tokens.add(token);
        } else {
          print('Warning: Skipping token with empty symbol/name');
        }
      }
      
      // Check if any saved tokens were not returned by the API
      for (final savedToken in watchlistTokens) {
        final hasToken = tokens.any((t) => t.id == savedToken.id);
        if (!hasToken) {
          print('Warning: Token ${savedToken.symbol} (ID: ${savedToken.id}) was not returned by API');
          tokens.add(savedToken);
        }
      }
      
      print('Final token count: ${tokens.length}');
      
      // Calculate portfolio totals
      double totalValue = 0;
      double totalChange24h = 0;
      
      for (final token in tokens) {
        if (token.holdings != null && token.holdings! > 0) {
          totalValue += token.totalValue;
          final previousValue = token.totalValue / (1 + (token.percentChange24h / 100));
          totalChange24h += token.totalValue - previousValue;
        }
      }
      
      final percentChange = totalValue > 0 ? (totalChange24h / (totalValue - totalChange24h)) * 100 : 0.0;
      
      final portfolioData = PortfolioData(
        totalValue: totalValue,
        totalChange24h: totalChange24h,
        percentChange24h: percentChange,
        tokens: tokens,
        lastUpdated: DateTime.now(),
      );
      
      // Cache the data
      await _localStorage.cachePortfolioData(portfolioData);
      
      return portfolioData;
    } catch (e) {
      print('Error in getPortfolioData: $e');
      final cached = await _localStorage.getCachedPortfolioData();
      if (cached != null) {
        return cached;
      }
      throw e;
    }
  }
  
  Future<List<Token>> searchTokens(String query) async {
    if (query.isEmpty) return [];
    
    final searchResults = await _apiService.searchTokens(query);
    
    return searchResults.map((data) {
      final fullName = data['name'] ?? '';
      String name = fullName;
      String symbol = '';
      
      final lastParenMatch = RegExp(r'(.+)\s*\(([^)]+)\)$').firstMatch(fullName);
      if (lastParenMatch != null) {
        name = lastParenMatch.group(1)!.trim();
        symbol = lastParenMatch.group(2)!.trim();
      }
      
      return Token(
        id: data['id'],
        symbol: symbol,
        name: name,
        logo: data['logo'],
        currentPrice: 0,
        priceChange24h: 0,
        percentChange24h: 0,
        marketCap: (data['market_cap'] as num?)?.toDouble(),
      );
    }).toList();
  }
  
  Future<void> addToken(Token token) async {
    await _localStorage.addToken(token);
  }
  
  Future<void> removeToken(int tokenId) async {
    await _localStorage.removeToken(tokenId);
  }
  
  Future<void> updateHoldings(int tokenId, double holdings) async {
    print('updateHoldings called: tokenId=$tokenId, holdings=$holdings');
    await _localStorage.updateTokenHoldings(tokenId, holdings);
  }
}