// lib/presentation/screens/wallets/add_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/wallet_provider.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _addressFocus = FocusNode();
  String _selectedChain = 'SOL';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _chains = [
    {'id': 'BTC', 'name': 'Bitcoin', 'icon': Icons.currency_bitcoin, 'color': Color(0xFFF7931A)},
    {'id': 'ETH', 'name': 'Ethereum', 'icon': Icons.diamond_outlined, 'color': Color(0xFF627EEA)},
    {'id': 'SOL', 'name': 'Solana', 'icon': Icons.circle, 'color': Color(0xFF9945FF)},
  ];

  @override
  void initState() {
    super.initState();
    _addressFocus.requestFocus();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _addressFocus.dispose();
    super.dispose();
  }

  Future<void> _addWallet() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<WalletProvider>().addWallet(
        address,
        _selectedChain,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding wallet: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Wallet'),
        backgroundColor: AppTheme.background,
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.displayMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.5,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chain selector
            Text(
              'Select Chain',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _chains.map((chain) {
                final isSelected = _selectedChain == chain['id'];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: chain != _chains.last ? 8 : 0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedChain = chain['id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (chain['color'] as Color).withOpacity(0.1)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? chain['color'] as Color
                                : AppTheme.muted.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              chain['icon'] as IconData,
                              color: chain['color'] as Color,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              chain['name'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? chain['color'] as Color : AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Wallet address input
            Text(
              'Wallet Address',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              focusNode: _addressFocus,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter wallet address',
                hintStyle: TextStyle(color: AppTheme.muted),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.muted.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.muted.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Wallet name input (optional)
            Text(
              'Wallet Name (Optional)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g., Main Wallet, Cold Storage',
                hintStyle: TextStyle(color: AppTheme.muted),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.muted.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.muted.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            const SizedBox(height: 32),

            // Add button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Add Wallet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}