// lib/presentation/widgets/crypto_logo.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';

class CryptoLogo extends StatelessWidget {
  final String? logoUrl;
  final String symbol;
  final double size;
  final double borderRadius;

  const CryptoLogo({
    super.key,
    this.logoUrl,
    required this.symbol,
    this.size = 40,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: AppTheme.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(
            imageUrl: logoUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(context),
            errorWidget: (context, url, error) => _buildPlaceholder(context),
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            memCacheWidth: (size * 2).toInt(),
            memCacheHeight: (size * 2).toInt(),
            maxWidthDiskCache: (size * 2).toInt(),
            maxHeightDiskCache: (size * 2).toInt(),
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    }
    
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.muted.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          symbol.isNotEmpty ? symbol.substring(0, 1).toUpperCase() : '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}