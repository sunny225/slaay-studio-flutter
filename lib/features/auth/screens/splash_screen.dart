import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../providers/auth_provider.dart';
import '../../home/providers/cms_provider.dart';
import '../../product/providers/product_provider.dart';
import 'onboarding_screen.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import '../../../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _taglineController;
  late AnimationController _logoController;
  
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;
  
  late Animation<double> _iconScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoLetterSpacing;
  
  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;
  
  bool _showTagline = true;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Tagline Animation (Glide-Up + Fade-In -> Hold -> Fade-Out)
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    _taglineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 35),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _taglineController, curve: Curves.easeInOut));

    _taglineSlide = Tween<double>(begin: 25.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _taglineController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Logo Animation (Elastic Monogram Bounce -> Text Fade -> Static Hold -> Exit Zoom)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.35, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.15, 0.40, curve: Curves.easeIn),
      ),
    );

    _logoLetterSpacing = Tween<double>(begin: 1.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.15, 0.50, curve: Curves.easeOutBack),
      ),
    );

    // Exit transition mapped directly to the last 15% of the timeline
    _exitScale = Tween<double>(begin: 1.0, end: 3.5).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInOutQuart),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // Chain animations via status listeners
    _taglineController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showTagline = false;
            _showLogo = true;
          });
          _logoController.forward();
        }
      }
    });

    _logoController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          _doNavigation();
        }
      }
    });

    // Start Phase 1
    _taglineController.forward();
  }

  @override
  void dispose() {
    _taglineController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _doNavigation() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cmsProvider = Provider.of<CmsProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    bool isAllReady() {
      return authProvider.isInitialized &&
          cmsProvider.isPreloaded &&
          productProvider.isPreloaded;
    }

    if (isAllReady()) {
      _performPush(authProvider);
    } else {
      late VoidCallback listener;
      listener = () {
        if (!mounted) {
          authProvider.removeListener(listener);
          cmsProvider.removeListener(listener);
          productProvider.removeListener(listener);
          return;
        }
        if (isAllReady()) {
          authProvider.removeListener(listener);
          cmsProvider.removeListener(listener);
          productProvider.removeListener(listener);
          _performPush(authProvider);
        }
      };

      authProvider.addListener(listener);
      cmsProvider.addListener(listener);
      productProvider.addListener(listener);
    }
  }

  void _performPush(AuthProvider authProvider) {
    // Initialize Notification Service for push/local alerts
    NotificationService().init(context);

    final destination = (authProvider.completedOnboarding || authProvider.isAuthenticated)
        ? const MainNavigationWrapper()
        : const OnboardingScreen();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _buildSplashBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SplashBackgroundPainter(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Stack(
          children: [
            // Elegant background wave vectors
            _buildSplashBackground(),
            
            // Dynamic Phase Content Renderer
            Center(
              child: _showTagline
                  ? AnimatedBuilder(
                      animation: _taglineController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _taglineOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _taglineSlide.value),
                            child: Text(
                              "Premium Chic Energy",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 19,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 2.2,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    )
                  : _showLogo
                      ? AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _exitOpacity.value,
                              child: Transform.scale(
                                scale: _exitScale.value,
                                child: Opacity(
                                  opacity: _logoOpacity.value,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Elastic logo icon monogram
                                      Transform.scale(
                                        scale: _iconScale.value,
                                        child: Container(
                                          width: 86,
                                          height: 86,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3.5),
                                            color: Colors.white.withValues(alpha: 0.05),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withValues(alpha: 0.04),
                                                blurRadius: 15,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'S',
                                              style: GoogleFonts.bebasNeue(
                                                color: Colors.white,
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      // Expanding brand name text
                                      Text(
                                        'SLAAY STUDIO',
                                        style: GoogleFonts.bebasNeue(
                                          color: Colors.white,
                                          fontSize: 36,
                                          letterSpacing: _logoLetterSpacing.value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final path1 = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.02,
        size.width * 1.1,
        size.height * 0.28,
      );

    final path2 = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.09,
        size.width * 1.1,
        size.height * 0.35,
      );

    final path3 = Path()
      ..moveTo(-size.width * 0.1, size.height * 0.29)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.16,
        size.width * 1.1,
        size.height * 0.42,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
