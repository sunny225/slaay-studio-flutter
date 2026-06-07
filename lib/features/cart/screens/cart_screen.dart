import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../providers/cart_provider.dart';
import '../../profile/models/order.dart';
import '../../../services/order_service.dart';
import '../../profile/screens/order_tracking_screen.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/login_bottom_sheet.dart';
import '../../../core/widgets/smooth_page_route.dart';

class CartScreen extends StatefulWidget {
  final bool isPrimaryTab;
  const CartScreen({super.key, this.isPrimaryTab = false});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final _addressFormKey = GlobalKey<FormState>();
  
  // Address controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _flatController = TextEditingController();
  final _streetController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  ShippingAddress? _selectedAddress;
  bool _isCheckingOut = false;
  bool _showAddRecipientForm = false;
  
  final _couponController = TextEditingController();
  bool _isApplyingCoupon = false;
  String? _couponErrorMessage;
  String? _couponSuccessMessage;

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
    _couponController.dispose();
    super.dispose();
  }


  void _handlePincodeChange(String pin) {
    if (pin.length == 6) {
      // Mock Indian pincode auto lookup
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

  bool _isDisposableOrTestEmail(String email) {
    final emailClean = email.trim().toLowerCase();
    
    // 1. Common placeholder/test emails list
    final testEmails = {
      'test@test.com',
      'test@example.com',
      'example@example.com',
      'admin@admin.com',
      'demo@demo.com',
      'test@gmail.com',
      'feedback@feedback.com'
    };
    if (testEmails.contains(emailClean)) {
      return true;
    }

    final parts = emailClean.split('@');
    if (parts.length != 2) return true;
    final username = parts[0];
    final domain = parts[1];
    
    final domainParts = domain.split('.');
    if (domainParts.length < 2) return true;
    final domainName = domainParts[0];

    // 2. Known temporary / disposable domains & typos
    final disposableDomains = {
      'tempmail.com', 'temp-mail.org', 'mailinator.com', 'yopmail.com', 
      'guerrillamail.com', 'sharklasers.com', 'dispostable.com', 
      'getairmail.com', '10minutemail.com', '10minutemail.co.za', 
      'maildrop.cc', 'throwawaymail.com', 'tempmailaddress.com', 
      'fakeinbox.com', 'burnermail.io', 'mailnesia.com', 'generator.email',
      'disposable.com', 'test.com', 'example.com', 'demo.com', 'admin.com',
      'testing.com', 'fake.com', 'dummy.com', 'tesy.com', 'tst.com', 
      'tes.com', 'tets.com', 'gamil.com', 'gmal.com', 'gmaill.com', 
      'gml.com', 'yaho.com', 'yhoo.com', 'hotail.com', 'hotmial.com', 
      'outlok.com', 'outllok.com', 'iclud.com'
    };

    if (disposableDomains.contains(domain)) {
      return true;
    }

    if (domain.contains('tempmail') || domain.contains('temp-mail') || domain.contains('disposable')) {
      return true;
    }

    // 3. Placeholder keywords inside username or domain name
    final placeholders = {
      'test', 'temp', 'fake', 'dummy', 'guest', 'random', 'garbage', 
      'testing', 'trial', 'demo', 'example', 'noreply', 'no-reply'
    };
    for (final placeholder in placeholders) {
      if (username == placeholder || username.startsWith('$placeholder.') || username.endsWith('.$placeholder')) {
        return true;
      }
      if (domainName == placeholder || domainName.contains(placeholder)) {
        return true;
      }
    }

    // 4. Keyboard walks or sequential/mashed strings
    final keyboardWalks = {'asdf', 'qwer', 'zxcv', 'qwert', 'asdfg', 'zxcvb', '1234', 'abcd', 'ghjk', 'uiop'};
    for (final walk in keyboardWalks) {
      if (username.contains(walk) || domainName.contains(walk)) {
        return true;
      }
    }

    // 5. Repeated characters in username (e.g. aaaa@...)
    if (RegExp(r'([a-zA-Z0-9])\1{3,}').hasMatch(username)) {
      return true;
    }

    // 6. Whitelist check for known non-vowel domains (like bbc) before no-vowel check
    final isWhitelistedDomain = {'bbc.com', 'bbc.co.uk', 'cnn.com', 'dhl.com', 'h&m.com', 'hm.com'}.contains(domain);
    if (!isWhitelistedDomain && domainName.length >= 4 && !RegExp(r'[aeiouy]', caseSensitive: false).hasMatch(domainName)) {
      return true;
    }

    // 7. Typos of major providers starting with or containing specific patterns
    if ((domainName.startsWith('tes') || domainName.startsWith('tst')) && !{'tesla', 'tesco'}.contains(domainName)) {
      return true;
    }

    final domainTypoPatterns = [
      RegExp(r'^g[am]*il+\.com$'),
      RegExp(r'^y[ah]*o+\.com$'),
      RegExp(r'^hot[am]*il\.com$'),
      RegExp(r'^outl[o]*k\.com$'),
      RegExp(r'^icl[u]*d\.com$'),
    ];
    final correctSpellings = {'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com', 'icloud.com'};
    for (final pattern in domainTypoPatterns) {
      if (pattern.hasMatch(domain) && !correctSpellings.contains(domain)) {
        return true;
      }
    }

    return false;
  }

  bool _hasSavedAddress(AuthProvider auth) {
    final address = _selectedAddress ?? auth.activeAddress;
    if (address == null) return false;
    return address.phoneNumber.isNotEmpty;
  }

  Widget _buildSavedAddressCard(AuthProvider auth, bool isDarkMode) {
    final address = _selectedAddress ?? auth.activeAddress!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? AppColors.borderDark : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: isDarkMode ? Colors.white : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deliver to: ${address.fullName}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF121111),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => _showSavedAddressesBottomSheet(auth, isDarkMode),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change / Add New',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.fullAddressString,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDarkMode ? AppColors.textSecondaryDark : const Color(0xFF555555),
            ),
          ),
          if (address.phoneNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Phone: ${address.phoneNumber}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isDarkMode ? AppColors.textSecondaryDark : const Color(0xFF787676),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineAddressForm(AuthProvider auth, bool isDarkMode) {
    if (_nameController.text.isEmpty && auth.userName != null && !auth.userName!.startsWith('User_')) {
      _nameController.text = auth.userName!;
    }
    if (_phoneController.text.isEmpty && auth.phoneNumber != null) {
      _phoneController.text = auth.phoneNumber!;
    }
    if (_emailController.text.isEmpty && auth.email != null) {
      _emailController.text = auth.email!;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.borderDark : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Form(
        key: _addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (auth.savedAddresses.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAddRecipientForm = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 14, color: AppColors.primary),
                  label: Text(
                    'Choose from Saved Addresses',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Delivery Address',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Gifting / Shipping to others? Enter recipient details below.',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Recipient Full Name',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter recipient name' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid 10-digit number' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Updates Email',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter email';
                      final valClean = v.trim();
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(valClean)) {
                        return 'Enter valid email';
                      }
                      if (_isDisposableOrTestEmail(valClean)) {
                        return 'Invalid email address';
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
              decoration: const InputDecoration(
                labelText: 'Flat / House No. / Building Name',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter building number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _streetController,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Area / Street / Locality',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter street address' : null,
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
                    decoration: const InputDecoration(
                      labelText: 'Pincode (6-digits)',
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _handlePincodeChange,
                    validator: (v) => v == null || v.trim().length != 6 ? 'Enter pincode' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    style: GoogleFonts.outfit(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'City',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stateController,
              style: GoogleFonts.outfit(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'State',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () async {
                  if (_addressFormKey.currentState!.validate()) {
                    final address = ShippingAddress(
                      fullName: _nameController.text.trim(),
                      phoneNumber: _phoneController.text.trim(),
                      flatHouseNo: _flatController.text.trim(),
                      areaStreet: _streetController.text.trim(),
                      city: _cityController.text.trim(),
                      state: _stateController.text.trim(),
                      pincode: _pincodeController.text.trim(),
                    );
                    
                    setState(() {
                      _selectedAddress = address;
                      _showAddRecipientForm = false;
                    });
                    
                    await auth.setActiveAddress(address);
                    
                    if (auth.isAuthenticated) {
                      await auth.updateProfile(
                        name: _nameController.text.trim(),
                        phone: _phoneController.text.trim(),
                        email: _emailController.text.trim(),
                        flatHouseNo: _flatController.text.trim(),
                        areaStreet: _streetController.text.trim(),
                        city: _cityController.text.trim(),
                        state: _stateController.text.trim(),
                        pincode: _pincodeController.text.trim(),
                      );
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery address saved successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('SAVE & DELIVER HERE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedAddressesBottomSheet(AuthProvider auth, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? AppColors.backgroundDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool showAddForm = false;
        final formKey = GlobalKey<FormState>();
        
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();
        final flatController = TextEditingController();
        final streetController = TextEditingController();
        final pincodeController = TextEditingController();
        final cityController = TextEditingController();
        final stateController = TextEditingController();

        if (auth.userName != null && !auth.userName!.startsWith('User_')) {
          nameController.text = auth.userName!;
        }
        if (auth.phoneNumber != null) {
          phoneController.text = auth.phoneNumber!;
        }
        if (auth.email != null) {
          emailController.text = auth.email!;
        }

        void handlePincodeChange(String pin, StateSetter setModalState) {
          if (pin.length == 6) {
            if (pin.startsWith('56')) {
              cityController.text = 'Bengaluru';
              stateController.text = 'Karnataka';
            } else if (pin.startsWith('11')) {
              cityController.text = 'Delhi';
              stateController.text = 'Delhi';
            } else if (pin.startsWith('40')) {
              cityController.text = 'Mumbai';
              stateController.text = 'Maharashtra';
            } else if (pin.startsWith('60')) {
              cityController.text = 'Chennai';
              stateController.text = 'Tamil Nadu';
            } else if (pin.startsWith('70')) {
              cityController.text = 'Kolkata';
              stateController.text = 'West Bengal';
            } else if (pin.startsWith('50')) {
              cityController.text = 'Hyderabad';
              stateController.text = 'Telangana';
            } else {
              cityController.text = 'Mumbai';
              stateController.text = 'Maharashtra';
            }
            setModalState(() {});
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            final allAddresses = auth.isAuthenticated ? auth.savedAddresses : <ShippingAddress>[];
            
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          showAddForm ? 'Add New Address' : 'Select Delivery Address',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: isDarkMode ? Colors.white70 : Colors.grey,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!showAddForm) ...[
                      if (allAddresses.isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'No other saved addresses found.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDarkMode ? AppColors.textSecondaryDark : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allAddresses.length,
                          itemBuilder: (context, idx) {
                            final addr = allAddresses[idx];
                            final isSelected = auth.activeAddress != null &&
                                auth.activeAddress!.flatHouseNo == addr.flatHouseNo &&
                                auth.activeAddress!.pincode == addr.pincode;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Row(
                                  children: [
                                    Text(
                                      addr.fullName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addr.fullAddressString,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          color: isDarkMode ? AppColors.textSecondaryDark : Colors.grey[700],
                                        ),
                                      ),
                                      if (addr.phoneNumber.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Phone: ${addr.phoneNumber}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11.5,
                                            color: isDarkMode ? AppColors.textSecondaryDark : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  setState(() {
                                    _selectedAddress = addr;
                                  });
                                  await auth.setActiveAddress(addr);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              showAddForm = true;
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            'ADD NEW ADDRESS',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                'Gifting / Shipping to others? Enter recipient details below.',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: nameController,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Recipient Full Name'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Contact Phone'),
                                    validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid 10-digit number' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Updates Email'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Enter email';
                                      final valClean = v.trim();
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(valClean)) {
                                        return 'Enter valid email';
                                      }
                                      if (_isDisposableOrTestEmail(valClean)) {
                                        return 'Invalid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: flatController,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Flat / House No. / Building'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter building' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: streetController,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'Area / Street / Locality'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter street' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: pincodeController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'Pincode', counterText: ''),
                                    onChanged: (pin) => handlePincodeChange(pin, setModalState),
                                    validator: (v) => v == null || v.trim().length != 6 ? 'Enter pincode' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: cityController,
                                    style: GoogleFonts.outfit(fontSize: 13),
                                    decoration: const InputDecoration(labelText: 'City'),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: stateController,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: const InputDecoration(labelText: 'State'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        showAddForm = false;
                                      });
                                    },
                                    child: const Text('CANCEL'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        final addressObj = ShippingAddress(
                                          fullName: nameController.text.trim(),
                                          phoneNumber: phoneController.text.trim(),
                                          flatHouseNo: flatController.text.trim(),
                                          areaStreet: streetController.text.trim(),
                                          city: cityController.text.trim(),
                                          state: stateController.text.trim(),
                                          pincode: pincodeController.text.trim(),
                                        );

                                         setState(() {
                                           _selectedAddress = addressObj;
                                         });
                                         await auth.setActiveAddress(addressObj);

                                        if (auth.isAuthenticated) {
                                          await auth.updateProfile(
                                            name: nameController.text.trim(),
                                            phone: phoneController.text.trim(),
                                            email: emailController.text.trim(),
                                            flatHouseNo: flatController.text.trim(),
                                            areaStreet: streetController.text.trim(),
                                            city: cityController.text.trim(),
                                            state: stateController.text.trim(),
                                            pincode: pincodeController.text.trim(),
                                          );
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('New delivery address saved!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('SAVE'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _processPayment(CartProvider cartProvider) {
    if (cartProvider.items.any((item) => item.isOutOfStock)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please remove out of stock items before placing order.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const LoginBottomSheet(),
      ).then((_) {
        if (Provider.of<AuthProvider>(context, listen: false).isAuthenticated) {
          _processPayment(cartProvider);
        }
      });
      return;
    }

    if (!_hasSavedAddress(authProvider) || _showAddRecipientForm) {
      if (_addressFormKey.currentState != null && _addressFormKey.currentState!.validate()) {
        final address = ShippingAddress(
          fullName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          flatHouseNo: _flatController.text.trim(),
          areaStreet: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
        );
        setState(() {
          _selectedAddress = address;
          _showAddRecipientForm = false;
        });
        authProvider.setActiveAddress(address);
        
        if (authProvider.isAuthenticated) {
          authProvider.updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            flatHouseNo: _flatController.text.trim(),
            areaStreet: _streetController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter and save a valid shipping address first!'), backgroundColor: AppColors.error),
        );
        return;
      }
    } else {
      _selectedAddress = authProvider.activeAddress;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Payment Option',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // UPI option
              ListTile(
                leading: const Icon(Icons.payment, color: AppColors.primary),
                title: Text('Google Pay / PhonePe / Paytm (UPI)', style: GoogleFonts.outfit(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _completeOrder(cartProvider, 'UPI'),
              ),
              const Divider(height: 1),
              
              // Card option
              ListTile(
                leading: const Icon(Icons.credit_card, color: AppColors.primary),
                title: Text('Credit / Debit Card', style: GoogleFonts.outfit(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _completeOrder(cartProvider, 'Card'),
              ),
              const Divider(height: 1),
              
              // COD option
              ListTile(
                leading: const Icon(Icons.monetization_on, color: AppColors.primary),
                title: Text('Cash On Delivery (COD)', style: GoogleFonts.outfit(fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _completeOrder(cartProvider, 'COD'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeOrder(CartProvider cartProvider, String paymentMethod) async {
    Navigator.pop(context); // Close payment options sheet
    
    setState(() {
      _isCheckingOut = true;
    });

    final newOrder = OrderModel(
      id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
      items: List.from(cartProvider.items),
      totalAmount: cartProvider.totalAmount,
      date: DateTime.now(),
      status: OrderStatus.placed,
      address: _selectedAddress!,
      paymentMethod: paymentMethod,
      couponCode: cartProvider.appliedCouponCode,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // 1. Place order (returns order with backend MongoID if logged in)
      final placed = await _orderService.placeOrder(newOrder);
      
      // If COD or guest user, skip Razorpay payments verification
      if (paymentMethod.toLowerCase() == 'cod' || !authProvider.isAuthenticated) {
        await cartProvider.clearCart();
        setState(() {
          _isCheckingOut = false;
          _couponSuccessMessage = null;
          _couponErrorMessage = null;
          _couponController.clear();
        });

        // Navigate to Order Status Tracking screen
        if (mounted) {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: OrderTrackingScreen(orderId: placed.id),
              direction: AxisDirection.right,
            ),
          );
        }
        return;
      }

      // 2. Create Razorpay Payment Order on backend
      String? razorpayOrderId;
      try {
        razorpayOrderId = await _orderService.createPaymentOrder(placed.id);
      } catch (err) {
        razorpayOrderId = 'mock_rzp_${DateTime.now().millisecondsSinceEpoch}';
      }

      setState(() {
        _isCheckingOut = false;
      });

      // 3. Show simulated payment sheet
      if (mounted) {
        _showPaymentSimulationSheet(placed, paymentMethod, razorpayOrderId ?? '', cartProvider);
      }
    } catch (e) {
      setState(() {
        _isCheckingOut = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPaymentSimulationSheet(
    OrderModel placed,
    String paymentMethod,
    String razorpayOrderId,
    CartProvider cartProvider,
  ) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PaymentSimulationBottomSheet(
          placed: placed,
          paymentMethod: paymentMethod,
          razorpayOrderId: razorpayOrderId,
          cartProvider: cartProvider,
          onSuccess: (orderId) {
            Navigator.pop(context, true); // Pop returning true (success)
          },
        );
      },
    ).then((success) async {
      if (success == true) {
        await cartProvider.clearCart();
        
        setState(() {
          _couponSuccessMessage = null;
          _couponErrorMessage = null;
          _couponController.clear();
        });

        if (mounted) {
          Navigator.push(
            context,
            SmoothPageRoute(
              child: OrderTrackingScreen(orderId: placed.id),
              direction: AxisDirection.right,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled. Order remains pending in history.'),
              backgroundColor: AppColors.warning,
            ),
          );
          Navigator.push(
            context,
            SmoothPageRoute(
              child: OrderTrackingScreen(orderId: placed.id),
              direction: AxisDirection.right,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    if (_selectedAddress == null) {
      if (authProvider.activeAddress != null && authProvider.activeAddress!.phoneNumber.isNotEmpty) {
        _selectedAddress = authProvider.activeAddress;
      } else if (authProvider.savedAddresses.isNotEmpty) {
        _selectedAddress = authProvider.savedAddresses.first;
        authProvider.setActiveAddress(authProvider.savedAddresses.first);
      } else {
        _selectedAddress = authProvider.activeAddress;
      }
    }

    if (_isCheckingOut) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
              SizedBox(height: 16),
              Text('Securing your order... Please wait', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: (!widget.isPrimaryTab && Navigator.canPop(context))
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Theme.of(context).platform == TargetPlatform.iOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111), size: Theme.of(context).platform == TargetPlatform.iOS ? 16 : 22),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
            : null,
        title: Text(
          'My Bag',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
            fontSize: 18,
          ),
        ),
        actions: const [],
      ),
      body: cartProvider.items.isEmpty
          ? _buildEmptyBag(context)
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Shopping cart items list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartProvider.items.length,
                        itemBuilder: (context, index) {
                          final item = cartProvider.items[index];
                          return _buildCartItemCard(context, item, cartProvider);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Shipping Address custom representation (Visa removed)
                      _buildShippingInformationSection(),
                      const SizedBox(height: 24),

                      // Promo Code & Coupons Section
                      _buildCouponSection(cartProvider),
                      const SizedBox(height: 24),
 
                      // Price Details breakdown
                      _buildPriceBreakdownSection(cartProvider),
                      const SizedBox(height: 220), // Higher spacer to allow scrolling past floating checkout & nav bars
                    ],
                  ),
                ),
                
                // Floating Place Order Button (Solid Charcoal Capsule)
                Builder(
                  builder: (context) {
                    final bool hasOosItems = cartProvider.items.any((item) => item.isOutOfStock);
                    return Positioned(
                      left: 20,
                      right: 20,
                      bottom: 112, // Positioned 12px above bottom nav bar (76 height + 24 bottom)
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: hasOosItems 
                              ? AppColors.error 
                              : (isDarkMode ? AppColors.primaryDark : const Color(0xFF121111)),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: hasOosItems 
                                  ? () {
                                      final oosItems = cartProvider.items.where((item) => item.isOutOfStock).toList();
                                      for (final item in oosItems) {
                                        cartProvider.removeFromCart(item.product.id, item.size);
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed all out of stock items from your bag.'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  : () => _processPayment(cartProvider),
                              child: Center(
                                child: Text(
                                  hasOosItems ? 'Remove Out of Stock Items' : 'Place Order',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, var item, CartProvider cartProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isOos = item.isOutOfStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOos 
              ? AppColors.error.withValues(alpha: 0.5) 
              : (isDarkMode ? AppColors.borderDark : const Color(0xFFF2F2F2)),
          width: isOos ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rounded Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: isOos ? 0.6 : 1.0,
              child: CachedNetworkImage(
                imageUrl: item.product.images.isNotEmpty 
                    ? item.product.images[0] 
                    : 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=500',
                height: 90,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and Option dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.product.fabric} | Size: ${item.size}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: isDarkMode ? AppColors.textSecondaryDark : const Color(0xFF787676),
                                  fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isOos) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'OUT OF STOCK',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ] else if (item.stockLeft < 6) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF4E342E) : const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDarkMode ? const Color(0xFF8D6E63) : const Color(0xFFFFB74D),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'HURRY, ONLY ${item.stockLeft} LEFT!',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: isDarkMode ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Open option menu to remove item
                          _showItemOptionsBottomSheet(context, item, cartProvider);
                        },
                        child: Icon(
                          Icons.more_horiz,
                          color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and Quantity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.product.price.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
                        ),
                      ),
                      
                      // - X + Quantity capsule selector
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.borderDark : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.remove, size: 14, color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111)),
                              onPressed: () {
                                cartProvider.updateQuantity(item.product.id, item.size, item.quantity - 1);
                              },
                            ),
                            Text(
                              item.quantity.toString(),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.add,
                                size: 14,
                                color: isOos 
                                    ? Colors.grey 
                                    : (isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111)),
                              ),
                              onPressed: isOos
                                  ? null
                                  : () {
                                      cartProvider.updateQuantity(item.product.id, item.size, item.quantity + 1);
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemOptionsBottomSheet(BuildContext context, var item, CartProvider cartProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remove from checkout', style: GoogleFonts.outfit(color: AppColors.error, fontWeight: FontWeight.bold)),
                onTap: () {
                  cartProvider.removeFromCart(item.product.id, item.size);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShippingInformationSection() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    Widget addressWidget;
    if (authProvider.savedAddresses.isEmpty) {
      addressWidget = _buildInlineAddressForm(authProvider, isDarkMode);
    } else if (_showAddRecipientForm) {
      addressWidget = _buildInlineAddressForm(authProvider, isDarkMode);
    } else {
      addressWidget = _buildSavedAddressesSelector(authProvider, isDarkMode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping Information',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
          ),
        ),
        const SizedBox(height: 12),
        addressWidget,
      ],
    );
  }

  Widget _buildSavedAddressesSelector(AuthProvider auth, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: auth.savedAddresses.length,
            itemBuilder: (context, index) {
              final addr = auth.savedAddresses[index];
              final isSelected = _selectedAddress != null && 
                  _selectedAddress!.flatHouseNo == addr.flatHouseNo &&
                  _selectedAddress!.pincode == addr.pincode &&
                  _selectedAddress!.fullName == addr.fullName;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAddress = addr;
                  });
                  auth.setActiveAddress(addr);
                },
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 12, bottom: 4, top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? (isDarkMode ? Colors.white : const Color(0xFF121111)) 
                          : (isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.06)),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.05 : 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              addr.fullName,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected 
                                ? (isDarkMode ? Colors.white : const Color(0xFF121111))
                                : (isDarkMode ? Colors.white30 : Colors.black26),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        addr.phoneNumber,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          addr.fullAddressString,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: isDarkMode ? AppColors.textSecondaryDark.withOpacity(0.7) : AppColors.textSecondaryLight.withOpacity(0.7),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showAddRecipientForm = true;
              });
            },
            icon: const Icon(Icons.card_giftcard, size: 16, color: AppColors.primary),
            label: Text(
              'SHIP TO SOMEONE ELSE / ADD GIFTING ADDRESS',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isDarkMode ? Colors.white10 : AppColors.borderLight,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponSection(CartProvider cartProvider) {
    final bool hasCoupon = cartProvider.appliedCouponCode != null;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Promo Code & Coupons',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF121111),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.surfaceDark : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  enabled: !hasCoupon && !_isApplyingCoupon,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF121111),
                  ),
                  decoration: InputDecoration(
                    hintText: hasCoupon ? 'Coupon ${cartProvider.appliedCouponCode} Applied' : 'Enter Coupon Code (e.g. SLAAY20)',
                    hintStyle: GoogleFonts.outfit(
                      color: hasCoupon ? AppColors.success : const Color(0xFF787676),
                      fontWeight: hasCoupon ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      color: hasCoupon ? AppColors.success : const Color(0xFF787676),
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (_isApplyingCoupon)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  ),
                )
              else if (hasCoupon)
                TextButton(
                  onPressed: () {
                    cartProvider.removeCoupon();
                    _couponController.clear();
                    setState(() {
                      _couponSuccessMessage = null;
                      _couponErrorMessage = null;
                    });
                  },
                  child: Text(
                    'REMOVE',
                    style: GoogleFonts.outfit(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: () async {
                    final code = _couponController.text.trim();
                    if (code.isEmpty) return;
                    
                    setState(() {
                      _isApplyingCoupon = true;
                      _couponErrorMessage = null;
                      _couponSuccessMessage = null;
                    });
                    
                    final res = await cartProvider.validateAndApplyCoupon(
                      code,
                      paymentMethod: 'cod',
                    );
                    
                    setState(() {
                      _isApplyingCoupon = false;
                      if (res['success'] == true) {
                        _couponSuccessMessage = res['message'];
                      } else {
                        _couponErrorMessage = res['message'];
                      }
                    });
                  },
                  child: Text(
                    'APPLY',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_couponErrorMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _couponErrorMessage!,
              style: GoogleFonts.outfit(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
        if (_couponSuccessMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _couponSuccessMessage!,
              style: GoogleFonts.outfit(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceBreakdownSection(CartProvider cartProvider) {
    Widget priceRow(String label, String value, {bool isGrandTotal = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.w500,
                color: isGrandTotal ? const Color(0xFF121111) : const Color(0xFF787676),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: isGrandTotal ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF121111),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        priceRow('Total (${cartProvider.totalItemsCount} items)', '₹${cartProvider.subtotal.toInt()}'),
        priceRow('GST (5%)', '₹${cartProvider.tax.toInt()}'),
        priceRow('Shipping Fee', cartProvider.shippingFee == 0 ? '₹0.00' : '₹${cartProvider.shippingFee.toInt()}'),
        priceRow('Discount', '-₹${cartProvider.couponDiscount.toInt()}'),
        const Divider(height: 24, color: Color(0xFFF2F2F2)),
        priceRow(
          'Sub Total',
          '₹${cartProvider.totalAmount.toInt()}',
          isGrandTotal: true,
        ),
      ],
    );
  }

  Widget _buildEmptyBag(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 72, color: AppColors.borderLight),
            const SizedBox(height: 20),
            Text(
              'Your Shopping Bag is empty',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill it with beautiful Indian ethnic kurtis, luxurious sarees, or fusion dresses.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                MainNavigationWrapper.activeTabNotifier.value = 0; // Go back to Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(200, 50),
              ),
              child: const Text('SHOP NOW'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSimulationBottomSheet extends StatefulWidget {
  final OrderModel placed;
  final String paymentMethod;
  final String razorpayOrderId;
  final CartProvider cartProvider;
  final Function(String orderId) onSuccess;

  const _PaymentSimulationBottomSheet({
    required this.placed,
    required this.paymentMethod,
    required this.razorpayOrderId,
    required this.cartProvider,
    required this.onSuccess,
  });

  @override
  State<_PaymentSimulationBottomSheet> createState() => _PaymentSimulationBottomSheetState();
}

class _PaymentSimulationBottomSheetState extends State<_PaymentSimulationBottomSheet> {
  final OrderService _orderService = OrderService();
  bool _isProcessing = false;
  String _processingStep = "";
  bool _isSuccess = false;
  String? _errorMessage;

  // UPI variables
  String _selectedUpiApp = "Google Pay";
  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'Google Pay', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'PhonePe', 'icon': Icons.account_balance_outlined},
    {'name': 'Paytm', 'icon': Icons.payment_outlined},
    {'name': 'Other UPI App', 'icon': Icons.phonelink_ring_outlined},
  ];

  // Card variables
  final _cardNoController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderController = TextEditingController();
  
  String _cardNumber = "•••• •••• •••• ••••";
  String _cardExpiry = "MM/YY";
  String _cardHolder = "CARD HOLDER";
  bool _showCvv = false;

  @override
  void initState() {
    super.initState();
    _cardNoController.addListener(() {
      setState(() {
        String text = _cardNoController.text;
        _cardNumber = text.isEmpty ? "•••• •••• •••• ••••" : text;
      });
    });
    _expiryController.addListener(() {
      setState(() {
        String text = _expiryController.text;
        _cardExpiry = text.isEmpty ? "MM/YY" : text;
      });
    });
    _holderController.addListener(() {
      setState(() {
        String text = _holderController.text.toUpperCase();
        _cardHolder = text.isEmpty ? "CARD HOLDER" : text;
      });
    });
  }

  @override
  void dispose() {
    _cardNoController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _processSimulatedPayment() async {
    // Validate inputs first
    if (widget.paymentMethod.toLowerCase() == 'card') {
      if (_cardNoController.text.replaceAll(' ', '').length < 16) {
        setState(() => _errorMessage = "Please enter a valid 16-digit card number");
        return;
      }
      if (_expiryController.text.length < 5) {
        setState(() => _errorMessage = "Please enter valid expiry date (MM/YY)");
        return;
      }
      if (_cvvController.text.length < 3) {
        setState(() => _errorMessage = "Please enter valid CVV");
        return;
      }
      if (_holderController.text.trim().isEmpty) {
        setState(() => _errorMessage = "Please enter card holder name");
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processingStep = "Connecting to payment gateway...";
    });

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        _processingStep = widget.paymentMethod.toLowerCase() == 'card' 
            ? "Authorizing card transaction..."
            : "Requesting payment authorization from $_selectedUpiApp...";
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        _processingStep = "Verifying secure payment signature...";
      });

      // Call verifyPayment with mock signature on backend
      final verified = await _orderService.verifyPayment(
        orderId: widget.placed.id,
        razorpayOrderId: widget.razorpayOrderId,
        razorpayPaymentId: "pay_mock_${DateTime.now().millisecondsSinceEpoch}",
        razorpaySignature: "mock_signature",
      );

      if (verified) {
        setState(() {
          _processingStep = "Payment Successful!";
          _isSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        widget.onSuccess(widget.placed.id);
      } else {
        throw Exception("Payment signature verification failed");
      }

    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "").replaceAll("ApiException: ", "");
      });
    }
  }

  Widget _buildProcessingView() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isSuccess) ...[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ] else ...[
            const CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              _processingStep,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            "Transaction ID: ${widget.razorpayOrderId}",
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_outlined, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                "Secured by Razorpay Sandbox",
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFormView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Debit / Credit Card',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SLAAY SECURE',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Icon(Icons.wifi, color: Colors.white54, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _cardNumber,
                style: GoogleFonts.spaceMono(
                  color: Colors.white,
                  fontSize: 19,
                  letterSpacing: 2,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARD HOLDER',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _cardHolder,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EXPIRES',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _cardExpiry,
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 38,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.credit_card, color: Colors.white70, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.outfit(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _cardNoController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: '4532 7182 9381 2309',
            prefixIcon: Icon(Icons.credit_card),
          ),
          onChanged: (val) {
            String digits = val.replaceAll(RegExp(r'\D'), '');
            if (digits.length > 16) digits = digits.substring(0, 16);
            
            String formatted = "";
            for (int i = 0; i < digits.length; i++) {
              if (i > 0 && i % 4 == 0) formatted += " ";
              formatted += digits[i];
            }
            
            if (formatted != val) {
              _cardNoController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _expiryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onChanged: (val) {
                  String digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length > 4) digits = digits.substring(0, 4);
                  
                  String formatted = "";
                  if (digits.length > 2) {
                    formatted = "${digits.substring(0, 2)}/${digits.substring(2)}";
                  } else {
                    formatted = digits;
                  }
                  
                  if (formatted != val) {
                    _expiryController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _cvvController,
                keyboardType: TextInputType.number,
                obscureText: !_showCvv,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(_showCvv ? Icons.visibility : Icons.visibility_off, size: 18),
                    onPressed: () {
                      setState(() => _showCvv = !_showCvv);
                    },
                  ),
                ),
                onChanged: (val) {
                  String digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length > 3) digits = digits.substring(0, 3);
                  if (digits != val) {
                    _cvvController.value = TextEditingValue(
                      text: digits,
                      selection: TextSelection.collapsed(offset: digits.length),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _holderController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Card Holder Name',
            hintText: 'SARAH SMITH',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _processSimulatedPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              'PAY ₹${widget.placed.totalAmount.toInt()}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiAppSelectionView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select UPI Application',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total Amount: ₹${widget.placed.totalAmount.toInt()}',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: AppColors.error, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _upiApps.length,
          itemBuilder: (context, index) {
            final app = _upiApps[index];
            final isSelected = _selectedUpiApp == app['name'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[200]!,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    app['icon'],
                    color: isSelected ? AppColors.primary : Colors.grey[600],
                    size: 20,
                  ),
                ),
                title: Text(
                  app['name'],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected 
                    ? const Icon(Icons.radio_button_checked, color: AppColors.primary)
                    : const Icon(Icons.radio_button_off, color: Colors.grey),
                onTap: () {
                  setState(() {
                    _selectedUpiApp = app['name'];
                  });
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _processSimulatedPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Text(
              'PAY VIA $_selectedUpiApp',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: _isProcessing 
            ? _buildProcessingView()
            : widget.paymentMethod.toLowerCase() == 'card'
                ? _buildCardFormView()
                : _buildUpiAppSelectionView(),
      ),
    );
  }
}
