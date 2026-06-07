import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import 'home_screen.dart';
import '../../product/screens/search_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../product/providers/product_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/login_bottom_sheet.dart';
import '../../../core/widgets/glassmorphic_container.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../product/screens/new_drops_screen.dart';
import '../../profile/models/order.dart';
import '../../../services/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/orders_screen.dart';
import '../../profile/screens/saved_addresses_screen.dart';
import '../../profile/screens/coupons_screen.dart';
import '../../profile/screens/faqs_screen.dart';
import '../../profile/screens/help_support_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../notification/widgets/notification_illustration.dart';
import '../../../services/notification_service.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0.0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const NewDropsScreen(isPrimaryTab: true),
    const CartScreen(isPrimaryTab: true),
    const ProfileScreen(isPrimaryTab: true),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = MainNavigationWrapper.activeTabNotifier.value;
    MainNavigationWrapper.activeTabNotifier.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowNotificationPrompt();
    });
  }

  Future<void> _checkAndShowNotificationPrompt() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final status = await Permission.notification.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        final prefs = await SharedPreferences.getInstance();
        final lastPromptStr = prefs.getString('last_notification_prompt_time');
        bool shouldPrompt = false;
        
        if (lastPromptStr == null) {
          shouldPrompt = true;
        } else {
          final lastPromptTime = DateTime.parse(lastPromptStr);
          final difference = DateTime.now().difference(lastPromptTime);
          if (difference.inDays >= 3) {
            shouldPrompt = true;
          }
        }

        if (shouldPrompt && mounted) {
          _showEnableNotificationsBottomSheet(context);
        }
      }
    } catch (e) {
      debugPrint('Error checking notification permissions: $e');
    }
  }

  Future<void> _updateNotificationPromptTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_notification_prompt_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving last notification prompt time: $e');
    }
  }

  Future<void> _handlePermissionAction() async {
    try {
      final status = await Permission.notification.status;
      if (status.isPermanentlyDenied) {
        openAppSettings();
      } else {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          if (mounted) {
            NotificationService().init(context);
          }
        } else if (result.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  void _showEnableNotificationsBottomSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? AppColors.surfaceDark : Colors.white;
    final titleColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final buttonTextColor = isDarkMode ? Colors.black : Colors.white;
    final buttonBgColor = isDarkMode ? Colors.white : const Color(0xFF1D1D1D);
    final outlineBorderColor = isDarkMode ? Colors.white30 : const Color(0xFF1D1D1D);
    final outlineTextColor = isDarkMode ? Colors.white : const Color(0xFF1D1D1D);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Enable Notifications?',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: titleColor,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const NotificationIllustration(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Be the first to know about new products, exclusive collections, latest trends, stories and more with our insider alerts.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: subtitleColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: outlineBorderColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'NOT NOW',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: outlineTextColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        _handlePermissionAction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBgColor,
                        foregroundColor: buttonTextColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'YES, PLEASE',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDarkMode ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _updateNotificationPromptTime();
    });
  }

  @override
  void dispose() {
    MainNavigationWrapper.activeTabNotifier.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) {
      final newIndex = MainNavigationWrapper.activeTabNotifier.value;
      setState(() {
        _currentIndex = newIndex;
        _isNavBarVisible = true;
        _lastScrollOffset = 0.0;
      });
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
    MainNavigationWrapper.activeTabNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
          MainNavigationWrapper.activeTabNotifier.value = 0;
        }
      },
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBgColor(context),
          extendBody: true, // Bleeds content underneath the floating bar
          body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),

            // Static Floating Glassmorphic Capsule Nav Bar
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF3A2F3D).withValues(alpha: 0.8) : const Color(0xFFFFFFFF).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF534854) : const Color(0xFFE0D0D0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDarkMode ? 0.35 : 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double itemWidth = width / 5;
                        const double indicatorWidth = 42;
                        final double leftPosition = (itemWidth * _currentIndex) + (itemWidth - indicatorWidth) / 2;

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Sliding White Circle Pill Indicator behind the active tab icon
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.fastOutSlowIn,
                              left: leftPosition,
                              top: (constraints.maxHeight - indicatorWidth) / 2,
                              width: indicatorWidth,
                              height: indicatorWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent, // Gold Foil active highlight!
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Navigation Items
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildNavItem(0, HugeIcons.strokeRoundedHome01, HugeIcons.strokeRoundedHome01),
                                _buildNavItem(1, HugeIcons.strokeRoundedSearch01, HugeIcons.strokeRoundedSearch01),
                                _buildNavItem(
                                  2, 
                                  HugeIcons.strokeRoundedSparkles, 
                                  HugeIcons.strokeRoundedSparkles, 
                                ),
                                _buildNavItem(
                                  3, 
                                  HugeIcons.strokeRoundedShoppingBag01, 
                                  HugeIcons.strokeRoundedShoppingBag01, 
                                  badgeCount: cartProvider.totalItemsCount,
                                ),
                                _buildNavItem(4, HugeIcons.strokeRoundedUser, HugeIcons.strokeRoundedUser),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  String _getLottieAssetName(int index) {
    switch (index) {
      case 0: return 'home';
      case 1: return 'search';
      case 2: return 'wishlist';
      case 3: return 'cart';
      case 4: return 'profile';
      default: return 'home';
    }
  }

  Widget _buildNavItem(int index, List<List<dynamic>> outlineIcon, List<List<dynamic>> filledIcon, {int badgeCount = 0}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (index == 4 && !authProvider.isAuthenticated) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const LoginBottomSheet(),
            ).then((_) {
              if (mounted && authProvider.isAuthenticated) {
                _onTabTapped(4);
              }
            });
          } else {
            _onTabTapped(index);
          }
        },
        child: SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
               Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: (index == 0 || index == 1 || index == 2)
                    ? HugeIcon(
                        icon: isSelected ? filledIcon : outlineIcon,
                        color: isSelected ? const Color(0xFF3A2F3D) : (isDarkMode ? const Color(0xFFC0A0B0) : const Color(0xFF807090)),
                        size: 24,
                      )
                    : Lottie.asset(
                        'assets/LottieAssets/${_getLottieAssetName(index)}.json',
                        width: 24,
                        height: 24,
                        animate: isSelected,
                        repeat: false,
                        delegates: LottieDelegates(
                          values: [
                            ValueDelegate.colorFilter(
                              const ['**'],
                              value: ColorFilter.mode(
                                isSelected ? const Color(0xFF3A2F3D) : (isDarkMode ? const Color(0xFFC0A0B0) : const Color(0xFF807090)),
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ),
                        errorBuilder: (context, error, stackTrace) {
                          return HugeIcon(
                            icon: isSelected ? filledIcon : outlineIcon,
                            color: isSelected ? const Color(0xFF3A2F3D) : (isDarkMode ? const Color(0xFFC0A0B0) : const Color(0xFF807090)),
                            size: 24,
                          );
                        },
                      ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== WISHLIST SCREEN ====================
class WishlistScreen extends StatelessWidget {
  final bool isPrimaryTab;
  const WishlistScreen({super.key, this.isPrimaryTab = false});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Find products currently wishlisted
    final wishlistedProducts = productProvider.products.where((p) => p.isWishlisted).toList();

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: (!isPrimaryTab && Navigator.of(context).canPop())
            ? IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: AppColors.primary,
                  size: Theme.of(context).platform == TargetPlatform.iOS ? 20 : 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'YOUR WISHLIST',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
      ),
      body: wishlistedProducts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedFavourite,
                      size: 72,
                      color: AppColors.borderLight,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your wishlist is empty',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save your favorite handcrafted items here to buy them later.',
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.53,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: wishlistedProducts.length,
              itemBuilder: (context, index) {
                final product = wishlistedProducts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(productId: product.slug),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white12 : const Color(0xFFF2F2F2),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: product.images[0],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white.withValues(alpha: 0.85),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedDelete01,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    productProvider.toggleWishlist(product.id);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.fabric,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.name,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${product.price.toInt()}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (product.originalPrice > product.price)
                            Text(
                              '₹${product.originalPrice.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}

// ==================== PROFILE SCREEN ====================
class ProfileScreen extends StatefulWidget {
  final bool isPrimaryTab;
  const ProfileScreen({super.key, this.isPrimaryTab = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orderHistory = [];
  bool _isLoading = true;
  bool? _wasAuthenticated;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchOrderHistory();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _fetchOrderHistory();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrderHistory([AuthProvider? authProvider]) async {
    final provider = authProvider ?? (mounted ? Provider.of<AuthProvider>(context, listen: false) : null);
    if (provider == null || !provider.isAuthenticated) {
      if (mounted) {
        setState(() {
          _orderHistory = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final history = await _orderService.getOrders();
      if (mounted) {
        setState(() {
          _orderHistory = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildGuestView(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  width: 1.5,
                ),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedUser,
                size: 45,
                color: isDarkMode ? Colors.white70 : AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            GlassmorphicContainer(
              padding: const EdgeInsets.all(24.0),
              color: isDarkMode
                  ? const Color(0x13FFFFFF)
                  : const Color(0x06000000),
              borderColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              child: Column(
                children: [
                  Text(
                    'UNLOCK YOUR PROFILE',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDarkMode ? Colors.white : AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Log in or sign up to view your orders, apply exclusive coupons, manage addresses, and personalize your ethnic wardrobe.',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      height: 1.6,
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const LoginBottomSheet(),
                  ).then((_) {
                    if (!mounted) return;
                    if (auth.isAuthenticated) {
                      _fetchOrderHistory(auth);
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? Colors.white : AppColors.primary,
                  foregroundColor: isDarkMode ? AppColors.primary : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'LOG IN / SIGN UP',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_wasAuthenticated != authProvider.isAuthenticated) {
      _wasAuthenticated = authProvider.isAuthenticated;
      if (authProvider.isAuthenticated) {
        _isLoading = true;
        _fetchOrderHistory();
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: (!widget.isPrimaryTab && Navigator.of(context).canPop())
            ? IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  color: AppColors.primary,
                  size: Theme.of(context).platform == TargetPlatform.iOS ? 20 : 24,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'MY PROFILE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            letterSpacing: 3,
            fontSize: 16,
          ),
        ),
      ),
      body: !authProvider.isAuthenticated
          ? _buildGuestView(context, isDarkMode)
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Information Card
                  Card(
                    elevation: 0,
                    color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDarkMode ? Colors.white12 : AppColors.borderLight),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedUser,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      authProvider.userName ?? 'Slaay User',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.phoneNumber != null ? '+91 ${authProvider.phoneNumber}' : '',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12, 
                                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    if (authProvider.email != null && !authProvider.email!.startsWith('phone_') && authProvider.email!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        authProvider.email!,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                  ).then((_) {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if ((authProvider.gender != null && authProvider.gender!.isNotEmpty) || 
                              (authProvider.dob != null && authProvider.dob!.isNotEmpty)) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (authProvider.gender != null && authProvider.gender!.isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            authProvider.gender!,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12, 
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (authProvider.dob != null && authProvider.dob!.isNotEmpty)
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const HugeIcon(icon: HugeIcons.strokeRoundedCalendar01, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _formatDob(authProvider.dob),
                                            style: GoogleFonts.outfit(
                                              fontSize: 12, 
                                              fontWeight: FontWeight.w600,
                                              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Complete Profile Card Prompt
                  if (() {
                    final isProfileIncomplete = (authProvider.gender == null || authProvider.gender!.isEmpty) ||
                        (authProvider.dob == null || authProvider.dob!.isEmpty) ||
                        (authProvider.email == null || authProvider.email!.startsWith('phone_') || authProvider.email!.isEmpty) ||
                        (authProvider.userName == null || authProvider.userName!.startsWith('User_') || authProvider.userName!.isEmpty);
                    return isProfileIncomplete;
                  }()) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDarkMode 
                              ? [AppColors.primary.withValues(alpha: 0.2), AppColors.surfaceDark] 
                              : [AppColors.primary.withValues(alpha: 0.05), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Complete Your Profile',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Provide your name, email, gender, and date of birth to get personal recommendations and a premium shopping experience.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              height: 1.5,
                              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                ).then((_) {
                                  if (mounted) {
                                    setState(() {});
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(
                                'COMPLETE PROFILE',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  _buildMenuItem(
                    icon: HugeIcons.strokeRoundedShoppingBag01,
                    title: 'My Orders',
                    subtitle: 'View and track your order history',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OrdersScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: HugeIcons.strokeRoundedLocation01,
                    title: 'Saved Addresses',
                    subtitle: 'Manage your shipping address options',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SavedAddressesScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: HugeIcons.strokeRoundedTicket01,
                    title: 'Coupons & Offers',
                    subtitle: 'Active promo codes and seasonal discounts',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CouponsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: HugeIcons.strokeRoundedHelpCircle,
                    title: 'FAQs',
                    subtitle: 'Find quick answers to common questions',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FaqsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: HugeIcons.strokeRoundedCustomerService,
                    title: 'Help & Support',
                    subtitle: 'Submit tickets and contact customer care',
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                      );
                    },
                  ),



                  const SizedBox(height: 40),

                  // Logout
                  OutlinedButton(
                    onPressed: () async {
                      await authProvider.logout();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('LOG OUT'),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return '';
    try {
      String datePart = dob.split('T')[0];
      DateTime parsed = DateFormat('yyyy-MM-dd').parse(datePart);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (e) {
      if (dob.contains('T')) {
        return dob.split('T')[0];
      }
      return dob;
    }
  }

  Widget _buildMenuItem({
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        trailing: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 16,
          color: AppColors.primary,
        ),
        onTap: onTap,
      ),
    );
  }
}
