// lib/presentation/screens/search/add_holdings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/comma_text_input_formatter.dart';
import '../../../data/models/token.dart';

class AddHoldingsDialog extends StatefulWidget {
  final Token token;
  final Function(double holdings) onSave;

  const AddHoldingsDialog({
    super.key,
    required this.token,
    required this.onSave,
  });

  @override
  State<AddHoldingsDialog> createState() => _AddHoldingsDialogState();
}

class _AddHoldingsDialogState extends State<AddHoldingsDialog> {
  final TextEditingController _holdingsController = TextEditingController();
  final FocusNode _holdingsFocus = FocusNode();
  bool _addToWatchlistOnly = false;

  @override
  void initState() {
    super.initState();
    _holdingsFocus.requestFocus();
  }

  @override
  void dispose() {
    _holdingsController.dispose();
    _holdingsFocus.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_addToWatchlistOnly) {
      widget.onSave(0);
    } else {
      final holdings = CommaTextInputFormatter.parseValue(_holdingsController.text);
      if (holdings != null && holdings > 0) {
        widget.onSave(holdings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add ${widget.token.symbol}',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.token.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Holdings Input
            if (!_addToWatchlistOnly) ...[
              Text(
                'Holdings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _holdingsController,
                focusNode: _holdingsFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  CommaTextInputFormatter(),
                ],
                style: Theme.of(context).textTheme.displayMedium,
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to update button state
                },
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: AppTheme.muted),
                  suffix: Text(
                    widget.token.symbol,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.muted,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Watchlist Only Checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _addToWatchlistOnly = !_addToWatchlistOnly;
                });
              },
              child: Row(
                children: [
                  Checkbox(
                    value: _addToWatchlistOnly,
                    onChanged: (value) {
                      setState(() {
                        _addToWatchlistOnly = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primary,
                  ),
                  Text(
                    'Add to watchlist only',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addToWatchlistOnly || _holdingsController.text.isNotEmpty
                        ? _onSave
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}