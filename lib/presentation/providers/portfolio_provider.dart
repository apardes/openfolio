// lib/presentation/providers/portfolio_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/portfolio_data.dart';
import '../../data/models/token.dart';
import '../../data/repositories/portfolio_repository.dart';

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository = PortfolioRepository();
  
  PortfolioData? _portfolioData;
  bool _isLoading = false;
  String? _error;
  List<Token> _searchResults = [];
  bool _isSearching = false;

  PortfolioData? get portfolioData => _portfolioData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Token> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  
  List<Token> get tokensWithHoldings {
    final tokens = _portfolioData?.tokens
        .where((t) => t.holdings != null && t.holdings! > 0)
        .toList() ?? [];
    
    // Sort by holding value (descending)
    tokens.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    
    return tokens;
  }
  
  List<Token> get watchlistTokens {
    final tokens = _portfolioData?.tokens
        .where((t) => t.holdings == null || t.holdings == 0)
        .toList() ?? [];
    
    // Sort by market cap (descending), with null values at the end
    tokens.sort((a, b) {
      if (a.marketCap == null && b.marketCap == null) return 0;
      if (a.marketCap == null) return 1;
      if (b.marketCap == null) return -1;
      return b.marketCap!.compareTo(a.marketCap!);
    });
    
    return tokens;
  }

  PortfolioProvider() {
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _portfolioData = await _repository.getPortfolioData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPortfolio() async {
    try {
      _portfolioData = await _repository.getPortfolioData();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchTokens(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      _searchResults = await _repository.searchTokens(query);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> addToken(Token token) async {
    try {
      await _repository.addToken(token);
      // Refresh portfolio data after adding a token
      await refreshPortfolio();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeToken(int tokenId) async {
    try {
      await _repository.removeToken(tokenId);
      await loadPortfolio();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateHoldings(int tokenId, double holdings) async {
    try {
      await _repository.updateHoldings(tokenId, holdings);
      // Refresh portfolio data after updating holdings
      await refreshPortfolio();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Token? getTokenById(int tokenId) {
    try {
      return _portfolioData?.tokens.firstWhere(
        (token) => token.id == tokenId,
      );
    } catch (e) {
      return null;
    }
  }
}