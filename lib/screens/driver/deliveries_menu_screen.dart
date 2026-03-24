import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'delivery_orders_screen.dart';
import 'driver_ui.dart';

class DeliveriesMenuScreen extends StatelessWidget {
  const DeliveriesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDriverAppBar(
        context,
        title: 'Deliveries',
        subtitle: 'Select delivery type',
        icon: Icons.local_shipping_outlined,
      ),
      backgroundColor: driverBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DriverSectionLabel('DELIVERY TYPES'),
              const SizedBox(height: 8),
              _buildMenuTile(
                context: context,
                icon: Icons.storefront_outlined,
                title: 'RETAIL',
                subtitle: 'Manage retail customer deliveries',
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeliveryOrdersScreen(
                          deliveryType: DeliveryType.retail),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                context: context,
                icon: Icons.home_outlined,
                title: 'HOME',
                subtitle: 'Manage home customer deliveries',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeliveryOrdersScreen(
                          deliveryType: DeliveryType.home),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                context: context,
                icon: Icons.business_outlined,
                title: 'COMMERCIAL',
                subtitle: 'Manage commercial customer deliveries',
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeliveryOrdersScreen(
                          deliveryType: DeliveryType.commercial),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return DriverCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: driverNavy,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: driverMuted,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: driverMuted,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
