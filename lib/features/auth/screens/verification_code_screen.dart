import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import 'reset_password_screen.dart';
import '../../home/screens/main_navigation_wrapper.dart';

enum VerificationFlow { signup, forgotPassword }

class VerificationCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final VerificationFlow flow;

  const VerificationCodeScreen({
    super.key,
    required this.phoneNumber,
    required this.flow,
  });

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus on first box after build finishes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _resendCode(AuthProvider authProvider) async {
    if (!_canResend) return;
    
    setState(() {
      _errorMessage = null;
    });

    bool success;
    if (widget.flow == VerificationFlow.signup) {
      success = true; // Simulated success
    } else {
      success = await authProvider.sendOtpForForgotPassword(widget.phoneNumber);
    }

    if (success) {
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent successfully! (Code: 123456)'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to resend code. Please try again.';
      });
    }
  }

  void _verifyCode(AuthProvider authProvider) async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    if (widget.flow == VerificationFlow.signup) {
      final success = await authProvider.verifyOtpForSignup(code);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome back to SLAAY!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid code. Enter 123456 to proceed.';
        });
      }
    } else {
      final success = await authProvider.verifyOtpForForgotPassword(widget.phoneNumber, code);
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Invalid code. Enter 123456 to proceed.';
        });
      }
    }
  }

  Widget _buildDigitInput(int index) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _focusNodes[index].hasFocus ? Colors.white : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? AppColors.primary
              : AppColors.borderLight.withValues(alpha: 0.2),
          width: _focusNodes[index].hasFocus ? 2.0 : 1.0,
        ),
        boxShadow: _focusNodes[index].hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKey: (RawKeyEvent event) {
          // Detect backspace key release to request previous focus when text field is empty
          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _controllers[index - 1].clear();
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
              }
            } else {
              if (index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            }
            setState(() {}); // Rebuild border colors and shadows
          },
        ),
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
        leading: IconButton(
          icon: Icon(Theme.of(context).platform == TargetPlatform.iOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: AppColors.primary, size: Theme.of(context).platform == TargetPlatform.iOS ? 20 : 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                
                const SizedBox(height: 40),
                
                Text(
                  'Verification Code',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: AppColors.secondary,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'Enter the 6-digit code sent to your mobile number ('),
                      TextSpan(
                        text: '+91 ${widget.phoneNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const TextSpan(text: ').'),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 24),
                ],

                // 4 Digit Input Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _buildDigitInput(index)),
                ),
                
                const SizedBox(height: 35),

                // Resend Timer Section
                Center(
                  child: Column(
                    children: [
                      Text(
                        _canResend
                            ? "Didn't receive the code?"
                            : "Resend code in ${_secondsRemaining}s",
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_canResend) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _resendCode(authProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Resend Code',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 45),

                // Continue Button
                authProvider.isLoading
                    ? Center(child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)))
                    : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _verifyCode(authProvider),
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
                                'Verify & Continue',
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
              ],
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
