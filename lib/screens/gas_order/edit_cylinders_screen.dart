import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_tank.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import 'confirm_cylinders_screen.dart';

class EditCylindersScreen extends StatefulWidget {
  final PendingGasOrder order;

  const EditCylindersScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<EditCylindersScreen> createState() => _EditCylindersScreenState();
}

class _EditCylindersScreenState extends State<EditCylindersScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  final TextEditingController _searchController = TextEditingController();

  List<GasTank> _allTanks = [];
  List<GasTank> _filteredTanks = [];
  Map<int, bool> _selectedTanks = {};
  Map<int, TextEditingController> _weightControllers = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTanks();
    _searchController.addListener(_filterTanks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _filterTanks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTanks = _allTanks;
      } else {
        _filteredTanks = _allTanks.where((tank) {
          return tank.name.toLowerCase().contains(query) ||
              (tank.trackingCode?.toLowerCase().contains(query) ?? false) ||
              (tank.cylinderType?.name.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadTanks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final token = authProvider.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      final tanks = await _gasOrderService.getTanksForStation(
        user.serviceStationId,
        token,
      );

      setState(() {
        _allTanks = tanks;
        _filteredTanks = tanks;
        _selectedTanks = {for (var tank in tanks) tank.id: false};
        _weightControllers = {
          for (var tank in tanks) tank.id: TextEditingController()
        };

        // Pre-populate existing cylinder data if available
        if (widget.order.itemsPreview.isNotEmpty) {
          for (var preview in widget.order.itemsPreview) {
            // Mark as selected
            if (_selectedTanks.containsKey(preview.tankId)) {
              _selectedTanks[preview.tankId] = true;
              // Pre-fill weight
              _weightControllers[preview.tankId]?.text = preview.bottomWeight;
            }
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToConfirmation() {
    // Validate selection
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

    // Validate weights and collect data
    List<Map<String, dynamic>> displayData = [];

    for (var tankId in selectedTankIds) {
      final tank = _allTanks.firstWhere((t) => t.id == tankId);
      final weightText = _weightControllers[tankId]?.text.trim() ?? '';
      final normalized = weightText.replaceAll(',', '.');
      final weight = double.tryParse(normalized);

      if (weightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter before refill weight for ${tank.trackingCode ?? tank.name}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid weight for ${tank.trackingCode ?? tank.name}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      displayData.add({
        'tank': tank,
        'weight': weight,
      });
    }

    // Navigate to confirmation screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmCylindersScreen(
          order: widget.order,
          cylindersData: displayData,
        ),
      ),
    );
  }

  int get _selectedCount => _selectedTanks.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.order.tanksCount > 0 ? 'Edit Cylinders' : 'Add Cylinders',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
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
              : _allTanks.isEmpty
                  ? const Center(
                      child: Text(
                        'No cylinders available',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : Column(
                      children: [
                        // Compact header with request info
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.order.requestCode,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.order.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$_selectedCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Search bar - Cleaner design
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by serial number...',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Cylinder list
                        Expanded(
                          child: _filteredTanks.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No cylinders found',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredTanks.length,
                                  itemBuilder: (context, index) {
                                    final tank = _filteredTanks[index];
                                    final isSelected = _selectedTanks[tank.id] ?? false;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey[200]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(0.1)
                                                : Colors.black.withOpacity(0.02),
                                            blurRadius: isSelected ? 8 : 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedTanks[tank.id] = !isSelected;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            children: [
                                              Row(
                                                children: [
                                                  // Custom checkbox
                                                  Container(
                                                    width: 22,
                                                    height: 22,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : Colors.transparent,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : Colors.grey[300]!,
                                                        width: 2,
                                                      ),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: isSelected
                                                        ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 16,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  // Cylinder info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          tank.trackingCode ?? tank.name,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: isSelected
                                                                ? AppColors.primary
                                                                : Colors.black87,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 3),
                                                        Text(
                                                          '${tank.cylinderType?.name ?? "N/A"} • ${tank.capacity.toStringAsFixed(0)} ${tank.unit}',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Status indicator
                                                  if (isSelected)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.success.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'Selected',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.success,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              // Weight input
                                              if (isSelected) ...[
                                                const SizedBox(height: 12),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF8F9FB),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: TextField(
                                                    controller: _weightControllers[tank.id],
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: 'Before refill weight',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontWeight: FontWeight.normal,
                                                      ),
                                                      prefixIcon: Icon(
                                                        Icons.scale,
                                                        color: Colors.grey[400],
                                                        size: 20,
                                                      ),
                                                      suffixText: tank.unit,
                                                      suffixStyle: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        // Submit button - Modern gradient design
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.modernGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _navigateToConfirmation,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continue',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
