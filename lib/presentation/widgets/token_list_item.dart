// lib/presentation/widgets/token_list_item.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/price_formatter.dart';
import '../../data/models/token.dart';
import 'crypto_logo.dart';

class TokenListItem extends StatelessWidget {
  final Token token;
  final bool showHoldings;
  final VoidCallback onTap;
  final VoidCallback onAlertTap;

  const TokenListItem({
    super.key,
    required this.token,
    required this.showHoldings,
    required this.onTap,
    required this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = token.percentChange24h >= 0;
    final changeColor = isPositive ? AppTheme.success : AppTheme.error;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // Coin column - Logo and Symbol
            SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Token Logo
                  CryptoLogo(
                    logoUrl: token.logo,
                    symbol: token.symbol,
                    size: 24,
                    borderRadius: 12,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    token.symbol,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Holdings column
            Expanded(
              child: showHoldings && token.holdings != null && token.holdings! > 0
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            PriceFormatter.formatPrice(token.totalValue),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            PriceFormatter.formatHoldings(token.holdings!),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(),
            ),
            
            // Price column
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            PriceFormatter.formatPrice(token.currentPrice),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: changeColor,
                          size: 10,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      PriceFormatter.formatPercentage(token.percentChange24h),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: changeColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Alert button
            SizedBox(
              width: 48,
              child: IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: AppTheme.muted,
                  size: 18,
                ),
                onPressed: onAlertTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}