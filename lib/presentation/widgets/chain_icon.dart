// lib/presentation/widgets/chain_icon.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ChainIcon extends StatelessWidget {
  final String chain;
  final double size;
  final double iconSize;
  final double borderRadius;

  const ChainIcon({
    super.key,
    required this.chain,
    this.size = 44,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final chainUpper = chain.toUpperCase();
    final backgroundColor = _getBackgroundColor(chainUpper);
    final pngAsset = _getPngAsset(chainUpper);

    return Container(
      width: size,
      height: size,
      child: Center(
        child: pngAsset != null
            ? Image.asset(
                pngAsset,
                width: iconSize,
                height: iconSize,
              )
            : Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primary,
                size: iconSize,
              ),
      ),
    );
  }

  String? _getPngAsset(String chain) {
    switch (chain) {
      case 'BTC':
        return 'assets/icons/btc.png';
      case 'ETH':
        return 'assets/icons/eth.png';
      case 'SOL':
        return 'assets/icons/sol.png';
      default:
        return null;
    }
  }

  Color _getBackgroundColor(String chain) {
    switch (chain) {
      case 'BTC':
        return const Color(0xFFF7931A);
      case 'ETH':
        return const Color(0xFF627EEA);
      case 'SOL':
        return const Color(0xFF9945FF);
      default:
        return AppTheme.primary;
    }
  }
}