import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../product/providers/product_provider.dart';

class LoginBottomSheet extends StatefulWidget {
  const LoginBottomSheet({super.key});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  bool _showOtpStage = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp(AuthProvider authProvider) async {
    if (_phoneFormKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      final phone = _phoneController.text.trim();
      final success = await authProvider.sendOtp(phone);

      if (success) {
        setState(() {
          _showOtpStage = true;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to send verification code. Please try again.';
        });
      }
    }
  }

  void _handleVerifyOtp(AuthProvider authProvider) async {
    if (_otpFormKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      final otp = _otpController.text.trim();
      final success = await authProvider.verifyOtp(otp);

      if (success) {
        if (!mounted) return;
        
        // Re-sync user data after login
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        cartProvider.syncAndLoadCart();
        productProvider.syncAndLoadWishlist();

        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid verification code. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slide indicator pill
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 48,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white30 : Colors.black26,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            AnimatedCrossFade(
              firstChild: _buildPhoneEntryStage(authProvider, isDarkMode),
              secondChild: _buildOtpEntryStage(authProvider, isDarkMode),
              crossFadeState: _showOtpStage
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneEntryStage(AuthProvider authProvider, bool isDarkMode) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'LOGIN OR SIGNUP',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.primary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock coupons, profile and much more',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Custom Input Box matching design
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white24 : AppColors.borderLight.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Text(
                  '+91',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1.2,
                  height: 22,
                  color: isDarkMode ? Colors.white24 : AppColors.borderLight.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Mobile Number',
                      hintStyle: GoogleFonts.outfit(
                        color: isDarkMode ? Colors.white30 : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter mobile number';
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.outfit(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _handleSendOtp(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: authProvider.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? AppColors.primary : Colors.white),
                      ),
                    )
                  : Text(
                      'VERIFY',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // T&C Centered Label
          Text(
            'By continuing, you agree to the\nTerms of Service and Privacy Policy',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: isDarkMode ? Colors.white30 : Colors.black45,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOtpEntryStage(AuthProvider authProvider, bool isDarkMode) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ENTER VERIFICATION CODE',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.primary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a verification code to +91 ${_phoneController.text.trim()}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // OTP field matching standard themes
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
              color: isDarkMode ? Colors.white : AppColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '••••',
              hintStyle: GoogleFonts.outfit(
                color: isDarkMode ? Colors.white24 : AppColors.textSecondaryLight.withValues(alpha: 0.3),
                letterSpacing: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.white24 : AppColors.borderLight.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDarkMode ? Colors.white24 : AppColors.borderLight.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter verification code';
              if (v.trim().length < 4) return 'Code must be at least 4 digits';
              return null;
            },
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.outfit(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : () => _handleVerifyOtp(authProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: authProvider.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(isDarkMode ? AppColors.primary : Colors.white),
                      ),
                    )
                  : Text(
                      'VERIFY & PROCEED',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Back Button to change phone
          TextButton(
            onPressed: () {
              setState(() {
                _showOtpStage = false;
                _otpController.clear();
                _errorMessage = null;
              });
            },
            child: Text(
              'Change Mobile Number',
              style: GoogleFonts.outfit(
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
