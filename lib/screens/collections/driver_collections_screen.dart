import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/site_collection_group.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import '../driver/driver_ui.dart';

class DriverCollectionsScreen extends StatefulWidget {
  const DriverCollectionsScreen({super.key});

  @override
  State<DriverCollectionsScreen> createState() => _DriverCollectionsScreenState();
}

class _DriverCollectionsScreenState extends State<DriverCollectionsScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  bool _isLoading = true;
  bool _isConfirming = false;
  String? _error;
  List<SiteCollectionGroup> _pending = [];
  List<SiteCollectionGroup> _pickedUp = [];
  final Map<String, bool> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      final pending = await _gasOrderService.getSiteCollectionsPendingGrouped(token);
      final pickedUp = await _gasOrderService.getSiteCollectionsPickedUpGrouped(token);

      pending.sort((a, b) {
        final ad = a.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      pickedUp.sort((a, b) {
        final ad = a.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });

      setState(() {
        _pending = pending;
        _pickedUp = pickedUp;
        _selected
          ..clear()
          ..addEntries(pending.map((c) => MapEntry(c.collectionReference, false)));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPickup() async {
    final groups = _selected.entries.where((e) => e.value).map((e) => e.key).toList();
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cylinder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ids = <int>[];
    for (final g in _pending) {
      if (!groups.contains(g.collectionReference)) continue;
      ids.addAll(g.items.map((e) => e.id));
    }

    setState(() => _isConfirming = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      await _gasOrderService.completeSiteCollections(
        completedByAttendantId: user.id,
        collectionIds: ids,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collections marked as picked up'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPending();
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
        setState(() => _isConfirming = false);
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final d = dateTime.toLocal();
    return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, int> _todaySummary(List<SiteCollectionGroup> groups, DateTime now) {
    int batches = 0;
    int cylinders = 0;
    for (final g in groups) {
      final d = g.preparedAt;
      if (d == null) continue;
      if (_isSameDay(d.toLocal(), now)) {
        batches += 1;
        cylinders += g.count;
      }
    }
    return {'batches': batches, 'cylinders': cylinders};
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pendingToday = _todaySummary(_pending, now);
    final pickedUpToday = _todaySummary(_pickedUp, now);
    return Scaffold(
      backgroundColor: driverBg,
      appBar: buildDriverAppBar(
        context,
        title: 'Cylinder Collections',
        subtitle: 'Pending and picked up batches',
        icon: Icons.propane_tank_outlined,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            onPressed: _loadPending,
            splashRadius: 20,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? DriverErrorState(
                  message: _error!,
                  onRetry: _loadPending,
                )
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      _buildTodaySummary(pendingToday, pickedUpToday),
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EDF5)),
                          boxShadow: [
                            BoxShadow(
                              color: driverNavy.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const TabBar(
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Color(0xFF51627C),
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: driverNavy,
                            borderRadius: BorderRadius.all(Radius.circular(9)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x220D2B55),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          labelPadding: EdgeInsets.symmetric(vertical: 7),
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pending_actions_rounded, size: 12),
                                  SizedBox(width: 4),
                                  Text('Pending'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.task_alt_rounded, size: 12),
                                  SizedBox(width: 4),
                                  Text('Picked Up'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPendingTab(),
                            _buildPickedUpTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTodaySummary(Map<String, int> pending, Map<String, int> pickedUp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: DriverCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: driverNavy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.today_rounded, color: driverNavy, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: driverNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pending: ${pending['batches']} batches, ${pending['cylinders']} cylinders',
                    style: const TextStyle(fontSize: 11, color: driverMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Picked up: ${pickedUp['batches']} batches, ${pickedUp['cylinders']} cylinders',
                    style: const TextStyle(fontSize: 11, color: driverMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return DriverEmptyState(
        icon: Icons.inventory_2_outlined,
        message: 'No pending collections',
        actionText: 'Refresh',
        onAction: _loadPending,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: _pending.length,
            itemBuilder: (context, index) {
              final item = _pending[index];
              final selected = _selected[item.collectionReference] ?? false;
              final stationName = item.items.isNotEmpty
                  ? (item.items.first.cylinder.serviceStationName)
                  : 'Station ${item.serviceStationId}';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EDF5)),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  leading: Checkbox(
                    value: selected,
                    onChanged: (value) {
                      setState(() {
                        _selected[item.collectionReference] = value ?? false;
                      });
                    },
                    activeColor: driverNavy,
                  ),
                  title: Text(
                    item.collectionReference,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: driverNavy,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: const TextStyle(
                            color: driverMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.count} cylinder${item.count != 1 ? 's' : ''} • ${_formatDateTime(item.preparedAt)}',
                          style: const TextStyle(
                            color: driverNavy,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    if ((item.remarks ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Remarks: ${item.remarks}',
                          style: const TextStyle(
                            color: driverMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (item.items.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.items.map((c) {
                          final t = c.cylinder;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE8EDF5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: driverNavy.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.propane_tank, color: driverNavy, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.trackingCode ?? t.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${t.cylinderType?.name ?? "TW"} - ${t.capacity.toStringAsFixed(2)} ${t.unit}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: driverMuted,
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'BE ${c.bottomEdgeWeight} ${t.unit}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: driverNavy,
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
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: const Color(0xFFE8EDF5))),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : _confirmPickup,
                icon: _isConfirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isConfirming ? 'Confirming...' : 'Confirm Pickup',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: driverNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickedUpTab() {
    if (_pickedUp.isEmpty) {
      return DriverEmptyState(
        icon: Icons.check_circle_outline_rounded,
        message: 'No picked up collections',
        actionText: 'Refresh',
        onAction: _loadPending,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _pickedUp.length,
      itemBuilder: (context, index) {
        final item = _pickedUp[index];
        final stationName = item.items.isNotEmpty
            ? (item.items.first.cylinder.serviceStationName)
            : 'Station ${item.serviceStationId}';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            title: Text(
              item.collectionReference,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: driverNavy,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stationName,
                    style: const TextStyle(
                      color: driverMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.count} cylinder${item.count != 1 ? 's' : ''} • ${_formatDateTime(item.preparedAt)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              if ((item.remarks ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Remarks: ${item.remarks}',
                    style: const TextStyle(
                      color: driverMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              if (item.items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: item.items.map((c) {
                    final t = c.cylinder;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8EDF5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: driverNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.propane_tank, color: driverNavy, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                t.trackingCode ?? t.name,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${t.cylinderType?.name ?? "N/A"} • ${t.capacity.toStringAsFixed(0)} ${t.unit}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: driverMuted,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'BE ${c.bottomEdgeWeight} ${t.unit}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: driverNavy,
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
