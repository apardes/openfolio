// lib/presentation/screens/token_detail/token_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../data/models/token.dart';
import '../../providers/portfolio_provider.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
        currentHoldings: token.holdings ?? 0,
        onSave: (holdings) async {
          await context.read<PortfolioProvider>().updateHoldings(token.id, holdings);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        onDelete: () async {
          await context.read<PortfolioProvider>().removeToken(token.id);
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog only
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final token = provider.getTokenById(widget.tokenId);
        
        if (token == null) {
          // Token has been deleted, pop back to portfolio
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

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CryptoLogo(
                  logoUrl: token.logo,
                  symbol: token.symbol,
                  size: 28,
                  borderRadius: 14,
                ),
                const SizedBox(width: 8),
                Text(token.name),
                if (token.exchange != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${token.exchange})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
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
                    await provider.removeToken(token.id);
                    // Don't need to pop here as the Consumer will handle it
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Tab Bar
              Container(
                color: AppTheme.surface,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Alerts'),
                    Tab(text: 'Holdings'),
                  ],
                ),
              ),
              
              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Details Tab
                    ListView(
                      children: [
                        // Price Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: AppTheme.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                token.exchange ?? 'Global Average',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    PriceFormatter.formatPrice(token.currentPrice),
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: changeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          PriceFormatter.formatPercentage(token.percentChange24h),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: changeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                          color: changeColor,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Time Range Selector
                        Container(
                          height: 48,
                          color: AppTheme.surface,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _timeRanges.length,
                            itemBuilder: (context, index) {
                              final range = _timeRanges.entries.elementAt(index);
                              final isSelected = range.value == _selectedTimeRange;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ChoiceChip(
                                  label: Text(range.key),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedTimeRange = range.value;
                                    });
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
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Price Chart
                        PriceChart(
                          token: token,
                          timeRange: _selectedTimeRange,
                          height: 300,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Market Stats
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
                                    // Market Cap
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.trending_up,
                                              size: 20,
                                              color: AppTheme.muted,
                                            ),
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
                                    const SizedBox(height: 16),
                                    Divider(
                                      color: AppTheme.muted.withOpacity(0.1),
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 16),
                                    // 24h Volume
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.bar_chart,
                                              size: 20,
                                              color: AppTheme.muted,
                                            ),
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
                                          token.volume24h != null 
                                              ? PriceFormatter.formatCompactPrice(token.volume24h!)
                                              : 'N/A',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (token.volumeChange24h != null) ...[
                                      const SizedBox(height: 16),
                                      Divider(
                                        color: AppTheme.muted.withOpacity(0.1),
                                        thickness: 1,
                                      ),
                                      const SizedBox(height: 16),
                                      // 24h Volume Change
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.change_history,
                                                size: 20,
                                                color: AppTheme.muted,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Volume Change',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppTheme.muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                PriceFormatter.formatPercentage(token.volumeChange24h!),
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: token.volumeChange24h! >= 0 
                                                      ? AppTheme.success 
                                                      : AppTheme.error,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                token.volumeChange24h! >= 0 
                                                    ? Icons.arrow_upward 
                                                    : Icons.arrow_downward,
                                                color: token.volumeChange24h! >= 0 
                                                    ? AppTheme.success 
                                                    : AppTheme.error,
                                                size: 16,
                                              ),
                                            ],
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
                        
                        // Holdings Section
                        if (token.holdings != null && token.holdings! > 0) ...[
                          const Divider(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Holdings',
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
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total Value',
                                                style: Theme.of(context).textTheme.labelSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                PriceFormatter.formatPrice(token.totalValue),
                                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                                  color: AppTheme.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Quantity',
                                                style: Theme.of(context).textTheme.labelSmall,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${PriceFormatter.formatHoldings(token.holdings!)} ${token.symbol}',
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Bottom padding
                        const SizedBox(height: 80),
                      ],
                    ),
                    
                    // Alerts Tab - Placeholder
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: AppTheme.muted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Price Alerts',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Get notified when ${token.symbol} reaches your target price',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement alerts
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Alert'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surface,
                              foregroundColor: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Holdings Tab
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (token.holdings == null || token.holdings == 0) ...[
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: AppTheme.muted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No holdings',
                                style: Theme.of(context).textTheme.displayMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add ${token.symbol} to your portfolio',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.muted,
                                ),
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
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      size: 48,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Current Holdings',
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      PriceFormatter.formatHoldings(token.holdings!),
                                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        fontSize: 36,
                                      ),
                                    ),
                                    Text(
                                      token.symbol,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: AppTheme.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Divider(
                                      color: AppTheme.muted.withOpacity(0.2),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Value',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                        Text(
                                          PriceFormatter.formatPrice(token.totalValue),
                                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Current Price',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.muted,
                                          ),
                                        ),
                                        Text(
                                          PriceFormatter.formatPrice(token.currentPrice),
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _showEditHoldingsDialog(token),
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Holdings'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: AppTheme.background,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}