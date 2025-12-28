// lib/presentation/screens/token_detail/token_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/models/token.dart';
import '../../../data/models/wallet.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/crypto_logo.dart';
import 'edit_holdings_dialog.dart';

class TokenDetailScreen extends StatefulWidget {
  final int tokenId;

  const TokenDetailScreen({
    super.key,
    required this.tokenId,
  });

  @override
  State<TokenDetailScreen> createState() => _TokenDetailScreenState();
}

class _TokenDetailScreenState extends State<TokenDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChartTimeRange _selectedTimeRange = ChartTimeRange.day;
  
  final Map<String, ChartTimeRange> _timeRanges = {
    '1D': ChartTimeRange.day,
    '7D': ChartTimeRange.week,
    '30D': ChartTimeRange.month,
    'All': ChartTimeRange.all,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditHoldingsDialog(Token token) {
    showDialog(
      context: context,
      builder: (context) => EditHoldingsDialog(
        token: token,
        currentHoldings: token.manualHoldings,
        onSave: (holdings) async {
          await context.read<PortfolioProvider>().updateHoldings(token.id, holdings);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        onDelete: () async {
          await context.read<PortfolioProvider>().removeToken(token.id);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PortfolioProvider, WalletProvider>(
      builder: (context, portfolioProvider, walletProvider, child) {
        final token = portfolioProvider.getTokenById(widget.tokenId);
        
        if (token == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isPositive = token.percentChange24h >= 0;
        final changeColor = isPositive ? AppTheme.success : AppTheme.error;
        
        // Get wallets that hold this token
        final walletsForToken = walletProvider.getWalletsForToken(token.id);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            title: Row(
              children: [
                CryptoLogo(
                  logoUrl: token.logo,
                  symbol: token.symbol,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token.symbol,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text(
                      token.name,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'remove') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppTheme.surface,
                        title: const Text('Remove Token'),
                        content: Text('Remove ${token.symbol} from your portfolio?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.error,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && mounted) {
                      await portfolioProvider.removeToken(token.id);
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppTheme.error),
                        SizedBox(width: 8),
                        Text('Remove'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: AppTheme.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Alerts'),
                    Tab(text: 'Holdings'),
                    Tab(text: 'Wallets'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDetailsTab(token, isPositive, changeColor),
                    _buildAlertsTab(token),
                    _buildHoldingsTab(token),
                    _buildWalletsTab(token, walletsForToken),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailsTab(Token token, bool isPositive, Color changeColor) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                token.exchange ?? 'Portfolio',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    PriceFormatter.formatPrice(token.currentPrice),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: changeColor,
                          size: 16,
                        ),
                        Text(
                          '${isPositive ? '+' : ''}${token.percentChange24h.toStringAsFixed(2)}%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: _timeRanges.entries.map((entry) {
              final isSelected = _selectedTimeRange == entry.value;
              return ChoiceChip(
                label: Text(entry.key),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTimeRange = entry.value);
                  }
                },
                selectedColor: AppTheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.muted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                backgroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : AppTheme.muted.withOpacity(0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        PriceChart(
          token: token,
          timeRange: _selectedTimeRange,
          height: 300,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Stats',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.muted.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up, size: 20, color: AppTheme.muted),
                            const SizedBox(width: 8),
                            Text(
                              'Market Cap',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          token.marketCap != null 
                              ? PriceFormatter.formatCompactPrice(token.marketCap!)
                              : 'N/A',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (token.volume24h != null) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart, size: 20, color: AppTheme.muted),
                              const SizedBox(width: 8),
                              Text(
                                '24h Volume',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            PriceFormatter.formatCompactPrice(token.volume24h!),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
  
  Widget _buildAlertsTab(Token token) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: AppTheme.muted),
          const SizedBox(height: 16),
          Text('Price Alerts', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Get notified when ${token.symbol} reaches your target price',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Create Alert'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHoldingsTab(Token token) {
    final hasAnyHoldings = token.holdings != null && token.holdings! > 0;
    final hasManualHoldings = token.manualHoldings > 0;
    final hasWalletHoldings = token.walletHoldings > 0;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!hasAnyHoldings) ...[
              const SizedBox(height: 48),
              Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.muted),
              const SizedBox(height: 16),
              Text('No holdings', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Add ${token.symbol} to your portfolio',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showEditHoldingsDialog(token),
                icon: const Icon(Icons.add),
                label: const Text('Add Holdings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.primary,
                ),
              ),
            ] else ...[
              // Total Holdings Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 48, color: AppTheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Total Holdings',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${PriceFormatter.formatHoldings(token.holdings!)} ${token.symbol}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PriceFormatter.formatPrice(token.totalValue),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Holdings Breakdown
              if (hasManualHoldings || hasWalletHoldings) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Breakdown',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Manual Holdings Row
                      _buildHoldingsBreakdownRow(
                        icon: Icons.edit_note,
                        iconColor: AppTheme.primary,
                        label: 'Manual',
                        value: token.manualHoldings,
                        symbol: token.symbol,
                        price: token.currentPrice,
                        isEditable: true,
                        onEdit: () => _showEditHoldingsDialog(token),
                      ),
                      
                      if (hasWalletHoldings) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1),
                        ),
                        
                        // Wallet Holdings Row
                        _buildHoldingsBreakdownRow(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: const Color(0xFF9945FF),
                          label: 'Tracked Wallets',
                          value: token.walletHoldings,
                          symbol: token.symbol,
                          price: token.currentPrice,
                          isEditable: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Edit Manual Holdings Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditHoldingsDialog(token),
                  icon: const Icon(Icons.edit),
                  label: Text(hasManualHoldings ? 'Edit Manual Holdings' : 'Add Manual Holdings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildHoldingsBreakdownRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double value,
    required String symbol,
    required double price,
    required bool isEditable,
    VoidCallback? onEdit,
  }) {
    final valueUsd = value * price;
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${PriceFormatter.formatHoldings(value)} $symbol',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              PriceFormatter.formatPrice(valueUsd),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
              ),
            ),
            if (isEditable && onEdit != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  'Edit',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Widget _buildWalletsTab(Token token, List<Wallet> walletsForToken) {
    if (walletsForToken.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.muted),
            const SizedBox(height: 16),
            Text('No Wallets', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'No wallets holding ${token.symbol} are being tracked',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add wallets from the main screen',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: walletsForToken.length,
      itemBuilder: (context, index) {
        final wallet = walletsForToken[index];
        
        // Get balance for this token
        double balance = 0;
        if (wallet.tokenId == token.id) {
          balance = wallet.totalNativeBalance;
        } else {
          final walletToken = wallet.tokens.where((t) => t.tokenId == token.id).firstOrNull;
          if (walletToken != null) {
            balance = walletToken.balance;
          }
        }
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.muted.withOpacity(0.1), width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildChainIcon(wallet.chain),
            title: Text(
              wallet.displayName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _truncateAddress(wallet.address),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            trailing: Text(
              '${_formatBalance(balance)} ${token.symbol}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildChainIcon(String chain) {
    IconData iconData;
    Color iconColor;

    switch (chain.toUpperCase()) {
      case 'BTC':
        iconData = Icons.currency_bitcoin;
        iconColor = const Color(0xFFF7931A);
        break;
      case 'ETH':
        iconData = Icons.diamond_outlined;
        iconColor = const Color(0xFF627EEA);
        break;
      case 'SOL':
        iconData = Icons.circle;
        iconColor = const Color(0xFF9945FF);
        break;
      default:
        iconData = Icons.account_balance_wallet;
        iconColor = AppTheme.primary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }
  
  String _truncateAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }
  
  String _formatBalance(double balance) {
    if (balance == 0) return '0';
    if (balance < 0.0001) return '<0.0001';
    if (balance < 1) return balance.toStringAsFixed(4);
    if (balance < 1000) return balance.toStringAsFixed(2);
    return balance.toStringAsFixed(2);
  }
}