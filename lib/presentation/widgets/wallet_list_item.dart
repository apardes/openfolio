// lib/presentation/widgets/wallet_list_item.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/wallet.dart';

class WalletListItem extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const WalletListItem({
    super.key,
    required this.wallet,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.muted.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildChainIcon(),
        title: Text(
          wallet.displayName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _truncateAddress(wallet.address),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.muted,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatBalance(wallet.totalNativeBalance)} ${wallet.chainSymbol}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (wallet.stakeBalance != null && wallet.stakeBalance! > 0)
                  Text(
                    '${_formatBalance(wallet.stakeBalance!)} staked',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.muted,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChainIcon() {
    IconData iconData;
    Color iconColor;

    switch (wallet.chain.toUpperCase()) {
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
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
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