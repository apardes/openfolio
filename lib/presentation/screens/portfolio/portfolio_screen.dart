// lib/presentation/screens/portfolio/portfolio_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/portfolio_header.dart';
import '../../widgets/token_list_item.dart';
import '../search/search_screen.dart';
import '../token_detail/token_detail_screen.dart';
import '../wallets/wallets_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Openfolio'),
        backgroundColor: AppTheme.background,
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletsScreen()),
              ).then((_) {
                // Refresh portfolio when returning from wallets
                context.read<PortfolioProvider>().refreshPortfolio();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ).then((_) {
                // Refresh portfolio when returning from search
                context.read<PortfolioProvider>().refreshPortfolio();
              });
            },
          ),
        ],
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.portfolioData == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null && provider.portfolioData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading portfolio',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: provider.loadPortfolio,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final portfolioData = provider.portfolioData;
          if (portfolioData == null || portfolioData.tokens.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Openfolio',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first token to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refreshPortfolio,
            backgroundColor: AppTheme.surface,
            color: AppTheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Portfolio Header
                SliverToBoxAdapter(
                  child: PortfolioHeader(
                    totalValue: portfolioData.totalValue,
                    percentChange24h: portfolioData.percentChange24h,
                    totalChange24h: portfolioData.totalChange24h,
                  ),
                ),
                
                // Holdings Section
                if (provider.tokensWithHoldings.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      showHoldings: true,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final token = provider.tokensWithHoldings[index];
                        return TokenListItem(
                          token: token,
                          showHoldings: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenDetailScreen(tokenId: token.id),
                              ),
                            );
                          },
                          onAlertTap: () {
                            // TODO: Show alert dialog
                          },
                        );
                      },
                      childCount: provider.tokensWithHoldings.length,
                    ),
                  ),
                ],
                
                // Watchlist Section
                if (provider.watchlistTokens.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      context,
                      showHoldings: false,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final token = provider.watchlistTokens[index];
                        return TokenListItem(
                          token: token,
                          showHoldings: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenDetailScreen(tokenId: token.id),
                              ),
                            );
                          },
                          onAlertTap: () {
                            // TODO: Show alert dialog
                          },
                        );
                      },
                      childCount: provider.watchlistTokens.length,
                    ),
                  ),
                ],
                
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required bool showHoldings}) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.surface.withOpacity(0.5),
      child: Row(
        children: [
          // Coin label - centered
          SizedBox(
            width: 60,
            child: Text(
              'Coin',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.muted,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Holdings column - right aligned
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                showHoldings ? 'Holdings' : 'Watchlist',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          
          // Price column - right aligned
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                'Price',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          
          // Alert button spacer (matches token_list_item.dart)
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}