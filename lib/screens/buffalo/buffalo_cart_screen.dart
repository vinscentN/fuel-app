import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import 'buffalo_card_payment_screen.dart';

class BuffaloCartScreen extends StatelessWidget {
  const BuffaloCartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
        backgroundColor: BuffaloColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<BuffaloProvider>(
        builder: (context, provider, _) {
          if (provider.cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 100,
                    color: BuffaloColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your order is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: BuffaloColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BuffaloColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }

          final cartProducts = provider.cart.entries.map((entry) {
            final product =
                provider.products.firstWhere((p) => p.id == entry.key);
            return {'product': product, 'quantity': entry.value};
          }).toList();

          return Column(
            children: [
              // Cart Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProducts.length,
                  itemBuilder: (context, index) {
                    final item = cartProducts[index];
                    final product = item['product'] as dynamic;
                    final quantity = item['quantity'] as int;
                    final price = product
                        .getPriceForCurrency(provider.selectedCurrencyId);

                    if (price == null) return const SizedBox.shrink();

                    final subtotal = price.price * quantity;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Product Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    BuffaloColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                size: 28,
                                color: BuffaloColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Product Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${price.formatted} x $quantity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BuffaloColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${price.currencySymbol}${subtotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: BuffaloColors.cardBorder),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (quantity > 1) {
                                            provider.updateCartItemQuantity(
                                                product.id, quantity - 1);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: quantity > 1
                                                ? BuffaloColors.primary
                                                : BuffaloColors.textLight,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Text(
                                          '$quantity',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: BuffaloColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          provider.updateCartItemQuantity(
                                              product.id, quantity + 1);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.add,
                                            size: 16,
                                            color: BuffaloColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    provider.removeFromCart(product.id);
                                  },
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: BuffaloColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Summary and Checkout Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: BuffaloColors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items:',
                          style: TextStyle(
                            fontSize: 16,
                            color: BuffaloColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${provider.cartItemCount}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BuffaloColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: BuffaloColors.textPrimary,
                          ),
                        ),
                        Text(
                          provider.cartTotalFormatted,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BuffaloColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BuffaloCardPaymentScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BuffaloColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Order'),
                            content: const Text(
                                'Are you sure you want to clear your order?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.clearCart();
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Clear',
                                  style: TextStyle(color: BuffaloColors.error),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        'Clear Order',
                        style: TextStyle(
                          color: BuffaloColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
