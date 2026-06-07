import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'verification_code_screen.dart';
import 'auth_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = null;
      });

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;

      final success = await authProvider.sendOtpForSignup(
        name: name,
        phone: phone,
        password: password,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent! (Use Code: 123456)'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerificationCodeScreen(
              phoneNumber: phone,
              flow: VerificationFlow.signup,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to initiate signup verification. Try again.';
        });
      }
    }
  }

  Widget _buildSocialButton({
    required Widget child,
    required VoidCallback onTap,
    Color? backgroundColor,
    BorderSide? borderSide,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: borderSide != null ? Border.all(color: borderSide.color, width: borderSide.width) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Theme.of(context).platform == TargetPlatform.iOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: AppColors.primary, size: Theme.of(context).platform == TargetPlatform.iOS ? 20 : 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  
                  // Premium Center Branding Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              'S',
                              style: GoogleFonts.bebasNeue(
                                color: AppColors.primary,
                                fontSize: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SLAAY',
                          style: GoogleFonts.bebasNeue(
                            color: AppColors.primary,
                            fontSize: 28,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 35),
                  
                  Text(
                    'Create an account',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Join us to explore handblock prints & royal silks.",
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: AppColors.secondary,
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.outfit(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Full Name Field Label
                  Text(
                    'Full Name',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.secondary, size: 20),
                      hintText: 'Enter your full name',
                      hintStyle: GoogleFonts.outfit(color: AppColors.secondary.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // Mobile Number Field Label
                  Text(
                    'Mobile Number',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.secondary, size: 20),
                      prefixText: '+91 ',
                      prefixStyle: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
                      hintText: '98765 43210',
                      hintStyle: GoogleFonts.outfit(color: AppColors.secondary.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.trim().length != 10) {
                        return 'Please enter a valid 10-digit number';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),

                  // Password Field Label
                  Text(
                    'Password',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondary, size: 20),
                      hintText: 'Enter your password',
                      hintStyle: GoogleFonts.outfit(color: AppColors.secondary.withValues(alpha: 0.4), fontWeight: FontWeight.normal),
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.0),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),

                  // Terms & Conditions text
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.secondary,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'By signing up, you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, decoration: TextDecoration.underline),
                        ),
                        const TextSpan(text: ', '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, decoration: TextDecoration.underline),
                        ),
                        const TextSpan(text: ', and '),
                        TextSpan(
                          text: 'Cookie Use',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, decoration: TextDecoration.underline),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Register Button
                  authProvider.isLoading
                      ? Center(child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                      : SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _handleSignUp(authProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Account',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),

                  const SizedBox(height: 35),
                  
                  // "Or sign up with" Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFEDEDED), thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Or sign up with',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFEDEDED), thickness: 1)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Social Logins Side-by-Side Pill Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialButton(
                        child: Text(
                          'G',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFEA4335),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        onTap: () {},
                        backgroundColor: Colors.white,
                        borderSide: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.2)),
                      ),
                      const SizedBox(width: 20),
                      _buildSocialButton(
                        child: const Icon(Icons.apple, color: Colors.white, size: 24),
                        onTap: () {},
                        backgroundColor: Colors.black,
                      ),
                      const SizedBox(width: 20),
                      _buildSocialButton(
                        child: const Icon(Icons.facebook, color: Colors.white, size: 22),
                        onTap: () {},
                        backgroundColor: const Color(0xFF1877F2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  
                  // Footer Login navigation
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const AuthScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            color: AppColors.secondary,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Log In',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthLogoPainter extends CustomPainter {
  final Color color;
  AuthLogoPainter({this.color = const Color(0xFF121111)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    
    // Arm segment dimensions
    final arm = w / 3;

    final path = Path();
    path.moveTo(arm, 0);
    path.lineTo(arm * 2, 0);
    path.lineTo(arm * 2, arm);
    path.lineTo(w, arm);
    path.lineTo(w, arm * 1.5);
    
    path.arcToPoint(
      Offset(arm * 1.5, h),
      radius: Radius.circular(arm * 1.5),
      clockwise: false,
    );
    
    path.lineTo(arm, h);
    path.lineTo(arm, arm * 2);
    path.lineTo(0, arm * 2);
    path.lineTo(0, arm);
    path.lineTo(arm, arm);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
