// lib/presentation/screens/token_detail/edit_holdings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/comma_text_input_formatter.dart';
import '../../../data/models/token.dart';

class EditHoldingsDialog extends StatefulWidget {
  final Token token;
  final double currentHoldings;
  final Function(double holdings) onSave;
  final VoidCallback onDelete;

  const EditHoldingsDialog({
    super.key,
    required this.token,
    required this.currentHoldings,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<EditHoldingsDialog> createState() => _EditHoldingsDialogState();
}

class _EditHoldingsDialogState extends State<EditHoldingsDialog> {
  late TextEditingController _holdingsController;
  final FocusNode _holdingsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Format the initial value with commas
    String initialValue = '';
    if (widget.currentHoldings > 0) {
      // Convert to string and format
      initialValue = _formatNumberWithCommas(widget.currentHoldings);
    }
    
    _holdingsController = TextEditingController(text: initialValue);
    _holdingsFocus.requestFocus();
    
    // Select all text when dialog opens
    _holdingsController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _holdingsController.text.length,
    );
  }
  
  String _formatNumberWithCommas(double value) {
    String stringValue = value.toString();
    
    // Check if it has decimals
    if (stringValue.contains('.')) {
      // Remove trailing zeros after decimal point
      stringValue = stringValue.replaceAll(RegExp(r'\.0+$'), '');
      
      // If still has decimal, format both parts
      if (stringValue.contains('.')) {
        final parts = stringValue.split('.');
        final integerPart = parts[0];
        final decimalPart = parts[1];
        
        // Format integer part with commas
        String formattedInteger = '';
        int digitCount = 0;
        for (int i = integerPart.length - 1; i >= 0; i--) {
          if (digitCount == 3) {
            formattedInteger = ',' + formattedInteger;
            digitCount = 0;
          }
          formattedInteger = integerPart[i] + formattedInteger;
          digitCount++;
        }
        
        return '$formattedInteger.$decimalPart';
      }
    }
    
    // Format integer part only
    String formattedInteger = '';
    int digitCount = 0;
    for (int i = stringValue.length - 1; i >= 0; i--) {
      if (digitCount == 3) {
        formattedInteger = ',' + formattedInteger;
        digitCount = 0;
      }
      formattedInteger = stringValue[i] + formattedInteger;
      digitCount++;
    }
    
    return formattedInteger;
  }

  @override
  void dispose() {
    _holdingsController.dispose();
    _holdingsFocus.dispose();
    super.dispose();
  }

  void _onSave() {
    final holdings = CommaTextInputFormatter.parseValue(_holdingsController.text) ?? 0;
    widget.onSave(holdings);
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
                        'Edit ${widget.token.symbol} Holdings',
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
                setState(() {}); // Update button state
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
            const SizedBox(height: 8),
            Text(
              'Enter 0 to move to watchlist only',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                // Delete Button
                if (widget.currentHoldings > 0 || 
                    (_holdingsController.text.isNotEmpty && 
                     CommaTextInputFormatter.parseValue(_holdingsController.text) == 0))
                  Expanded(
                    child: TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                
                if (widget.currentHoldings > 0) const SizedBox(width: 16),
                
                // Save Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _holdingsController.text.isNotEmpty ? _onSave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save',
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