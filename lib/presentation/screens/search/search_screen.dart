// lib/presentation/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/models/token.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/crypto_logo.dart';
import 'add_holdings_dialog.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
    
    // Clear previous search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().clearSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.length >= 2) {
      context.read<PortfolioProvider>().searchTokens(query).then((_) {
        // Preload logos for search results
        final provider = context.read<PortfolioProvider>();
        for (final token in provider.searchResults) {
          if (token.logo != null && token.logo!.isNotEmpty) {
            precacheImage(
              CachedNetworkImageProvider(token.logo!),
              context,
            );
          }
        }
      });
    } else {
      context.read<PortfolioProvider>().clearSearch();
    }
  }

  void _showAddHoldingsDialog(Token token) {
    showDialog(
      context: context,
      builder: (context) => AddHoldingsDialog(
        token: token,
        onSave: (holdings) async {
          final provider = context.read<PortfolioProvider>();
          final newToken = Token(
            id: token.id,
            symbol: token.symbol,
            name: token.name,
            logo: token.logo,
            currentPrice: token.currentPrice,
            priceChange24h: token.priceChange24h,
            percentChange24h: token.percentChange24h,
            holdings: holdings,
            marketCap: token.marketCap,
            volume24h: token.volume24h,
          );
          
          await provider.addToken(newToken);
          
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog
            Navigator.of(context).pop(); // Go back to portfolio
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Add Token'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search coins...',
                hintStyle: TextStyle(color: AppTheme.muted),
                prefixIcon: Icon(Icons.search, color: AppTheme.muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.muted),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          
          // Search Results
          Expanded(
            child: Consumer<PortfolioProvider>(
              builder: (context, provider, child) {
                if (provider.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (_searchController.text.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for a cryptocurrency',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                if (provider.searchResults.isEmpty && _searchController.text.length >= 2) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching for another coin',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final token = provider.searchResults[index];
                    final isAdded = provider.portfolioData?.tokens
                        .any((t) => t.id == token.id) ?? false;
                    
                    return InkWell(
                      onTap: isAdded ? null : () => _showAddHoldingsDialog(token),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Token Logo
                            CryptoLogo(
                              logoUrl: token.logo,
                              symbol: token.symbol.isNotEmpty 
                                  ? token.symbol
                                  : token.name,
                              size: 40,
                              borderRadius: 20,
                            ),
                            const SizedBox(width: 12),
                            
                            // Token Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    token.name,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    token.symbol,
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Market Cap or Added Status
                            if (isAdded)
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Added',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              )
                            else if (token.marketCap != null)
                              Text(
                                'MCap: ${PriceFormatter.formatCompactPrice(token.marketCap!)}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}