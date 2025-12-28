// lib/presentation/providers/wallet_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/wallet.dart';
import '../../data/repositories/wallet_repository.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repository = WalletRepository();

  List<Wallet> _wallets = [];
  bool _isLoading = false;
  String? _error;

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  WalletProvider() {
    loadWallets();
  }

  Future<void> loadWallets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _repository.getWallets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWalletBalances() async {
    _error = null;

    try {
      _wallets = await _repository.refreshAllWalletBalances();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addWallet(String address, String chain, {String? name}) async {
    try {
      await _repository.addWallet(address, chain, name: name);
      await loadWallets();
      
      // Fetch balance for the new wallet
      final newWallet = _wallets.firstWhere(
        (w) => w.address == address && w.chain == chain,
      );
      await _repository.fetchWalletBalance(newWallet);
      await loadWallets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeWallet(String address, String chain) async {
    try {
      await _repository.removeWallet(address, chain);
      await loadWallets();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get aggregated holdings by token ID
  Future<Map<int, double>> getWalletHoldingsByTokenId() async {
    return await _repository.getWalletHoldingsByTokenId();
  }

  /// Get wallets that hold a specific token by token ID
  List<Wallet> getWalletsForToken(int tokenId) {
    return _repository.getWalletsForToken(_wallets, tokenId);
  }
  
  /// Get balance of a specific token across all wallets
  double getTokenBalanceFromWallets(int tokenId) {
    return _repository.getTokenBalanceFromWallets(_wallets, tokenId);
  }
}