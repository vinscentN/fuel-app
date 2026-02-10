import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_tank.dart';
import '../../models/site_collection_group.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';

class CylinderCollectionsScreen extends StatefulWidget {
  const CylinderCollectionsScreen({super.key});

  @override
  State<CylinderCollectionsScreen> createState() => _CylinderCollectionsScreenState();
}

class _CylinderCollectionsScreenState extends State<CylinderCollectionsScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  List<GasTank> _tanks = [];
  Map<int, bool> _selectedTanks = {};
  Map<int, TextEditingController> _weightControllers = {};

  List<SiteCollectionGroup> _pendingGroups = [];

  bool _isLoadingTanks = true;
  bool _isSubmitting = false;
  bool _isLoadingCollections = true;
  String? _errorTanks;
  String? _errorCollections;

  @override
  void initState() {
    super.initState();
    _loadTanks();
    _loadCollections();
  }

  @override
  void dispose() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTanks() async {
    setState(() {
      _isLoadingTanks = true;
      _errorTanks = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      final tanks = await _gasOrderService.getTanksForStation(
        user.serviceStationId,
        token,
      );

      setState(() {
        _tanks = tanks;
        _selectedTanks = {for (final tank in tanks) tank.id: false};
        _weightControllers = {
          for (final tank in tanks) tank.id: TextEditingController()
        };
        _isLoadingTanks = false;
      });
    } catch (e) {
      setState(() {
        _errorTanks = e.toString().replaceAll('Exception: ', '');
        _isLoadingTanks = false;
      });
    }
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoadingCollections = true;
      _errorCollections = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      final pending = await _gasOrderService.getSiteCollectionsPendingGrouped(token);

      final pendingFiltered = pending.where((c) {
        final sameStation = user.serviceStationId == 0 || c.serviceStationId == user.serviceStationId;
        final sameAttendant = c.preparedByAttendantId == user.id;
        return sameStation && sameAttendant;
      }).toList();

      pendingFiltered.sort((a, b) {
        final ad = a.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      setState(() {
        _pendingGroups = pendingFiltered;
        _isLoadingCollections = false;
      });
    } catch (e) {
      setState(() {
        _errorCollections = e.toString().replaceAll('Exception: ', '');
        _isLoadingCollections = false;
      });
    }
  }

  double _parseWeight(String value) {
    final normalized = value.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  double _bottomEdge(double currentWeight, double tareWeight) {
    return currentWeight - tareWeight;
  }

  Future<void> _submitCollections() async {
    final selectedTankIds = _selectedTanks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedTankIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cylinder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cylinders = <Map<String, dynamic>>[];
    for (final tankId in selectedTankIds) {
      final text = _weightControllers[tankId]?.text.trim() ?? '';
      if (text.isEmpty) {
        final tank = _tanks.firstWhere((t) => t.id == tankId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter current weight for ${tank.trackingCode ?? tank.name}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final currentWeight = _parseWeight(text);
      if (currentWeight <= 0) {
        final tank = _tanks.firstWhere((t) => t.id == tankId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid weight for ${tank.trackingCode ?? tank.name}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      cylinders.add({
        'cylinder_id': tankId,
        'current_weight': currentWeight,
      });
    }

    final remarks = _buildRemarks();

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      await _gasOrderService.createSiteCollections(
        serviceStationId: user.serviceStationId,
        preparedByAttendantId: user.id,
        remarks: remarks,
        cylinders: cylinders,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cylinder collections prepared successfully'),
            backgroundColor: Colors.green,
          ),
        );
        for (final id in selectedTankIds) {
          _selectedTanks[id] = false;
          _weightControllers[id]?.clear();
        }
        setState(() {});
        await _loadCollections();
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

  String _buildRemarks() {
    final now = DateTime.now().toLocal();
    final date = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return 'Daily Collection - $date';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PICKED_UP':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final d = dateTime.toLocal();
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.modernGradient,
          ),
          child: AppBar(
            title: const Text(
              'Cylinder Collections',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  _loadTanks();
                  _loadCollections();
                },
              ),
            ],
          ),
        ),
      ),
      body: _isLoadingTanks
          ? const Center(child: CircularProgressIndicator())
          : _errorTanks != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorTanks!,
                          style: const TextStyle(color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTanks,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tanks.isEmpty
                  ? const Center(
                      child: Text(
                        'No cylinders available',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      Provider.of<AuthProvider>(context, listen: false).serviceStationName ??
                                          'Service Station',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Text(
                                'Select empty cylinders that are ready to go for refill.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _tanks.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final tank = _tanks[index];
                                final isSelected = _selectedTanks[tank.id] ?? false;
                                final tare = tank.capacity;
                                final weightText = _weightControllers[tank.id]?.text.trim() ?? '';
                                final double current = weightText.isEmpty ? 0.0 : _parseWeight(weightText);
                                final bottomEdge = _bottomEdge(current, tare);
                                final displayBottomEdge = weightText.isEmpty ? 0.0 : bottomEdge;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: Colors.white,
                                  elevation: isSelected ? 4 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: isSelected,
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedTanks[tank.id] = value ?? false;
                                                });
                                              },
                                              activeColor: AppColors.primary,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tank.trackingCode ?? tank.name,
                                                    style: const TextStyle(
                                                      color: Colors.black87,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${tank.cylinderType?.name ?? "N/A"} • ${tank.capacity.toStringAsFixed(0)} ${tank.unit}',
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    tank.product?.productType?.name ?? 'N/A',
                                                    style: const TextStyle(
                                                      color: Colors.black45,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _weightControllers[tank.id],
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            style: const TextStyle(color: Colors.black87),
                                            decoration: InputDecoration(
                                              labelText: 'Current Weight (${tank.unit})',
                                              labelStyle: const TextStyle(color: Colors.black54),
                                              hintText: '0.00',
                                              hintStyle: const TextStyle(color: Colors.black38),
                                              filled: true,
                                              fillColor: Colors.grey[100],
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                              ),
                                              prefixIcon: const Icon(Icons.scale, color: Colors.black54),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Tare Weight: ${tare.toStringAsFixed(2)} ${tank.unit}',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                              'Bottom Edge: ${displayBottomEdge.toStringAsFixed(2)} ${tank.unit}',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitCollections,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Prepare Collections',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'My Collections',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: _isLoadingCollections
                                  ? const Center(child: CircularProgressIndicator())
                                  : _errorCollections != null
                                      ? Center(child: Text(_errorCollections!))
                                      : _buildGroupList(_pendingGroups, emptyText: 'No pending collections'),
                            ),
                          ],
                        ),
                      ),
    );
  }

  Widget _buildGroupList(List<SiteCollectionGroup> groups, {required String emptyText}) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final stationName = group.items.isNotEmpty
            ? group.items.first.cylinder.serviceStationName
            : 'Station ${group.serviceStationId}';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _statusColor(group.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: _statusColor(group.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.collectionReference,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stationName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.count} cylinder${group.count != 1 ? 's' : ''} • ${_formatDateTime(group.preparedAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(group.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.status,
                    style: TextStyle(
                      color: _statusColor(group.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              if ((group.remarks ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Remarks: ${group.remarks}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              if (group.items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: group.items.map((c) {
                    final t = c.cylinder;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.propane_tank, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.trackingCode ?? t.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${t.cylinderType?.name ?? "N/A"} • ${t.capacity.toStringAsFixed(0)} ${t.unit}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${c.currentWeight} ${t.unit}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'BE ${c.bottomEdgeWeight} ${t.unit}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}
