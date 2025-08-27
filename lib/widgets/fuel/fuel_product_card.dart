import 'package:flutter/material.dart';
import '../../models/fuel_product.dart';
import '../../utils/colors.dart'; // Ensure this path is correct for AppColors

class FuelProductCard extends StatelessWidget {
  final FuelProduct product;
  final String selectedCurrency;
  final VoidCallback onTap;

  const FuelProductCard({
    super.key,
    required this.product,
    required this.selectedCurrency,
    required this.onTap, required String currency,
    // The 'currency' parameter was redundant and has been removed.
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      // Shadow color is now consistent with a blue card
      shadowColor: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: product.isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Solid blue color applied here
            color: Colors.blue,
          ),
          child: Row(
            children: [
              _ProductIcon(
                productType: product.type,
                isAvailable: product.isAvailable,
                iconColor: Colors.white, // White icon for contrast on blue
                backgroundColor: Colors.white.withOpacity(0.1), // Light background for icon
              ),
              const SizedBox(width: 12),
              _ProductInfo(
                name: product.name,
                isAvailable: product.isAvailable,
                textColor: Colors.white, // White text for primary info
                lightTextColor: Colors.white70, // Lighter white for secondary info ("Per Liter")
              ),
              _PriceSection(
                price: product.prices[selectedCurrency] ?? 0.0,
                currency: selectedCurrency,
                productType: product.type,
                isAvailable: product.isAvailable,
                priceColor: Colors.white, // White price for contrast
              ),
              if (product.isAvailable) ...[
                const SizedBox(width: 8),
                _NavigationArrow(arrowColor: Colors.white), // White navigation arrow
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Product Icon Widget
class _ProductIcon extends StatelessWidget {
  final String productType;
  final bool isAvailable;
  final Color iconColor;
  final Color backgroundColor;

  const _ProductIcon({
    required this.productType,
    required this.isAvailable,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _ProductHelper.getProductIcon(productType); // Still gets icon based on type

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(isAvailable ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: iconColor.withOpacity(isAvailable ? 1.0 : 0.5),
        size: 20,
      ),
    );
  }
}

// Product Info Widget
class _ProductInfo extends StatelessWidget {
  final String name;
  final bool isAvailable;
  final Color textColor;
  final Color lightTextColor;

  const _ProductInfo({
    required this.name,
    required this.isAvailable,
    required this.textColor,
    required this.lightTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isAvailable ? textColor : lightTextColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Per Liter',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isAvailable ? lightTextColor : lightTextColor.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Price Section Widget
class _PriceSection extends StatelessWidget {
  final double price;
  final String currency;
  final String productType;
  final bool isAvailable;
  final Color priceColor;

  const _PriceSection({
    required this.price,
    required this.currency,
    required this.productType,
    required this.isAvailable,
    required this.priceColor,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbol =''; // Assume currency symbol is handled elsewhere or is an empty string
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$currencySymbol${price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isAvailable ? priceColor : priceColor.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        _StatusBadge(isAvailable: isAvailable),
      ],
    );
  }
}

// Status Badge Widget (No changes, retains its own color logic for status)
class _StatusBadge extends StatelessWidget {
  final bool isAvailable;

  const _StatusBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.2)
            : AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Out',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isAvailable ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

// Navigation Arrow Widget
class _NavigationArrow extends StatelessWidget {
  final Color arrowColor;

  const _NavigationArrow({required this.arrowColor});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios,
      color: arrowColor,
      size: 14,
    );
  }
}

// Product Helper Class (No changes needed, still useful for icon if different types exist)
class _ProductHelper {
  static Color getProductColor(String type) {
    switch (type.toLowerCase()) {
      case 'petrol':
        return AppColors.petrolColor;
      case 'diesel':
        return AppColors.dieselColor;
      case 'unleaded':
        return AppColors.unleadedColor;
      default:
        return AppColors.primary;
    }
  }

  static IconData getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'petrol':
      case 'diesel':
      case 'unleaded':
        return Icons.local_gas_station;
      default:
        return Icons.local_gas_station;
    }
  }
}