import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';

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
  bool _showCustomerCapture = false;

  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

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
      _showSnack('Please enter a phone number or name to search',
          isError: true);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Not authenticated');

      String q = phone.isNotEmpty && name.isNotEmpty
          ? '$phone $name'
          : phone.isNotEmpty
          ? phone
          : name;

      final customers =
      await _customerService.getCustomers(searchQuery: q, token: token);

      setState(() {
        _isSearching = false;
        _searchResults = customers;

        if (customers.isEmpty) {
          _selectedCustomer = null;
          _showSearchResults = false;
          _showNewCustomerForm = true;
          _nameController.text = name;
          _phoneController.text = phone;
          _customerType = 'Individual';
        } else if (customers.length == 1) {
          _selectedCustomer = customers.first;
          _showSearchResults = false;
          _showNewCustomerForm = false;
          _populateCustomerData(_selectedCustomer!);
        } else {
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
      if (mounted) _showSnack('Search failed: ${e.toString()}', isError: true);
    }
  }

  void _populateCustomerData(Customer customer) {
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _customerType =
    customer.customerType.isNotEmpty ? customer.customerType : 'Individual';
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _showSearchResults = false;
      _showNewCustomerForm = false;
      _showCustomerCapture = true;
      _populateCustomerData(customer);
    });
  }

  void _skipCustomerDetails() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    Navigator.of(context).pop({'customerId': null, 'customerData': null});
  }

  void _cancelTransaction() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    Navigator.of(context).popUntil((route) {
      return route.settings.name == '/amount_input' ||
          !Navigator.of(context).canPop();
    });
  }

  void _confirmCustomerDetails() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (_selectedCustomer != null) {
      Navigator.of(context)
          .pop({'customerId': _selectedCustomer!.id, 'customerData': null});
    } else if (_showNewCustomerForm) {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      if (name.isEmpty) {
        setState(() => _isProcessing = false);
        _showSnack('Please enter customer name', isError: true);
        return;
      }
      if (phone.isEmpty) {
        setState(() => _isProcessing = false);
        _showSnack('Please enter a phone number', isError: true);
        return;
      }

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
      Navigator.of(context).pop(null);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showConfirmButton =
        _selectedCustomer != null || _showNewCustomerForm;

    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Continue without customer ──
              _buildContinueButton(),
              const SizedBox(height: 10),

              // ── Optional customer section ──
              _buildCustomerSection(showConfirmButton),
              const SizedBox(height: 10),

              // ── Cancel ──
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
            bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0x99FFFFFF),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Continue button ───────────────────────────────────────

  Widget _buildContinueButton() {
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isProcessing ? null : _skipCustomerDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Without Customer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Skip and proceed to transaction',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Customer capture section ──────────────────────────────

  Widget _buildCustomerSection(bool showConfirmButton) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _showCustomerCapture,
          onExpansionChanged: (v) =>
              setState(() => _showCustomerCapture = v),
          tilePadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
            const Icon(Icons.person_search_rounded, color: _navy, size: 17),
          ),
          title: const Text(
            'Add Customer Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          subtitle: const Text(
            'Optional — search or create a customer',
            style: TextStyle(fontSize: 11, color: _navyMuted),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          children: [
            const Divider(height: 1, color: Color(0xFFEEF2F8)),
            const SizedBox(height: 12),
            _sectionLabel('SEARCH EXISTING CUSTOMER'),
            const SizedBox(height: 8),
            _navyTextField(
              controller: _searchNameController,
              label: 'Customer Name',
              hint: 'Enter name',
              icon: Icons.person_rounded,
              onChanged: (v) {
                if (v.isEmpty && _searchPhoneController.text.isEmpty) {
                  setState(() {
                    _selectedCustomer = null;
                    _showNewCustomerForm = false;
                    _showSearchResults = false;
                    _searchResults = [];
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            _navyTextField(
              controller: _searchPhoneController,
              label: 'Phone Number',
              hint: 'Enter phone',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              onChanged: (v) {
                if (v.isEmpty && _searchNameController.text.isEmpty) {
                  setState(() {
                    _selectedCustomer = null;
                    _showNewCustomerForm = false;
                    _showSearchResults = false;
                    _searchResults = [];
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton.icon(
                onPressed: _isSearching ? null : _searchCustomers,
                style: TextButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _navy.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                icon: _isSearching
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  _isSearching ? 'Searching...' : 'Search Customer',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // ── Multiple results ──
            if (_showSearchResults && _searchResults.isNotEmpty) ...[
              const SizedBox(height: 14),
              _resultsBanner(
                  '${_searchResults.length} customers found — tap to select'),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 6),
                itemBuilder: (context, i) =>
                    _customerResultTile(_searchResults[i]),
              ),
            ],

            // ── Customer found ──
            if (_selectedCustomer != null) ...[
              const SizedBox(height: 14),
              _customerFoundCard(_selectedCustomer!),
            ],

            // ── New customer form ──
            if (_showNewCustomerForm && _selectedCustomer == null) ...[
              const SizedBox(height: 14),
              _newCustomerForm(),
            ],

            // ── Confirm ──
            if (showConfirmButton) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton.icon(
                  onPressed:
                  _isProcessing ? null : _confirmCustomerDetails,
                  style: TextButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _navy.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: const Text(
                    'Use Customer & Continue',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Cancel button ─────────────────────────────────────────

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton.icon(
        onPressed: _isProcessing ? null : _cancelTransaction,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFCC3333),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFEEC0C0)),
          ),
          backgroundColor: const Color(0xFFFFF5F5),
        ),
        icon: const Icon(Icons.cancel_outlined, size: 17),
        label: const Text(
          'Cancel Transaction',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: _navyMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _resultsBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _navy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _navy.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_rounded, color: _navy, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: _navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerResultTile(Customer customer) {
    return Material(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => _selectCustomer(customer),
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                const Icon(Icons.person_rounded, color: _navy, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _navy)),
                    Text(customer.phone,
                        style: const TextStyle(
                            fontSize: 11, color: _navyMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _navyMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerFoundCard(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB6DFC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2ECC71), size: 16),
              const SizedBox(width: 6),
              const Text(
                'Customer Found',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A7A40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('Name', customer.name),
          _infoRow('Phone', customer.phone),
          _infoRow('Type', customer.customerType),
        ],
      ),
    );
  }

  Widget _newCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultsBanner('No customer found — fill in details below'),
        const SizedBox(height: 10),
        _navyTextField(
          controller: _nameController,
          label: 'Name *',
          hint: 'Full name',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 8),
        _navyTextField(
          controller: _phoneController,
          label: 'Phone Number *',
          hint: 'e.g. 0771234567',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _customerType,
          style: const TextStyle(color: _navy, fontSize: 13),
          decoration: _navyInputDecoration(
              label: 'Customer Type', icon: Icons.category_rounded),
          items: ['Individual', 'Corporate']
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _customerType = v);
          },
        ),
      ],
    );
  }

  Widget _navyTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _navy, fontSize: 13),
      onChanged: onChanged,
      decoration: _navyInputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _navyInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
      const TextStyle(color: _navyMuted, fontSize: 12),
      hintStyle:
      const TextStyle(color: Color(0xFFBBCCDD), fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      prefixIcon: Icon(icon, color: _navyMuted, size: 18),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _navyMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: _navy),
            ),
          ),
        ],
      ),
    );
  }
}