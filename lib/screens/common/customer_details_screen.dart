import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/custom_button.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String title;
  final String? subtitle;

  const CustomerDetailsScreen({
    super.key,
    this.title = 'Customer Details',
    this.subtitle,
  });

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchPhoneController = TextEditingController();
  final TextEditingController _searchNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _customerType = 'Individual';

  Customer? _selectedCustomer;
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showNewCustomerForm = false;
  bool _showSearchResults = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchPhoneController.dispose();
    _searchNameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchCustomers() async {
    final phone = _searchPhoneController.text.trim();
    final name = _searchNameController.text.trim();

    if (phone.isEmpty && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number or name to search'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Build search query - combine phone and name if both provided
      String searchQuery = '';
      if (phone.isNotEmpty && name.isNotEmpty) {
        searchQuery = '$phone $name';
      } else if (phone.isNotEmpty) {
        searchQuery = phone;
      } else {
        searchQuery = name;
      }

      final customers = await _customerService.getCustomers(
        searchQuery: searchQuery,
        token: token,
      );

      setState(() {
        _isSearching = false;
        _searchResults = customers;

        if (customers.isEmpty) {
          // No customer found, show new customer form
          _selectedCustomer = null;
          _showSearchResults = false;
          _showNewCustomerForm = true;
          _nameController.text = name;
          _phoneController.text = phone;
          _customerType = 'Individual';
        } else if (customers.length == 1) {
          // Single customer found, auto-select
          _selectedCustomer = customers.first;
          _showSearchResults = false;
          _showNewCustomerForm = false;
          _populateCustomerData(_selectedCustomer!);
        } else {
          // Multiple customers found, show selection list
          _selectedCustomer = null;
          _showSearchResults = true;
          _showNewCustomerForm = false;
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _selectedCustomer = null;
        _searchResults = [];
        _showSearchResults = false;
        _showNewCustomerForm = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateCustomerData(Customer customer) {
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _customerType = customer.customerType.isNotEmpty
        ? customer.customerType
        : 'Individual';
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _showSearchResults = false;
      _showNewCustomerForm = false;
      _populateCustomerData(customer);
    });
  }

  void _skipCustomerDetails() {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    // Return empty data to proceed to transaction without customer details
    Navigator.of(context).pop({
      'customerId': null,
      'customerData': null,
    });
  }

  void _cancelTransaction() {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    // Pop back to amount input screen (2 screens back)
    // This will take user from: CustomerDetails -> PaymentMethod -> AmountInput
    Navigator.of(context).popUntil((route) {
      // Check if we've reached the amount input screen or if we've gone back enough
      return route.settings.name == '/amount_input' ||
             !Navigator.of(context).canPop();
    });
  }

  void _confirmCustomerDetails() {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    if (_selectedCustomer != null) {
      // Return existing customer ID
      Navigator.of(context).pop({
        'customerId': _selectedCustomer!.id,
        'customerData': null,
      });
    } else if (_showNewCustomerForm) {
      // Validate new customer form
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter customer name'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (phone.isEmpty) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a phone number'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Return new customer data
      Navigator.of(context).pop({
        'customerId': null,
        'customerData': CustomerData(
          name: name,
          email: '',
          phone: phone,
          customerType: _customerType,
        ),
      });
    } else {
      // No customer selected and form not shown - just skip
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the confirm button
    final showConfirmButton = _selectedCustomer != null || _showNewCustomerForm;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.subtitle != null) ...[
                Text(
                  widget.subtitle!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
              ],

              // Search section header
              const Text(
                'Search for Existing Customer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Name search field
              TextField(
                controller: _searchNameController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'Enter customer name',
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person_search, color: AppColors.primary),
                ),
                onChanged: (value) {
                  if (value.isEmpty && _searchPhoneController.text.isEmpty) {
                    setState(() {
                      _selectedCustomer = null;
                      _showNewCustomerForm = false;
                      _showSearchResults = false;
                      _searchResults = [];
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              // Phone number search
              TextField(
                controller: _searchPhoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'Enter phone number',
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                ),
                onChanged: (value) {
                  if (value.isEmpty && _searchNameController.text.isEmpty) {
                    setState(() {
                      _selectedCustomer = null;
                      _showNewCustomerForm = false;
                      _showSearchResults = false;
                      _searchResults = [];
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Search button
              CustomButton(
                onPressed: _isSearching ? null : _searchCustomers,
                backgroundColor: AppColors.primary,
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Search Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // Continue without customer button (default, always visible)
              if (!showConfirmButton) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _skipCustomerDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[300]!, width: 1.5),
                      backgroundColor: Colors.blue[50],
                      disabledForegroundColor: Colors.blue[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 20,
                          color: _isProcessing ? Colors.blue[400] : Colors.blue[700],
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue without customer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _isProcessing ? Colors.blue[400] : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Multiple search results
              if (_showSearchResults && _searchResults.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue.shade700, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Found ${_searchResults.length} Customer(s)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Select a customer:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final customer = _searchResults[index];
                          return InkWell(
                            onTap: () => _selectCustomer(customer),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          customer.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: Colors.grey[600]),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.phone, color: Colors.grey[600], size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        customer.phone,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.category, color: Colors.grey[600], size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        customer.customerType,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Existing customer found
              if (_selectedCustomer != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'Customer Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Name', _selectedCustomer!.name),
                      _buildInfoRow('Phone', _selectedCustomer!.phone),
                      _buildInfoRow('Type', _selectedCustomer!.customerType),
                    ],
                  ),
                ),
              ],

              // New customer form
              if (_showNewCustomerForm && _selectedCustomer == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.blue.shade700, size: 28),
                          const SizedBox(width: 12),
                          const Text(
                            'New Customer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name field
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Name *',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white,
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
                          prefixIcon: const Icon(Icons.person, color: Colors.black54),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Phone number field
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Phone Number *',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white,
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
                          prefixIcon: const Icon(Icons.phone, color: Colors.black54),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Customer type dropdown
                      DropdownButtonFormField<String>(
                        value: _customerType,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Customer Type',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.white,
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
                          prefixIcon: const Icon(Icons.category, color: Colors.black54),
                        ),
                        items: ['Individual', 'Corporate'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _customerType = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],

              // Confirm button (only show after search)
              if (showConfirmButton) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _confirmCustomerDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Confirm & Continue',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Cancel button - takes user back to amount input screen
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _cancelTransaction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!, width: 1.5),
                    backgroundColor: Colors.red[50],
                    disabledForegroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        size: 20,
                        color: _isProcessing ? Colors.grey[400] : Colors.red[700],
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Cancel Transaction',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _isProcessing ? Colors.grey[400] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
