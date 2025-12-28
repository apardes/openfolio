// lib/data/repositories/wallet_repository.dart

import '../models/wallet.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class WalletRepository {
  final LocalStorageService _localStorage = LocalStorageService();
  final ApiService _apiService = ApiService();

  Future<List<Wallet>> getWallets() async {
    return await _localStorage.getWallets();
  }

  Future<void> addWallet(String address, String chain, {String? name}) async {
    final wallet = Wallet(
      address: address,
      chain: chain,
      name: name,
    );
    await _localStorage.addWallet(wallet);
  }

  Future<void> removeWallet(String address, String chain) async {
    await _localStorage.removeWallet(address, chain);
  }

  Future<Wallet?> fetchWalletBalance(Wallet wallet) async {
    try {
      final balanceData = await _apiService.getWalletBalance(
        wallet.address,
        wallet.chain,
      );

      if (balanceData != null) {
        print('Wallet API response for ${wallet.chain}: $balanceData');
        
        final updatedWallet = Wallet.fromApiResponse(
          balanceData,
          wallet.address,
          wallet.chain,
        ).copyWith(name: wallet.name);

        print('Updated wallet native balance: ${updatedWallet.nativeBalance}');
        print('Updated wallet token_id: ${updatedWallet.tokenId}');
        print('Updated wallet tokens: ${updatedWallet.tokens.length}');
        for (final t in updatedWallet.tokens) {
          print('  - ${t.ticker} (id=${t.tokenId}): ${t.balance}');
        }

        await _localStorage.updateWallet(updatedWallet);
        return updatedWallet;
      }
      return wallet;
    } catch (e) {
      print('Error fetching wallet balance: $e');
      return wallet;
    }
  }

  Future<List<Wallet>> refreshAllWalletBalances() async {
    final wallets = await getWallets();
    final updatedWallets = <Wallet>[];

    for (final wallet in wallets) {
      final updated = await fetchWalletBalance(wallet);
      if (updated != null) {
        updatedWallets.add(updated);
      }
    }

    return updatedWallets;
  }

  /// Get aggregated holdings from all wallets by token ID
  /// Returns a map of token_id -> total balance
  Future<Map<int, double>> getWalletHoldingsByTokenId() async {
    final wallets = await getWallets();
    final holdings = <int, double>{}; 

    print('=== Aggregating wallet holdings by token ID ===');
    print('Total wallets: ${wallets.length}');

    for (final wallet in wallets) {
      print('Wallet ${wallet.displayName} (${wallet.chain}):');
      
      // Native balance
      if (wallet.tokenId != null) {
        print('  Native ${wallet.chainSymbol} (id=${wallet.tokenId}): ${wallet.totalNativeBalance}');
        holdings[wallet.tokenId!] = (holdings[wallet.tokenId!] ?? 0) + wallet.totalNativeBalance;
      }
      
      // Token balances
      for (final token in wallet.tokens) {
        if (token.tokenId != null) {
          print('  ${token.ticker} (id=${token.tokenId}): ${token.balance}');
          holdings[token.tokenId!] = (holdings[token.tokenId!] ?? 0) + token.balance;
        }
      }
    }

    print('=== Final wallet holdings map ===');
    holdings.forEach((tokenId, balance) {
      print('  Token ID $tokenId: $balance');
    });

    return holdings;
  }

  /// Get wallets that hold a specific token by token ID
  List<Wallet> getWalletsForToken(List<Wallet> wallets, int tokenId) {
    return wallets.where((wallet) {
      // Check native balance
      if (wallet.tokenId == tokenId) return true;
      // Check tokens
      return wallet.tokens.any((t) => t.tokenId == tokenId);
    }).toList();
  }
  
  /// Get the balance of a specific token across all wallets
  double getTokenBalanceFromWallets(List<Wallet> wallets, int tokenId) {
    double total = 0;
    for (final wallet in wallets) {
      // Check native balance
      if (wallet.tokenId == tokenId) {
        total += wallet.totalNativeBalance;
      }
      // Check tokens
      for (final token in wallet.tokens) {
        if (token.tokenId == tokenId) {
          total += token.balance;
        }
      }
    }
    return total;
  }
}