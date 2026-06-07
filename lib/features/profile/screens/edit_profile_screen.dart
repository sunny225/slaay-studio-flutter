import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../core/widgets/press_scale_effect.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  String? _selectedGender;
  String _initialEmail = '';
  String _initialPhone = '';
  
  bool _isPhoneVerified = true;
  bool _isSaving = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  String _sanitizeDob(String? dob) {
    if (dob == null || dob.isEmpty) return '';
    if (dob.contains('T')) {
      return dob.split('T')[0];
    }
    return dob;
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

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    _initialEmail = auth.email ?? '';
    if (_initialEmail.startsWith('phone_') && (_initialEmail.endsWith('@vastraa.com') || _initialEmail.endsWith('@slaay.com'))) {
      _initialEmail = '';
    }

    _initialPhone = auth.phoneNumber ?? '';

    _nameController = TextEditingController(text: auth.userName?.startsWith('User_') == true ? '' : auth.userName);
    _emailController = TextEditingController(text: _initialEmail);
    _phoneController = TextEditingController(text: _initialPhone);
    _dobController = TextEditingController(text: _sanitizeDob(auth.dob));

    _selectedGender = _genders.contains(auth.gender) ? auth.gender : null;

    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    final cleanPhone = _phoneController.text.trim();
    setState(() {
      _isPhoneVerified = cleanPhone == _initialPhone;
    });
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _triggerVerification(String type, String value) async {
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid $type')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (type == 'phone') {
      final currentPhone = auth.phoneNumber ?? '';
      if (value.trim() == currentPhone.trim()) {
        showDialog(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Verification Alert',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              content: Text(
                'This mobile number is already registered to your account.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }

      // Show confirmation dialog before sending OTP
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Change Mobile Number',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            content: Text(
              'Are you sure you want to update your registered mobile number to +91 $value? A verification code (OTP) will be sent to this number.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'CONFIRM',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    final sendResult = await auth.sendProfileOtp(type, value);
    if (sendResult['success'] == true) {
      final String mockOtp = sendResult['data']?['otp'] ?? '1234';
      _showOtpDialog(type, value, mockOtp);
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(sendResult['message'] ?? 'Failed to send OTP code.')),
      );
    }
  }

  void _showOtpDialog(String type, String value, String mockOtp) {
    final otpController = TextEditingController();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Verify your ${type == 'phone' ? 'Mobile' : 'Email'}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the verification OTP code sent to $value.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  counterText: '',
                  hintText: 'Enter OTP (Try: $mockOtp)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final otp = otpController.text.trim();
                final verifyResult = await auth.verifyProfileOtp(type, value, otp);
                if (!context.mounted) return;
                
                if (verifyResult['success'] == true) {
                  setState(() {
                    if (type == 'phone') {
                      _initialPhone = value;
                      _isPhoneVerified = true;
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${type == 'phone' ? 'Phone' : 'Email'} verified successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(verifyResult['message'] ?? 'Invalid code entered.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'VERIFY',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your updated phone number first.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await auth.updateUserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: _selectedGender ?? '',
      dob: _dobController.text.trim(),
    );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Padding(
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
                icon: Icon(
                  Theme.of(context).platform == TargetPlatform.iOS 
                      ? Icons.arrow_back_ios_new_rounded 
                      : Icons.arrow_back_rounded, 
                  color: isDarkMode ? Colors.white : AppColors.textPrimaryLight, 
                  size: 18
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    final hasWrapper = context.findAncestorWidgetOfExactType<MainNavigationWrapper>() != null;
                    if (hasWrapper) {
                      MainNavigationWrapper.activeTabNotifier.value = 0;
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),
          ),
          title: Text(
            'EDIT PROFILE',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
              fontSize: 16,
              letterSpacing: 3,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 0,
            color: isDarkMode ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDarkMode ? Colors.white12 : AppColors.borderLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                            size: 18,
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCall,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                            size: 18,
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: _isPhoneVerified
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: SizedBox(
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: () => _triggerVerification('phone', _phoneController.text.trim()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.accent,
                                          foregroundColor: AppColors.textPrimaryLight,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        child: Text(
                                          'VERIFY',
                                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your mobile number';
                        }
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
                          return 'Please enter a valid 10-digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedMailAtSign01,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                            size: 18,
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailVal = value.trim();
                        if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(emailVal)) {
                          return 'Please enter a valid email';
                        }
                        if (_isDisposableOrTestEmail(emailVal)) {
                          return 'Test/Temporary emails are not allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                            size: 18,
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                      ),
                      dropdownColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
                      items: _genders.map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _selectDateOfBirth,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar01,
                            color: isDarkMode ? Colors.white70 : Colors.grey,
                            size: 18,
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        suffixIcon: const Icon(Icons.arrow_drop_down, size: 24),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please choose your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: PressScaleEffect(
                        onTap: _isSaving ? null : _saveProfile,
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'SAVE PROFILE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
