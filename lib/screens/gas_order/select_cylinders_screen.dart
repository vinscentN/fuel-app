import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_tank.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';

class SelectCylindersScreen extends StatefulWidget {
  const SelectCylindersScreen({Key? key}) : super(key: key);

  @override
  State<SelectCylindersScreen> createState() => _SelectCylindersScreenState();
}

class _SelectCylindersScreenState extends State<SelectCylindersScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  final TextEditingController _descriptionController = TextEditingController();

  List<GasTank> _tanks = [];
  Map<int, bool> _selectedTanks = {};
  Map<int, TextEditingController> _weightControllers = {};

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTanks();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        _tanks = tanks;
        _selectedTanks = {for (var tank in tanks) tank.id: false};
        _weightControllers = {
          for (var tank in tanks) tank.id: TextEditingController()
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
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

    // Validate weights
    List<Map<String, dynamic>> tanksData = [];
    for (var tankId in selectedTankIds) {
      final weightText = _weightControllers[tankId]?.text.trim() ?? '';
      final normalized = weightText.replaceAll(',', '.');
      final weight = double.tryParse(normalized);

      if (weightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter bottom edge weight for ${_tanks.firstWhere((t) => t.id == tankId).name}',
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
              'Invalid weight for ${_tanks.firstWhere((t) => t.id == tankId).name}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      tanksData.add({
        'gas_tank_id': tankId,
        'manual_bottom_edge_weight': weight,
      });
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      final token = authProvider.token;

      if (user == null || token == null) {
        throw Exception('Not authenticated');
      }

      await _gasOrderService.createFillRequest(
        siteId: user.serviceStationId,
        description: _descriptionController.text.trim(),
        createdBy: user.name,
        tanks: tanksData,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fill request created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Cylinders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
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
              : _tanks.isEmpty
                  ? const Center(
                      child: Text(
                        'No cylinders available',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: const TextStyle(color: Colors.black54),
                              hintText: 'e.g., Weekly refill batch',
                              hintStyle: const TextStyle(color: Colors.black38),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.description, color: Colors.black54),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tanks.length,
                            itemBuilder: (context, index) {
                              final tank = _tanks[index];
                              final isSelected = _selectedTanks[tank.id] ?? false;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: Colors.white,
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey[300]!,
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
                                            activeColor: Colors.blue,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tank.name,
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
                                            labelText: 'Bottom Edge Weight (${tank.unit})',
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
                                              borderSide: const BorderSide(color: Colors.blue, width: 2),
                                            ),
                                            prefixIcon: const Icon(Icons.scale, color: Colors.black54),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitRequest,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
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
                                        'Create Fill Request',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
