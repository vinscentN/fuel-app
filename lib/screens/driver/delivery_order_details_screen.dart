import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/delivery_order_service.dart';
import 'delivery_complete_screen.dart';

class DeliveryOrderDetailsScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryOrderDetailsScreen> createState() =>
      _DeliveryOrderDetailsScreenState();
}

class _DeliveryOrderDetailsScreenState
    extends State<DeliveryOrderDetailsScreen> {
  final DeliveryOrderService _service = DeliveryOrderService();
  bool _isSubmitting = false;

  // Controllers for editable current weight per item
  late final List<TextEditingController> _weightControllers;
  // Track which items have unsaved changes
  late final List<bool> _weightDirty;
  // Track which items are currently saving
  late final List<bool> _weightSaving;
  // Accordion: which index is expanded (-1 = none)
  int _expandedIndex = -1;
  // Track which home delivery item is being edited (-1 = none)
  int _editingIndex = -1;

  // ── Swap cylinder return state (home deliveries only) ────────────
  List<SwapCylinder> _swapAssignments = [];
  bool _swapLoading = false;
  // assignmentId → true while the return API call is in progress
  final Map<int, bool> _returningId = {};

  @override
  void initState() {
    super.initState();
    final items = widget.order.items;
    final isHome = widget.order.typeLabel == 'HOME';
    final isCommercial = widget.order.typeLabel == 'COMMERCIAL';
    _weightControllers = items
        .map((item) =>
            TextEditingController(
              text: ((isHome || isCommercial) ? item.kgsLoaded : item.currentWeight)
                  .toStringAsFixed(2),
            ))
        .toList();
    _weightDirty = List.filled(items.length, false);
    _weightSaving = List.filled(items.length, false);

    for (int i = 0; i < _weightControllers.length; i++) {
      final idx = i;
      _weightControllers[idx].addListener(() {
        final baseline = (isHome || isCommercial)
            ? widget.order.items[idx].kgsLoaded.toStringAsFixed(2)
            : widget.order.items[idx].currentWeight.toStringAsFixed(2);
        final changed = _weightControllers[idx].text != baseline;
        if (_weightDirty[idx] != changed) {
          setState(() => _weightDirty[idx] = changed);
        }
      });
    }

    // Load live swap assignments for all delivery types
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSwapAssignments());
  }

  Future<void> _loadSwapAssignments() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() => _swapLoading = true);
    try {
      final list = await _service.getSwapAssignments(
        orderId: widget.order.id,
        token: token,
      );
      if (mounted) setState(() => _swapAssignments = list);
    } catch (_) {
      // Fall back to the swap cylinders embedded in the order
      if (mounted) {
        setState(() =>
            _swapAssignments = List.from(widget.order.swapCylinders));
      }
    } finally {
      if (mounted) setState(() => _swapLoading = false);
    }
  }

  Future<void> _markReturned(SwapCylinder swap) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
    setState(() => _returningId[swap.assignmentId] = true);
    try {
      final updated = await _service.markSwapReturned(
        orderId: widget.order.id,
        assignmentId: swap.assignmentId,
        token: token,
      );
      if (mounted) {
        setState(() {
          final idx = _swapAssignments
              .indexWhere((s) => s.assignmentId == swap.assignmentId);
          if (idx != -1) _swapAssignments[idx] = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _returningId.remove(swap.assignmentId));
    }
  }

  @override
  void dispose() {
    for (final c in _weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveWeight(int index) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final newWeight =
        double.tryParse(_weightControllers[index].text.trim());

    if (newWeight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid weight value'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _weightSaving[index] = true);
    try {
      await _service.updateItemCurrentWeight(
        orderId: widget.order.id,
        itemId: widget.order.items[index].id,
        currentWeight: newWeight,
        token: token,
      );
      if (mounted) {
        setState(() {
          _weightDirty[index] = false;
          _weightSaving[index] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight updated'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _weightSaving[index] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<SwapCylinder> _returnableSwapAssignments() {
    // Collect all cylinder IDs being delivered
    final deliveredCylinderIds = widget.order.items
        .map((item) => item.cylinder?.id ?? 0)
        .where((id) => id > 0)
        .toSet();

    // Collect all possible serial numbers from delivered items
    final deliveredSerials = <String>{};
    for (final item in widget.order.items) {
      // Add trackingCode (which is a getter that returns cylinder.trackingCode or serial)
      final tracking = item.trackingCode.trim().toUpperCase();
      if (tracking.isNotEmpty && tracking != 'LPG GAS') {
        deliveredSerials.add(tracking);
      }

      // Add item.serial directly
      final serial = (item.serial ?? '').trim().toUpperCase();
      if (serial.isNotEmpty && serial != 'LPG GAS') {
        deliveredSerials.add(serial);
      }

      // Add cylinder.trackingCode
      final cylinderSerial =
          (item.cylinder?.trackingCode ?? '').trim().toUpperCase();
      if (cylinderSerial.isNotEmpty && cylinderSerial != 'LPG GAS') {
        deliveredSerials.add(cylinderSerial);
      }

      // Add cylinder.name as well (in case serial matches the name)
      final cylinderName = (item.cylinder?.name ?? '').trim().toUpperCase();
      if (cylinderName.isNotEmpty) {
        deliveredSerials.add(cylinderName);
      }

      // Add cylinderName from item
      final itemCylinderName = (item.cylinderName ?? '').trim().toUpperCase();
      if (itemCylinderName.isNotEmpty) {
        deliveredSerials.add(itemCylinderName);
      }
    }

    // Filter out swap cylinders that match delivered items
    return _swapAssignments.where((swap) {
      // Check if swap cylinder ID matches any delivered cylinder ID
      final isDeliveredById =
          swap.cylinderId > 0 && deliveredCylinderIds.contains(swap.cylinderId);

      // Check if swap cylinder serial matches any delivered serial
      final swapSerial = swap.serial.trim().toUpperCase();
      final isDeliveredBySerial =
          swapSerial.isNotEmpty &&
          swapSerial != 'LPG GAS' &&
          deliveredSerials.contains(swapSerial);

      // Check if swap cylinder name matches any delivered serial/name
      final swapName = swap.cylinderName.trim().toUpperCase();
      final isDeliveredByName =
          swapName.isNotEmpty && deliveredSerials.contains(swapName);

      // Exclude if any match is found
      return !isDeliveredById && !isDeliveredBySerial && !isDeliveredByName;
    }).toList();
  }

  double _homeQtyFor(DeliveryOrderItem item, int index) {
    return double.tryParse(_weightControllers[index].text.trim()) ??
        item.kgsLoaded;
  }

  double _homeLineTotalFor(DeliveryOrderItem item, int index) {
    return _homeQtyFor(item, index) * item.unitPrice;
  }

  double _homeGrandTotalFor(DeliveryOrder order) {
    return order.items.asMap().entries.fold<double>(0, (sum, e) {
      return sum + _homeLineTotalFor(e.value, e.key);
    });
  }

  double _homeTotalKgsFor(DeliveryOrder order) {
    return order.items.asMap().entries.fold<double>(0, (sum, e) {
      return sum + _homeQtyFor(e.value, e.key);
    });
  }

  void _toggleEditQuantity(int index) {
    setState(() {
      if (_editingIndex == index) {
        // Close editing
        _editingIndex = -1;
      } else {
        // Open editing for this item
        _editingIndex = index;
      }
    });
  }

  void _applyQuantityEdit(int index) {
    final parsed = double.tryParse(_weightControllers[index].text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _editingIndex = -1;
    });
  }

  Future<void> _confirmDelivery() async {
    final isHome = widget.order.typeLabel == 'HOME';
    final isCommercial = widget.order.typeLabel == 'COMMERCIAL';

    // Show confirmation dialog with summary
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: _green, size: 20),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Confirm Delivery',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHome || isCommercial) ...[
                  const Text(
                    'Delivery Summary:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.order.items.asMap().entries.map((e) {
                    final index = e.key;
                    final item = e.value;
                    final qty = _homeQtyFor(item, index);
                    final unitPrice = item.unitPrice;
                    final lineTotal = _homeLineTotalFor(item, index);

                    // Resolve serial
                    String serial = item.trackingCode;
                    if (serial == 'LPG GAS' && widget.order.swapCylinders.isNotEmpty) {
                      serial = index < widget.order.swapCylinders.length
                          ? widget.order.swapCylinders[index].serial
                          : widget.order.swapCylinders[0].serial;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _navy,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    serial,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${qty.toStringAsFixed(2)} kg × \$${unitPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _muted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '\$${lineTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _text,
                        ),
                      ),
                      Text(
                        '\$${_homeGrandTotalFor(widget.order).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Quantity',
                        style: TextStyle(
                          fontSize: 10,
                          color: _muted,
                        ),
                      ),
                      Text(
                        '${_homeTotalKgsFor(widget.order).toStringAsFixed(2)} kg',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Cylinder Weights:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.order.items.asMap().entries.map((e) {
                    final index = e.key;
                    final item = e.value;
                    final currentWeight = double.tryParse(_weightControllers[index].text.trim()) ?? item.currentWeight;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product?.name ?? item.cylinderName ?? 'Cylinder ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _text,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.trackingCode,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: _muted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${currentWeight.toStringAsFixed(2)} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Confirm', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final user = authProvider.currentUser;

      if (token == null) throw Exception('Not authenticated');
      if (user == null) throw Exception('User not found');

      // Build payload based on delivery type
      final isHome = widget.order.typeLabel == 'HOME';
      final isCommercial = widget.order.typeLabel == 'COMMERCIAL';
      List<Map<String, dynamic>>? items;
      List<Map<String, dynamic>>? cylinders;

      if (isHome || isCommercial) {
        // Home & Commercial deliveries: use items array with delivered_quantity
        items = <Map<String, dynamic>>[];
        for (int i = 0; i < widget.order.items.length; i++) {
          final item = widget.order.items[i];
          final deliveredQty =
              double.tryParse(_weightControllers[i].text.trim()) ?? item.kgsLoaded;
          items.add({
            'item_id': item.id,
            'delivered_quantity': deliveredQty,
          });
        }
      } else {
        // Retail/Site only: use cylinders array with actual_weight and bottom_edge_weight
        cylinders = <Map<String, dynamic>>[];
        for (int i = 0; i < widget.order.items.length; i++) {
          final item = widget.order.items[i];
          final actualWeight =
              double.tryParse(_weightControllers[i].text.trim()) ?? item.currentWeight;
          final entry = <String, dynamic>{
            'item_id': item.id,
            'actual_weight': actualWeight,
          };
          // Include bottom_edge_weight if available
          if (item.bottomEdgeWeight > 0) {
            entry['bottom_edge_weight'] = item.bottomEdgeWeight;
          }
          cylinders.add(entry);
        }
      }

      final updatedOrder = await _service.updateDeliveryStatus(
        deliveryOrderId: widget.order.id,
        status: 'DELIVERED',
        assignedDriverId: user.id,
        token: token,
        items: items,
        cylinders: cylinders,
      );

      if (mounted) {
        final receiptData = _buildReceiptData(updatedOrder);
        final posProvider =
            Provider.of<PosProvider>(context, listen: false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DeliveryCompleteScreen(
              order: updatedOrder,
              receiptData: receiptData,
              posProvider: posProvider,
              onPrint: _doPrint,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Build all receipt field values from [order] — does NOT call print.
  Map<String, String> _buildReceiptData(DeliveryOrder order) {
    final now = DateTime.now();
    final date =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isHome = order.typeLabel == 'HOME';
    final isCommercial = order.typeLabel == 'COMMERCIAL';
    final isRetail = order.typeLabel == 'RETAIL'; // Only retail/site use technical cylinder details

    final siteName = order.customer?.name ?? order.site?.name ?? 'N/A';

    // Map original item ids → controller index
    final itemIdToIndex = {
      for (int i = 0; i < widget.order.items.length; i++)
        widget.order.items[i].id: i,
    };

    // Invoice number — first item that has one
    String invoiceNumber = 'N/A';
    for (final item in order.items) {
      if (item.invoiceNumber != null && item.invoiceNumber!.isNotEmpty) {
        invoiceNumber = item.invoiceNumber!;
        break;
      }
    }

    // Total KGs delivered — use expectedKg for bobtail, product weight sum otherwise
    final totalKgsValue = (isHome || isCommercial)
        ? order.items.asMap().entries.fold<double>(0, (sum, e) {
            final idx = itemIdToIndex[e.value.id];
            final qty = idx != null
                ? (double.tryParse(_weightControllers[idx].text.trim()) ??
                    e.value.kgsLoaded)
                : e.value.kgsLoaded;
            return sum + qty;
          })
        : order.hasBobtail
            ? (order.expectedKg ?? order.totalKg ?? order.totalKgsLoaded)
            : order.totalKgsLoaded;
    final totalKgs = totalKgsValue.toStringAsFixed(2);

    final customerName = order.customer?.name ?? order.site?.name ?? 'N/A';

    // Combine swap sources: embedded in order + live-loaded assignments
    final swaps = [
      ...order.swapCylinders,
      ..._swapAssignments.where(
          (s) => !order.swapCylinders.any((o) => o.assignmentId == s.assignmentId)),
    ];

    // ── Helper: resolve serial for an item ──────────────────────────
    String resolveSerial(DeliveryOrderItem item, int idx) {
      String serial = item.trackingCode;
      if ((serial.isEmpty || serial == 'LPG GAS') &&
          (item.serial?.isNotEmpty ?? false)) {
        serial = item.serial!;
      }
      if ((serial.isEmpty || serial == 'LPG GAS') && swaps.isNotEmpty) {
        serial = idx < swaps.length ? swaps[idx].serial : swaps[0].serial;
      }
      return serial;
    }

    final grandTotal = order.items.asMap().entries.fold<double>(0, (sum, e) {
      if (isHome || isCommercial) {
        final idx = itemIdToIndex[e.value.id];
        final qty = idx != null
            ? (double.tryParse(_weightControllers[idx].text.trim()) ??
                e.value.kgsLoaded)
            : e.value.kgsLoaded;
        return sum + (qty * e.value.unitPrice);
      }
      return sum + e.value.total;
    });

    // ── Customer/home receipt lines: table format ─
    final homeItemLines = StringBuffer();
    homeItemLines.writeln('\nS/N              QTY  U/P  TOTAL');
    homeItemLines.writeln('--------------------------------');

    for (final e in order.items.asMap().entries) {
      final serial    = resolveSerial(e.value, e.key);
      final idx       = itemIdToIndex[e.value.id];
      final qtyValue  = idx != null
          ? (double.tryParse(_weightControllers[idx].text.trim()) ??
              e.value.kgsLoaded)
          : e.value.kgsLoaded;
      final qty       = qtyValue.toStringAsFixed(2);
      final unitPrice = e.value.unitPrice.toStringAsFixed(2);
      final lineTotal = (qtyValue * e.value.unitPrice).toStringAsFixed(2);

      // Truncate serial if too long (max 12 chars)
      final displaySerial = serial.length > 12 ? serial.substring(0, 12) : serial;

      // Format: S/N (12 chars), QTY (5 chars), U/P (5 chars), TOTAL (7 chars)
      final line = '${displaySerial.padRight(12)} ${qty.padLeft(5)} ${unitPrice.padLeft(4)} ${lineTotal.padLeft(6)}';
      homeItemLines.writeln(line);
    }

    final homeDetails = order.items.isEmpty
        ? 'Total KGs Delivered: $totalKgs kg'
        : '${homeItemLines.toString()}--------------------------------\n'
          'Total KGs: $totalKgs kg\n'
          'TOTAL: \$${grandTotal.toStringAsFixed(2)}';

    // ── Driver/technical cylinder details ──────────────────────────
    // Home & Commercial: table format with qty/price/total
    // Retail/Site only: table with bottom edge, product weight, current weight
    String itemLines;
    if (isRetail) {
      final retailLines = StringBuffer();
      retailLines.writeln('\nS/N           B.E   P.W   C.W');
      retailLines.writeln('--------------------------------');

      for (final item in order.items) {
        final serial     = resolveSerial(item, order.items.indexOf(item));
        final botEdge    = item.bottomEdgeWeight.toStringAsFixed(2);
        final prodWeight = item.kgsLoaded.toStringAsFixed(2);
        final ctrlIdx    = itemIdToIndex[item.id];
        final currWeight = ctrlIdx != null
            ? (double.tryParse(_weightControllers[ctrlIdx].text.trim())
                    ?.toStringAsFixed(2) ??
                item.currentWeight.toStringAsFixed(2))
            : item.currentWeight.toStringAsFixed(2);

        // Truncate serial if too long
        final displaySerial = serial.length > 12 ? serial.substring(0, 12) : serial;

        // Format: S/N (12 chars), B.E (5 chars), P.W (5 chars), C.W (5 chars)
        final line = '${displaySerial.padRight(12)} ${botEdge.padLeft(5)} ${prodWeight.padLeft(5)} ${currWeight.padLeft(5)}';
        retailLines.writeln(line);
      }
      itemLines = retailLines.toString();
    } else {
      itemLines = homeItemLines.toString(); // home & commercial use same format
    }

    final cylinderDetails = (isHome || isCommercial)
        ? homeDetails
        : '$itemLines--------------------------------\nTotal KGs Delivered: $totalKgs kg';

    // Customer copy details
    final customerCylinderDetails = (isHome || isCommercial) ? homeDetails : cylinderDetails;

    return {
      'requestCode':             'ORDER-${order.id}',
      'deliveryCode':            'DELIVERY-${order.id}',
      'invoiceNumber':           invoiceNumber,
      // Home & Commercial deliveries: no centered station name — the "Customer:" line covers it.
      // Retail/site only: print site name centered at top.
      'stationName':             (isHome || isCommercial) ? '' : siteName,
      'address':                 order.deliveryAddress,
      'phone':                   order.customer?.phone ?? '',
      'date':                    date,
      'time':                    time,
      'driverName':              authProvider.currentUser?.fullName ?? 'N/A',
      'cylinderCount':           order.items.length.toString(),
      'cylinderDetails':         cylinderDetails,
      'customerCylinderDetails': customerCylinderDetails,
      'customerName':            customerName,
      'description':             order.notes ?? (isHome ? 'Home' : (isCommercial ? 'Commercial' : order.typeLabel)),
      // Home & Commercial: siteName = customer name (printed as "Customer: X", stationName is blank)
      // Retail/site: siteName is blank because stationName already prints the name centred at top
      'siteName':                (isHome || isCommercial) ? customerName : '',
      'detailsLabel':            order.hasBobtail ? 'BOBTAIL DETAILS' : 'CYLINDER DETAILS',
      'recipientLabel':          (isHome || isCommercial) ? 'Customer' : 'Site',
    };
  }

  Future<void> _doPrint(
      Map<String, String> data, String copyType, PosProvider posProvider,
      {String? cylinderDetailsOverride}) async {
    await posProvider.printDeliveryReceipt(
      requestCode:     data['requestCode']!,
      deliveryCode:    data['deliveryCode']!,
      invoiceNumber:   data['invoiceNumber']!,
      stationName:     data['stationName']!,
      address:         data['address']!,
      phone:           data['phone']!,
      date:            data['date']!,
      time:            data['time']!,
      driverName:      data['driverName']!,
      cylinderCount:   data['cylinderCount']!,
      cylinderDetails: cylinderDetailsOverride ?? data['cylinderDetails']!,
      description:     data['description']!,
      siteName:        data['siteName']!,
      copyType:        copyType,
      detailsLabel:    data['detailsLabel'] ?? 'CYLINDER DETAILS',
      recipientLabel:  data['recipientLabel'] ?? 'Customer',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Palette
  // ─────────────────────────────────────────────────────────────────
  static const _navy   = Color(0xFF1C2B4A);
  static const _blue   = Color(0xFF2563EB);
  static const _amber  = Color(0xFFD97706);
  static const _green  = Color(0xFF16A34A);
  static const _bg     = Color(0xFFF5F7FA);
  static const _border = Color(0xFFE2E8F0);
  static const _text   = Color(0xFF1E293B);
  static const _muted  = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isHome = order.typeLabel == 'HOME';
    final isCommercial = order.typeLabel == 'COMMERCIAL';
    final count = order.items.length;
    final hasDirty = _weightDirty.any((d) => d);
    final totalKgs = (isHome || isCommercial)
        ? _homeTotalKgsFor(order)
        : (order.hasBobtail
            ? (order.expectedKg ?? order.totalKg ?? order.totalKgsLoaded)
            : order.totalKgsLoaded);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.recipientName,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Text(order.deliveryAddress,
                style:
                    const TextStyle(fontSize: 11, color: Colors.white54),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          if (order.hasBobtail)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _amber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('BOBTAIL',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary strip ──────────────────────────────────────
          Container(
            color: _navy,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _pill('$count ${count == 1 ? "Cylinder" : "Cylinders"}',
                        Icons.propane_tank_outlined),
                    const SizedBox(width: 8),
                    _pill(
                        '${totalKgs.toStringAsFixed(1)} kg total',
                        Icons.scale_outlined),
                  ],
                ),
                if (order.hasBobtail) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: _amber.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(8),
                      color: _amber.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 14, color: _amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.expectedKg != null
                                ? 'Delivery of ${order.expectedKg!.toStringAsFixed(1)} kg by bobtail'
                                : order.totalKg != null
                                    ? 'Delivery of ${order.totalKg!.toStringAsFixed(1)} kg by bobtail'
                                    : 'Bobtail delivery',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _amber),
                          ),
                        ),
                        if (order.bobtail?.plateNumber != null)
                          Text(order.bobtail!.plateNumber!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _amber)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Content list ───────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Bobtail-only: no cylinders, just a KG info card
                if (order.hasBobtail && order.items.isEmpty) ...[
                  _buildBobtailKgCard(order),
                  const SizedBox(height: 12),
                ],

                // Swap cylinders — interactive return for all delivery types
                _buildSwapReturnSection(),
                const SizedBox(height: 12),

                // Cylinder list
                if (order.items.isNotEmpty)
                  _buildCylinderList(order),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom bar ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _confirmDelivery,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline, size: 19),
                  label: Text(
                    _isSubmitting ? 'Confirming...' : 'Confirm Delivery',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary pill ─────────────────────────────────────────────────
  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ── Cylinder list (flat for home/commercial, retail uses simplified view) ─
  Widget _buildCylinderList(DeliveryOrder order) {
    final isHome = order.typeLabel == 'HOME';
    final isCommercial = order.typeLabel == 'COMMERCIAL';
    final swaps = order.swapCylinders;

    if (isHome || isCommercial) {
      final grandTotal = _homeGrandTotalFor(order);
      // Simple flat card — serial + KGs loaded per row
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _navy, width: 1.5),
        ),
        child: Column(
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 38), // badge width + gap
                  Expanded(
                    child: Text(
                      'Serial Number',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Text(
                    'Qty / Amount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _navy.withValues(alpha: 0.2)),
            ...order.items.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;

              // Resolve serial from swap_cylinders if item has none
              String serial = item.trackingCode;
              if (serial == 'LPG GAS' && swaps.isNotEmpty) {
                serial = index < swaps.length
                    ? swaps[index].serial
                    : swaps[0].serial;
              }

              final qty = _homeQtyFor(item, index);
              final unitPrice = item.unitPrice.toStringAsFixed(2);
              final lineTotal = _homeLineTotalFor(item, index).toStringAsFixed(2);
              final isLast = index == order.items.length - 1;
              final isEditing = _editingIndex == index;
              final isDirty = _weightDirty[index];

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isEditing
                          ? _blue.withValues(alpha: 0.03)
                          : Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        // Main row - fully clickable
                        InkWell(
                          onTap: isEditing ? null : () => _toggleEditQuantity(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isEditing
                                        ? _blue
                                        : _navy.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isEditing ? Colors.white : _navy,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        serial,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _text,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (!isEditing) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '@ \$$unitPrice/kg',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (!isEditing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isDirty ? _amber : _navy,
                                        width: isDirty ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isDirty)
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 4),
                                                child: Icon(Icons.edit_rounded,
                                                    size: 11, color: _amber),
                                              ),
                                            Text(
                                              '${qty.toStringAsFixed(2)} kg',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: isDirty ? _amber : _navy,
                                                height: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '\$$lineTotal',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDirty ? _amber : _green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Expandable edit section
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: isEditing
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 38), // Align with text
                                      Expanded(
                                        child: TextField(
                                          controller: _weightControllers[index],
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                  decimal: true),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: _navy,
                                          ),
                                          decoration: InputDecoration(
                                            suffixText: 'kg',
                                            suffixStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _muted,
                                            ),
                                            hintText: 'Enter quantity',
                                            hintStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFCBD5E1),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: _blue,
                                                width: 2,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: _blue,
                                                width: 2,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: _blue,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Apply button
                                      GestureDetector(
                                        onTap: () => _applyQuantityEdit(index),
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _green,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: _navy.withValues(alpha: 0.2)),
                ],
              );
            }),
            Divider(height: 1, color: _navy.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Text(
                    '\$${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Non-home: use same flat layout as home
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _navy, width: 1.5),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: _navy.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 38), // badge width + gap
                Expanded(
                  child: Text(
                    'Serial Number',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Text(
                  'Weight',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _navy.withValues(alpha: 0.2)),
          ...order.items.asMap().entries.map((e) {
            final index = e.key;
            final item = e.value;

            // Resolve serial from swap_cylinders if item has none
            String serial = item.trackingCode;
            if (serial == 'LPG GAS' && swaps.isNotEmpty) {
              serial = index < swaps.length
                  ? swaps[index].serial
                  : swaps[0].serial;
            }

            final currentWeight = double.tryParse(_weightControllers[index].text.trim()) ?? item.currentWeight;
            final isLast = index == order.items.length - 1;
            final isEditing = _editingIndex == index;
            final isDirty = _weightDirty[index];

            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isEditing
                        ? _blue.withValues(alpha: 0.03)
                        : Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      // Main row - fully clickable
                      InkWell(
                        onTap: isEditing ? null : () => _toggleEditQuantity(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isEditing
                                      ? _blue
                                      : _navy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isEditing ? Colors.white : _navy,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      serial,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _text,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (!isEditing) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.product?.name ?? item.cylinderName ?? 'Cylinder',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _muted,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isEditing)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isDirty ? _amber : _navy,
                                      width: isDirty ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isDirty)
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 4),
                                              child: Icon(Icons.edit_rounded,
                                                  size: 11, color: _amber),
                                            ),
                                          Text(
                                            '${currentWeight.toStringAsFixed(2)} kg',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: isDirty ? _amber : _navy,
                                              height: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Expandable edit section
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isEditing
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 38), // Align with text
                                    Expanded(
                                      child: TextField(
                                        controller: _weightControllers[index],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: _navy,
                                        ),
                                        decoration: InputDecoration(
                                          suffixText: 'kg',
                                          suffixStyle: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _muted,
                                          ),
                                          hintText: 'Enter weight',
                                          hintStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFFCBD5E1),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                              color: _blue,
                                              width: 2,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                              color: _blue,
                                              width: 2,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                              color: _blue,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Apply button
                                    GestureDetector(
                                      onTap: () => _applyQuantityEdit(index),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _green,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: _navy.withValues(alpha: 0.2)),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Accordion row ────────────────────────────────────────────────
  Widget _buildAccordion(
      DeliveryOrderItem item, String productName, int index,
      {String? swapSerial}) {
    final isHome = widget.order.typeLabel == 'HOME';
    final displaySerial = item.trackingCode != 'LPG GAS'
        ? item.trackingCode
        : (swapSerial?.isNotEmpty == true ? swapSerial! : 'LPG GAS');
    final isOpen = _expandedIndex == index;
    final isDirty = !isHome && _weightDirty[index];
    final isSaving = !isHome && _weightSaving[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDirty ? _amber : (isOpen ? _blue : _border),
          width: isOpen || isDirty ? 1.5 : 1,
        ),
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: _blue.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Column(
        children: [
          // ── Collapsed row (always visible) ──────────────────────
          InkWell(
            onTap: () => setState(() =>
                _expandedIndex = isOpen ? -1 : index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Index badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isOpen
                          ? _blue
                          : _navy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isOpen ? Colors.white : _navy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Serial + name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          displaySerial,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Weight preview
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (isDirty)
                            const Padding(
                              padding: EdgeInsets.only(right: 5),
                              child: Icon(Icons.edit_rounded,
                                  size: 12, color: _amber),
                            ),
                          Text(
                            isHome
                                ? '${item.kgsLoaded.toStringAsFixed(2)} kg'
                                : '${item.currentWeight.toStringAsFixed(2)} kg',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDirty ? _amber : _text,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isHome ? 'KGs loaded' : 'current wt',
                        style: const TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: _muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ────────────────────────────────────
          if (isOpen) ...[
            Divider(height: 1, color: _border),

            Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, isHome ? 12 : 0),
              child: Row(
                children: [
                  if (!isHome) ...[
                    Expanded(
                        child: _statCell(
                      label: 'Bottom Edge',
                      value:
                          '${item.bottomEdgeWeight.toStringAsFixed(2)} kg',
                      icon: Icons.vertical_align_bottom_rounded,
                    )),
                    Container(
                        width: 1, height: 36, color: _border),
                  ],
                  Expanded(
                      child: _statCell(
                    label: 'KGs Loaded',
                    value: '${item.kgsLoaded.toStringAsFixed(2)} kg',
                    icon: Icons.local_gas_station_outlined,
                  )),
                ],
              ),
            ),

            if (!isHome) ...[
            Divider(
                height: 24,
                indent: 14,
                endIndent: 14,
                color: _border),

            // Weight label
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.monitor_weight_outlined,
                      size: 13, color: _muted),
                  const SizedBox(width: 6),
                  const Text('Update Current Weight',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted)),
                  if (isDirty) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text('MODIFIED',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: _amber,
                              letterSpacing: 0.4)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Input row ──────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDirty
                            ? const Color(0xFFFFFBF0)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDirty
                              ? _amber
                              : _border,
                          width: isDirty ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller:
                                  _weightControllers[index],
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                          decimal: true),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: isDirty
                                    ? _amber
                                    : _text,
                                letterSpacing: 0.3,
                                height: 1.1,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.zero,
                                hintText: '0.00',
                                hintStyle: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 26,
                                    fontWeight:
                                        FontWeight.w800),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 14),
                            child: Text('kg',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDirty
                                        ? _amber
                                        : _muted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Save / spinner / check
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: 200),
                      child: isDirty
                          ? (isSaving
                              ? Container(
                                  key: const ValueKey('spin'),
                                  decoration: BoxDecoration(
                                    color: _amber
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(
                                            10),
                                    border: Border.all(
                                        color: _amber
                                            .withValues(
                                                alpha: 0.3)),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _amber,
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  key: const ValueKey('save'),
                                  onTap: () =>
                                      _saveWeight(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _amber,
                                      borderRadius:
                                          BorderRadius.circular(
                                              10),
                                    ),
                                    child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 22),
                                  ),
                                ))
                          : Container(
                              key: const ValueKey('ok'),
                              decoration: BoxDecoration(
                                color: _green
                                    .withValues(alpha: 0.08),
                                borderRadius:
                                    BorderRadius.circular(10),
                                border: Border.all(
                                    color: _green
                                        .withValues(alpha: 0.25)),
                              ),
                              child: const Icon(
                                  Icons.check_rounded,
                                  color: _green,
                                  size: 20),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            ], // end if (!isHome)
          ],
        ],
      ),
    );
  }

  // ── Bobtail KG info card ─────────────────────────────────────────
  Widget _buildBobtailKgCard(DeliveryOrder order) {
    final kg = order.expectedKg ?? order.totalKg ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_shipping_outlined, size: 36, color: _amber),
          const SizedBox(height: 12),
          Text(
            '${kg.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _amber,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Expected KGs to be delivered',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
          if (order.bobtail?.plateNumber != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_outlined,
                      size: 13, color: _navy),
                  const SizedBox(width: 6),
                  Text(
                    order.bobtail!.plateNumber!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Swap cylinder return section (home deliveries) ───────────────
  Widget _buildSwapReturnSection() {
    final visibleAssignments = _returnableSwapAssignments();
    final returnedCount =
        visibleAssignments.where((s) => s.isReturned).length;
    final totalCount = visibleAssignments.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _navy, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded,
                    size: 15, color: _blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _swapLoading
                        ? 'Loading swap cylinders…'
                        : 'Swap Cylinders ($returnedCount/$totalCount returned)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_swapLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _blue),
                  )
                else
                  GestureDetector(
                    onTap: _loadSwapAssignments,
                    child: const Icon(Icons.refresh_rounded,
                        size: 16, color: _muted),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: _navy.withValues(alpha: 0.2)),

          if (_swapLoading && visibleAssignments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Loading…',
                    style: TextStyle(fontSize: 13, color: _muted)),
              ),
            )
          else if (visibleAssignments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No returnable swap cylinders found for this delivery.',
                style: TextStyle(fontSize: 13, color: _muted),
              ),
            )
          else
            ...visibleAssignments.asMap().entries.map((e) {
              final i = e.key;
              final swap = e.value;
              final isReturning =
                  _returningId[swap.assignmentId] == true;
              final isLast = i == visibleAssignments.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Index badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: swap.isReturned
                                ? _green.withValues(alpha: 0.1)
                                : _blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Icon(
                              swap.isReturned
                                  ? Icons.check_rounded
                                  : Icons.propane_tank_outlined,
                              size: 14,
                              color:
                                  swap.isReturned ? _green : _blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Cylinder info
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                swap.cylinderName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                swap.serial,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _muted,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (swap.isReturned &&
                                  swap.returnedAt != null)
                                Text(
                                  'Returned: ${swap.returnedAt}',
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: _green),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Action button
                        if (swap.isReturned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      _green.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Returned',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _green),
                            ),
                          )
                        else if (isReturning)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _blue),
                          )
                        else
                          GestureDetector(
                            onTap: () => _markReturned(swap),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _navy,
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Mark Returned',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: _navy.withValues(alpha: 0.2)),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ── Swap cylinders section (read-only, non-home) ──────────────────
  Widget _buildSwapCylindersSection(List<SwapCylinder> swaps) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz_rounded, size: 15, color: _blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swap Cylinders (${swaps.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: _border),
          ...swaps.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.cylinderName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              s.serial,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _muted,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.swap_horiz_rounded,
                          size: 14, color: _muted),
                    ],
                  ),
                ),
                if (i < swaps.length - 1) Divider(height: 1, color: _border),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Stat cell ────────────────────────────────────────────────────
  Widget _statCell({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text,
                      height: 1.1)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: _muted, height: 1.2)),
            ],
          ),
        ],
      ),
    );
  }

}
