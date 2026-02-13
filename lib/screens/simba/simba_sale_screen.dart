import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/simba_provider.dart';
import '../../models/api_product.dart';
import 'simba_sale_card_tap_screen.dart';

class SimbaSaleScreen extends StatefulWidget {
  const SimbaSaleScreen({Key? key}) : super(key: key);

  @override
  State<SimbaSaleScreen> createState() => _SimbaSaleScreenState();
}

class _SimbaSaleScreenState extends State<SimbaSaleScreen> {
  ApiProduct? _selectedProduct;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SimbaProvider>().fetchProductsOnSale();
    });
  }

  void _proceedToPayment() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: BuffaloColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimbaSaleCardTapScreen(
          product: _selectedProduct!,
          quantity: _quantity,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Make a Sale'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Consumer<SimbaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingProducts) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(BuffaloColors.secondary),
              ),
            );
          }

          if (provider.productsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: BuffaloColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load products',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.productsError!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: BuffaloColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.fetchProductsOnSale();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BuffaloColors.secondary,
                        foregroundColor: BuffaloColors.textOnSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.products.isEmpty) {
            return const Center(
              child: Text(
                'No products available',
                style: TextStyle(
                  fontSize: 18,
                  color: BuffaloColors.textSecondary,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    final isSelected = _selectedProduct?.id == product.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? BuffaloColors.secondary
                              : BuffaloColors.cardBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedProduct = product;
                            _quantity = 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Product icon/image placeholder
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: BuffaloColors.primaryLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.shopping_bag,
                                  size: 32,
                                  color: BuffaloColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: BuffaloColors.textPrimary,
                                      ),
                                    ),
                                    if (product.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        product.description!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: BuffaloColors.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          '${product.currency?.symbol ?? ''} ${product.price}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: BuffaloColors.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Stock: ${product.stockQuantity}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: product.stockQuantity > 0
                                                ? BuffaloColors.success
                                                : BuffaloColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: BuffaloColors.secondary,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bottom section for quantity and proceed button
              if (_selectedProduct != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: BuffaloColors.cardShadow,
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle),
                              color: BuffaloColors.secondary,
                              iconSize: 36,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: BuffaloColors.cardBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _quantity < _selectedProduct!.stockQuantity
                                  ? () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.add_circle),
                              color: BuffaloColors.secondary,
                              iconSize: 36,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total: ${_selectedProduct!.currency?.symbol ?? ''} ${(_selectedProduct!.priceValue * _quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BuffaloColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _proceedToPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BuffaloColors.secondary,
                              foregroundColor: BuffaloColors.textOnSecondary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Proceed to Payment',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
