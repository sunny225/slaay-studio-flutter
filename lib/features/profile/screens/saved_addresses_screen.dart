import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../auth/providers/auth_provider.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _flatController = TextEditingController();
  final _streetController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _flatController.dispose();
    _streetController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _handlePincodeChange(String pin) {
    if (pin.length == 6) {
      if (pin.startsWith('56')) {
        _cityController.text = 'Bengaluru';
        _stateController.text = 'Karnataka';
      } else if (pin.startsWith('11')) {
        _cityController.text = 'Delhi';
        _stateController.text = 'Delhi';
      } else if (pin.startsWith('40')) {
        _cityController.text = 'Mumbai';
        _stateController.text = 'Maharashtra';
      } else if (pin.startsWith('60')) {
        _cityController.text = 'Chennai';
        _stateController.text = 'Tamil Nadu';
      } else if (pin.startsWith('70')) {
        _cityController.text = 'Kolkata';
        _stateController.text = 'West Bengal';
      } else if (pin.startsWith('50')) {
        _cityController.text = 'Hyderabad';
        _stateController.text = 'Telangana';
      } else {
        _cityController.text = 'Mumbai';
        _stateController.text = 'Maharashtra';
      }
      setState(() {});
    }
  }

  void _showAddAddressDialog(BuildContext context, AuthProvider auth, bool isDarkMode) {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _flatController.clear();
    _streetController.clear();
    _pincodeController.clear();
    _cityController.clear();
    _stateController.clear();

    if (auth.userName != null && !auth.userName!.startsWith('User_')) {
      _nameController.text = auth.userName!;
    }
    if (auth.phoneNumber != null) {
      _phoneController.text = auth.phoneNumber!;
    }
    if (auth.email != null) {
      _emailController.text = auth.email!;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? AppColors.backgroundDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add New Address',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Recipient Full Name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Contact Phone'),
                              validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid 10-digit number' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Updates Email'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter email';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                                  return 'Enter valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _flatController,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Flat / House No. / Building'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter building' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _streetController,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: const InputDecoration(labelText: 'Area / Street / Locality'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter street' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Pincode', counterText: ''),
                              onChanged: (pin) {
                                _handlePincodeChange(pin);
                                setModalState(() {});
                              },
                              validator: (v) => v == null || v.trim().length != 6 ? 'Enter pincode' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'City'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stateController,
                        style: GoogleFonts.outfit(fontSize: 13),
                        decoration: const InputDecoration(labelText: 'State'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setModalState(() {
                                      _isSaving = true;
                                    });
                                    final successVal = await auth.updateProfile(
                                      name: _nameController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                      email: _emailController.text.trim(),
                                      flatHouseNo: _flatController.text.trim(),
                                      areaStreet: _streetController.text.trim(),
                                      city: _cityController.text.trim(),
                                      state: _stateController.text.trim(),
                                      pincode: _pincodeController.text.trim(),
                                    );
                                    setModalState(() {
                                      _isSaving = false;
                                    });
                                    if (successVal && context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('New address saved successfully!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      setState(() {});
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('SAVE ADDRESS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final addresses = authProvider.savedAddresses;

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: isDarkMode ? Colors.white : AppColors.primary,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'SAVED ADDRESSES',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddAddressDialog(context, authProvider, isDarkMode),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'ADD NEW ADDRESS',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedLocation01,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Addresses Found",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Add a shipping address to speed up checkout.",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final addr = addresses[index];
                        final isSelected = authProvider.activeAddress != null &&
                            authProvider.activeAddress!.flatHouseNo == addr.flatHouseNo &&
                            authProvider.activeAddress!.pincode == addr.pincode;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 0,
                          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : (isDarkMode ? Colors.white10 : AppColors.borderLight),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              children: [
                                Text(
                                  addr.fullName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ACTIVE',
                                      style: GoogleFonts.outfit(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    addr.fullAddressString,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phone: ${addr.phoneNumber}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Delete Address', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    content: const Text('Are you sure you want to remove this address?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('DELETE', style: TextStyle(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await authProvider.deleteAddress(addr);
                                  setState(() {});
                                }
                              },
                            ),
                            onTap: () async {
                              // Tap to set active
                              await authProvider.setActiveAddress(addr);
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
