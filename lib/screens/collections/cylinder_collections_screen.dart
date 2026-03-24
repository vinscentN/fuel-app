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
  State<CylinderCollectionsScreen> createState() =>
      _CylinderCollectionsScreenState();
}

class _CylinderCollectionsScreenState
    extends State<CylinderCollectionsScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  List<GasTank> _tanks = [];
  Map<int, bool> _selectedTanks = {};
  Map<int, TextEditingController> _weightControllers = {};
  List<SiteCollectionGroup> _pendingGroups = [];
  List<SiteCollectionGroup> _pickedUpGroups = [];

  bool _isLoadingTanks = true;
  bool _isSubmitting = false;
  bool _isLoadingCollections = true;
  String? _errorTanks;
  String? _errorCollections;

  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();
    _loadTanks();
    _loadCollections();
  }

  @override
  void dispose() {
    for (final c in _weightControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadTanks() async {
    setState(() { _isLoadingTanks = true; _errorTanks = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;
      if (user == null || token == null) throw Exception('Not authenticated');
      final tanks = await _gasOrderService.getTanksForStation(user.serviceStationId, token);
      setState(() {
        _tanks = tanks;
        _selectedTanks = {for (final t in tanks) t.id: false};
        _weightControllers = {for (final t in tanks) t.id: TextEditingController()};
        _isLoadingTanks = false;
      });
    } catch (e) {
      setState(() { _errorTanks = e.toString().replaceAll('Exception: ', ''); _isLoadingTanks = false; });
    }
  }

  Future<void> _loadCollections() async {
    setState(() { _isLoadingCollections = true; _errorCollections = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;
      if (user == null || token == null) throw Exception('Not authenticated');
      final pending = await _gasOrderService.getSiteCollectionsPendingGrouped(token);
      final pickedUp = await _gasOrderService.getSiteCollectionsPickedUpGrouped(token);

      List<SiteCollectionGroup> sortAndFilter(List<SiteCollectionGroup> groups) {
        return groups.where((c) {
        final sameStation = user.serviceStationId == 0 || c.serviceStationId == user.serviceStationId;
        return sameStation && c.preparedByAttendantId == user.id;
      }).toList()
          ..sort((a, b) {
          final ad = a.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.preparedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });
      }

      setState(() {
        _pendingGroups = sortAndFilter(pending);
        _pickedUpGroups = sortAndFilter(pickedUp);
        _isLoadingCollections = false;
      });
    } catch (e) {
      setState(() { _errorCollections = e.toString().replaceAll('Exception: ', ''); _isLoadingCollections = false; });
    }
  }

  double _parseWeight(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0;

  Future<void> _submitCollections() async {
    final selectedIds = _selectedTanks.entries.where((e) => e.value).map((e) => e.key).toList();
    if (selectedIds.isEmpty) {
      _showSnack('Please select at least one cylinder', isError: true);
      return;
    }
    final cylinders = <Map<String, dynamic>>[];
    for (final id in selectedIds) {
      final text = _weightControllers[id]?.text.trim() ?? '';
      final tank = _tanks.firstWhere((t) => t.id == id);
      if (text.isEmpty) { _showSnack('Please enter weight for ${tank.trackingCode ?? tank.name}', isError: true); return; }
      final w = _parseWeight(text);
      if (w <= 0) { _showSnack('Invalid weight for ${tank.trackingCode ?? tank.name}', isError: true); return; }
      cylinders.add({'cylinder_id': id, 'current_weight': w});
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final token = auth.token;
      if (user == null || token == null) throw Exception('Not authenticated');
      await _gasOrderService.createSiteCollections(
        serviceStationId: user.serviceStationId,
        preparedByAttendantId: user.id,
        remarks: _buildRemarks(),
        cylinders: cylinders,
        token: token,
      );
      if (mounted) {
        _showSnack('Cylinder collections prepared successfully');
        for (final id in selectedIds) { _selectedTanks[id] = false; _weightControllers[id]?.clear(); }
        setState(() {});
        await _loadCollections();
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _buildRemarks() {
    final now = DateTime.now().toLocal();
    return 'Daily Collection - ${now.year}-${_p(now.month)}-${_p(now.day)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return const Color(0xFFE67E22);
      case 'PICKED_UP': return const Color(0xFF2ECC71);
      default: return _navyMuted;
    }
  }

  Color _statusBg(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return const Color(0xFFFFF4DC);
      case 'PICKED_UP': return const Color(0xFFDFF7EC);
      default: return const Color(0xFFF0F4FA);
    }
  }

  String _formatDt(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    return '${_p(d.day)}/${_p(d.month)}/${d.year} ${_p(d.hour)}:${_p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(),
      body: _isLoadingTanks
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _navy))
          : _errorTanks != null
          ? _buildErrorState(_errorTanks!, _loadTanks)
          : _tanks.isEmpty
          ? _buildEmptyState()
          : _buildBody(),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(bottom: BorderSide(color: Color(0x22FFFFFF), width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  splashRadius: 20,
                ),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.propane_tank_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cylinder Collections',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white, letterSpacing: -0.2)),
                      Text('Prepare cylinders for refill',
                          style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () { _loadTanks(); _loadCollections(); },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  splashRadius: 20,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instruction
          _sectionLabel('SELECT CYLINDERS'),
          const SizedBox(height: 4),
          const Text(
            'Tick empty cylinders ready for refill and enter their current weight.',
            style: TextStyle(fontSize: 12, color: _navyMuted, height: 1.4),
          ),
          const SizedBox(height: 10),

          // Tank list
          ...List.generate(_tanks.length, (i) {
            final tank = _tanks[i];
            final isSelected = _selectedTanks[tank.id] ?? false;
            final weightText = _weightControllers[tank.id]?.text.trim() ?? '';
            final current = weightText.isEmpty ? 0.0 : _parseWeight(weightText);
            final bottomEdge = weightText.isEmpty ? 0.0 : current - tank.capacity;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTankCard(tank, isSelected, weightText, current, bottomEdge),
            );
          }),

          const SizedBox(height: 6),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: _isSubmitting ? null : _submitCollections,
              style: TextButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _navy.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(_isSubmitting ? 'Submitting...' : 'Prepare Collections',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),

          const SizedBox(height: 20),

          // My Collections
          _sectionLabel('MY COLLECTIONS'),
          const SizedBox(height: 8),
          _buildCollectionsList(),
        ],
      ),
    );
  }

  // ── Tank card ─────────────────────────────────────────────

  Widget _buildTankCard(GasTank tank, bool isSelected, String weightText,
      double current, double bottomEdge) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _navy : const Color(0xFFE8EDF5),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => setState(() => _selectedTanks[tank.id] = !isSelected),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (v) => setState(() => _selectedTanks[tank.id] = v ?? false),
                      activeColor: _navy,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Icon
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? _navy.withOpacity(0.07) : const Color(0xFFF0F4FA),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.propane_tank_rounded,
                        color: isSelected ? _navy : _navyMuted, size: 17),
                  ),
                  const SizedBox(width: 10),
                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tank.trackingCode ?? tank.name,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: isSelected ? _navy : const Color(0xFF2A3A50),
                          ),
                        ),
                        Text(
                          '${tank.cylinderType?.name ?? 'N/A'} · ${tank.capacity.toStringAsFixed(0)} ${tank.unit}',
                          style: const TextStyle(fontSize: 11, color: _navyMuted),
                        ),
                      ],
                    ),
                  ),
                  if (tank.product?.productType?.name != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _navy.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tank.product!.productType!.name,
                        style: const TextStyle(fontSize: 10, color: _navy, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Weight input (expanded when selected)
          if (isSelected) ...[
            const Divider(height: 1, color: Color(0xFFF0F4FA)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  // Weight field
                  TextField(
                    controller: _weightControllers[tank.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: _navy, fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Current Weight (${tank.unit})',
                      labelStyle: const TextStyle(color: _navyMuted, fontSize: 12),
                      hintText: '0.00',
                      hintStyle: const TextStyle(color: Color(0xFFBBCCDD), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: Color(0xFFE0E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: Color(0xFFE0E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: const BorderSide(color: _navy, width: 1.5),
                      ),
                      prefixIcon: const Icon(Icons.scale_rounded, color: _navyMuted, size: 17),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tare / Bottom edge
                  Row(
                    children: [
                      _weightChip('Tare', '${tank.capacity.toStringAsFixed(2)} ${tank.unit}',
                          const Color(0xFFF0F4FA), _navyMuted),
                      const SizedBox(width: 8),
                      _weightChip('Bottom Edge', '${bottomEdge.toStringAsFixed(2)} ${tank.unit}',
                          _navy.withOpacity(0.07), _navy),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _weightChip(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: fg.withOpacity(0.6), letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }

  // ── Collections list ──────────────────────────────────────

  Widget _buildCollectionsList() {
    if (_isLoadingCollections) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2, color: _navy),
          ));
    }
    if (_errorCollections != null) {
      return _buildErrorState(_errorCollections!, _loadCollections);
    }
    if (_pendingGroups.isEmpty && _pickedUpGroups.isEmpty) {
      return _buildCollectionsEmptyState('No collections available');
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: const TabBar(
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: _navyMuted,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.all(Radius.circular(9)),
              ),
              labelPadding: EdgeInsets.symmetric(vertical: 7),
              labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Picked Up'),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _buildCollectionsTab(_pendingGroups, 'No pending collections'),
                _buildCollectionsTab(_pickedUpGroups, 'No picked up collections'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsTab(List<SiteCollectionGroup> groups, String emptyMessage) {
    if (groups.isEmpty) {
      return _buildCollectionsEmptyState(emptyMessage);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: groups.map((group) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildGroupCard(group),
      )).toList(),
    );
  }

  Widget _buildCollectionsEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: _navyMuted),
        ),
      ),
    );
  }

  Widget _buildGroupCard(SiteCollectionGroup group) {
    final stationName = group.items.isNotEmpty
        ? group.items.first.cylinder.serviceStationName
        : 'Station ${group.serviceStationId}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _statusBg(group.status),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.inventory_2_rounded,
                    color: _statusColor(group.status), size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.collectionReference,
                        style: const TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w700, color: _navy)),
                    Text(
                      '${group.count} cylinder${group.count != 1 ? 's' : ''} · ${_formatDt(group.preparedAt)}',
                      style: const TextStyle(fontSize: 11, color: _navyMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusBg(group.status),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  group.status,
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: _statusColor(group.status),
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFF0F4FA)),
            const SizedBox(height: 10),
            if ((group.remarks ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notes_rounded, size: 13, color: _navyMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(group.remarks!,
                          style: const TextStyle(fontSize: 11, color: _navyMuted)),
                    ),
                  ],
                ),
              ),
            ...group.items.map((c) {
              final t = c.cylinder;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFE8EDF5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.propane_tank_rounded,
                            color: _navy, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.trackingCode ?? t.name,
                                style: const TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w700, color: _navy)),
                            Text(
                              '${t.cylinderType?.name ?? 'N/A'} · ${t.capacity.toStringAsFixed(0)} ${t.unit}',
                              style: const TextStyle(fontSize: 10, color: _navyMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${c.currentWeight} ${t.unit}',
                              style: const TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w700, color: _navy)),
                          Text('BE ${c.bottomEdgeWeight} ${t.unit}',
                              style: const TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w600, color: _navyMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── State widgets ─────────────────────────────────────────

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.propane_tank_outlined,
                    color: _navyMuted, size: 22),
              ),
              const SizedBox(height: 12),
              const Text('Unable to Load',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _navy)),
              const SizedBox(height: 6),
              Text(message,
                  style: const TextStyle(fontSize: 12, color: _navyMuted, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity, height: 40,
                child: TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    backgroundColor: _navy, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No cylinders available',
          style: TextStyle(fontSize: 13, color: _navyMuted)),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: _navyMuted, letterSpacing: 1.1,
      ),
    );
  }
}
