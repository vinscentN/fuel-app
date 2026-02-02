import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../models/buffalo_product.dart';
import 'buffalo_cart_screen.dart';

class BuffaloProductListScreen extends StatefulWidget {
  const BuffaloProductListScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloProductListScreen> createState() =>
      _BuffaloProductListScreenState();
}

class _BuffaloProductListScreenState extends State<BuffaloProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuffaloProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: BuffaloColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<BuffaloProvider>(
            builder: (context, provider, _) {
              final itemCount = provider.cartItemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    onPressed: () {
                      if (itemCount > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BuffaloCartScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: BuffaloColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<BuffaloProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingProducts) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(BuffaloColors.secondary),
              ),
            );
          }

          if (provider.productsError != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: BuffaloColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BuffaloColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.productsError!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: BuffaloColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchProducts(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BuffaloColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.products.isEmpty) {
            return const Center(
              child: Text('No products available'),
            );
          }

          return Column(
            children: [
              // Currency Selector
              Container(
                padding: const EdgeInsets.all(16),
                color: BuffaloColors.surfaceVariant,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Currency: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: provider.selectedCurrencyId,
                      underline: Container(),
                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child: Text('USD (\$)'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('ZIG (\$)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.setSelectedCurrency(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Product List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return _ProductCard(product: product);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<BuffaloProvider>(
        builder: (context, provider, _) {
          if (provider.cartItemCount == 0) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuffaloCartScreen(),
                ),
              );
            },
            backgroundColor: BuffaloColors.secondary,
            label: Text(
              'View Order (${provider.cartItemCount})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.receipt_long),
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final BuffaloProduct product;

  const _ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addToCart(BuildContext context) {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    final provider = context.read<BuffaloProvider>();
    provider.addToCart(widget.product.id, 1);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuffaloProvider>();
    final price = widget.product.getPriceForCurrency(provider.selectedCurrencyId);

    if (price == null) {
      return const SizedBox.shrink();
    }

    final isInCart = provider.cart.containsKey(widget.product.id);
    final cartQuantity = provider.cart[widget.product.id] ?? 0;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: () => _addToCart(context),
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isInCart
                  ? BuffaloColors.secondary
                  : BuffaloColors.cardBorder,
              width: isInCart ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Icon/Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: BuffaloColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getProductIcon(widget.product.sku),
                    size: 32,
                    color: BuffaloColors.secondary,
                  ),
                ),
                const SizedBox(width: 16),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BuffaloColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: BuffaloColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        price.formatted,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BuffaloColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Cart quantity indicator
                if (isInCart) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: BuffaloColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$cartQuantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getProductIcon(String sku) {
    if (sku.startsWith('FOOD')) {
      return Icons.restaurant;
    } else if (sku.startsWith('BEV')) {
      return Icons.local_drink;
    } else if (sku.startsWith('DESS')) {
      return Icons.cake;
    }
    return Icons.shopping_bag;
  }
}
