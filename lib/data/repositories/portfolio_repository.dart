// lib/data/repositories/portfolio_repository.dart

import '../models/token.dart';
import '../models/portfolio_data.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';

class PortfolioRepository {
  final LocalStorageService _localStorage = LocalStorageService();
  final ApiService _apiService = ApiService();
  
  Future<PortfolioData> getPortfolioData() async {
    try {
      // Get watchlist from local storage
      final watchlistTokens = await _localStorage.getWatchlist();
      
      if (watchlistTokens.isEmpty) {
        // Return empty portfolio if no tokens
        return PortfolioData(
          totalValue: 0,
          totalChange24h: 0,
          percentChange24h: 0,
          tokens: [],
          lastUpdated: DateTime.now(),
        );
      }
      
      // Prepare token list for API - include current price from saved data
      final tokenListForApi = watchlistTokens.map((token) {
        // Make sure we have the required fields for the API
        return {
          'token_id': token.id,
          'price': token.currentPrice,
          'holdings': token.holdings ?? 0,
          'exchange': token.exchange,
        };
      }).toList();
      
      print('Sending to API: ${tokenListForApi.length} tokens');
      for (var token in tokenListForApi) {
        print('Token: id=${token['token_id']}, holdings=${token['holdings']}');
      }
      
      // Fetch latest prices from API
      final apiResponse = await _apiService.getPortfolioData(tokenListForApi);
      
      print('API Response: ${apiResponse.length} tokens returned');
      
      // If API returns empty response, use cached data with saved tokens
      if (apiResponse.isEmpty) {
        print('Warning: API returned empty response for tokens');
        // Return portfolio with saved tokens but no updated prices
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
        print('Processing API response for token ID: $tokenId');
        
        // Find the matching saved token
        final savedToken = savedTokenMap[tokenId];
        
        if (savedToken == null) {
          print('Warning: No saved token found for ID $tokenId, skipping...');
          continue;
        }
        
        // Create token from API response, preserving local holdings and saved data
        final token = Token.fromApiResponse({
          ...apiData,
          'holdings': savedToken.holdings ?? apiData['holdings'],
          'exchange': savedToken.exchange ?? apiData['exchange'],
          // Ensure we preserve the symbol and name from saved token if API doesn't provide them
          'ticker': apiData['ticker'] ?? savedToken.symbol,
          'name': apiData['name'] ?? savedToken.name,
          // Preserve logo from saved token if API doesn't provide it
          'logo': apiData['logo'] ?? savedToken.logo,
        });
        
        // Only add tokens that have valid data
        if (token.symbol.isNotEmpty && token.name.isNotEmpty) {
          tokens.add(token);
          print('Added token: ${token.symbol} (${token.name})');
        } else {
          print('Warning: Skipping token with empty symbol/name');
        }
      }
      
      // Check if any saved tokens were not returned by the API
      for (final savedToken in watchlistTokens) {
        final hasToken = tokens.any((t) => t.id == savedToken.id);
        if (!hasToken) {
          print('Warning: Token ${savedToken.symbol} (ID: ${savedToken.id}) was not returned by API');
          // Add the saved token with its saved data (prices might be outdated)
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
          // Calculate the change in value based on percentage change
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
      // If API fails, try to return cached data
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
    
    // Convert search results to Token objects
    return searchResults.map((data) {
      // Parse name to extract symbol - format is "Billy (Bitcoin) (BILLY)"
      // The last part in parentheses is the symbol
      final fullName = data['name'] ?? '';
      String name = fullName;
      String symbol = '';
      
      // Use regex to extract the last parentheses content as symbol
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
        currentPrice: 0, // Will be fetched when added to portfolio
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
    await _localStorage.updateTokenHoldings(tokenId, holdings);
  }
}