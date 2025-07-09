// lib/presentation/widgets/portfolio_header.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/price_formatter.dart';

class PortfolioHeader extends StatelessWidget {
  final double totalValue;
  final double percentChange24h;
  final double totalChange24h;

  const PortfolioHeader({
    super.key,
    required this.totalValue,
    required this.percentChange24h,
    required this.totalChange24h,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = percentChange24h >= 0;
    final changeColor = isPositive ? AppTheme.success : AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Portfolio Value Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Portfolio Value',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.3,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                PriceFormatter.formatPrice(totalValue),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
          
          // 24hr Change Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '24hr Change',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.3,
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    PriceFormatter.formatPercentage(percentChange24h),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: changeColor,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}