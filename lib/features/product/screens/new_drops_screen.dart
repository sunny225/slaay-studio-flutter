import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'dart:ui';
import '../../../services/product_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/press_scale_effect.dart';
import '../../../core/widgets/smooth_page_route.dart';

class NewDropsScreen extends StatefulWidget {
  final bool isPrimaryTab;

  const NewDropsScreen({
    super.key,
    this.isPrimaryTab = false,
  });

  @override
  State<NewDropsScreen> createState() => _NewDropsScreenState();
}

class _NewDropsScreenState extends State<NewDropsScreen> {
  // 0: List View (1 column), 1: Grid 2x2 (2 columns), 2: Grid 3x3 (3 columns)
  int _layoutMode = 1;
  String _selectedSubFilter = 'ALL';

  final List<String> _subFilters = [
    'ALL',
    'NEW',
    'CORE LAB',
    'BAGGY',
    'RELAXED',
  ];

  final ProductService _productService = ProductService();
  List<Product>? _filteredProducts;
  bool _isLoadingProducts = false;

  // Filter selections
  final List<String> _selectedSizes = [];
  final List<String> _selectedColors = [];
  final List<String> _selectedPatterns = [];
  final List<String> _selectedFits = [];
  final List<String> _selectedMaterials = [];
  double _minPrice = 500;
  double _maxPrice = 12000;
  bool _hasPriceFilter = false;

  @override
  void initState() {
    super.initState();
    _loadFilteredProducts();
  }

  Future<void> _loadFilteredProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _productService.getProducts(
        sizes: _selectedSizes.isNotEmpty ? _selectedSizes : null,
        colors: _selectedColors.isNotEmpty ? _selectedColors : null,
        patterns: _selectedPatterns.isNotEmpty ? _selectedPatterns : null,
        fits: _selectedFits.isNotEmpty ? _selectedFits : null,
        materials: _selectedMaterials.isNotEmpty ? _selectedMaterials : null,
        minPrice: _hasPriceFilter ? _minPrice : null,
        maxPrice: _hasPriceFilter ? _maxPrice : null,
      );

      // Perform local filtering to only include "New Drops"
      final filteredNewDrops = products.where((p) {
        final nameLower = p.name.toLowerCase();
        final descLower = p.description.toLowerCase();
        final occasionLower = p.occasion.toLowerCase();
        
        final isNewOccasion = occasionLower.contains('new') || occasionLower.contains('modern');
        final isNewName = nameLower.contains('new') || nameLower.contains('modern') || nameLower.contains('pastel');
        final isNewDescription = descLower.contains('new') || descLower.contains('modern');
        final isNewCategory = p.category.toLowerCase() == 'fusion wear';

        return isNewOccasion || isNewName || isNewDescription || isNewCategory;
      }).toList();

      if (mounted) {
        setState(() {
          _filteredProducts = filteredNewDrops;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Default list fallback when filters are not loaded yet
    final productProvider = Provider.of<ProductProvider>(context);
    final displayedProducts = _filteredProducts ?? productProvider.products.where((p) {
      final nameLower = p.name.toLowerCase();
      final descLower = p.description.toLowerCase();
      final occasionLower = p.occasion.toLowerCase();
      
      final isNewOccasion = occasionLower.contains('new') || occasionLower.contains('modern');
      final isNewName = nameLower.contains('new') || nameLower.contains('modern') || nameLower.contains('pastel');
      final isNewDescription = descLower.contains('new') || descLower.contains('modern');
      final isNewCategory = p.category.toLowerCase() == 'fusion wear';

      return isNewOccasion || isNewName || isNewDescription || isNewCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: widget.isPrimaryTab
            ? null
              : Padding(
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
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
                        size: Theme.of(context).platform == TargetPlatform.iOS ? 18 : 22,
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
          'NEW DROPS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 40,
              height: 40,
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
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: isDarkMode ? AppColors.textPrimaryDark : const Color(0xFF121111),
                  size: 18,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    SmoothPageRoute(
                      child: const SearchScreen(),
                      direction: AxisDirection.right,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          
          // Horizontal Pill selector
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _subFilters.length,
              itemBuilder: (context, index) {
                final filter = _subFilters[index];
                final isSelected = _selectedSubFilter == filter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubFilter = filter;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? AppColors.borderDark : const Color(0xFFE2E2E2)),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? (isDarkMode ? Colors.black : Colors.white) : (isDarkMode ? Colors.white70 : Colors.black),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Filters & Layout Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Layout Switcher Buttons using HugeIcons
                Row(
                  children: [
                    // Grid 2x2 View mode (2 columns)
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedGrid02,
                        color: _layoutMode == 1 ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white30 : Colors.black26),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _layoutMode = 1),
                    ),
                    // Grid 3x3 View mode (3 columns)
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedDashboardSquare01,
                        color: _layoutMode == 2 ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white30 : Colors.black26),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _layoutMode = 2),
                    ),
                    // List View mode (1 column)
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedListView,
                        color: _layoutMode == 0 ? (isDarkMode ? Colors.white : Colors.black) : (isDarkMode ? Colors.white30 : Colors.black26),
                        size: 22,
                      ),
                      onPressed: () => setState(() => _layoutMode = 0),
                    ),
                  ],
                ),

                // Filter Option on the right end
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFilter,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    size: 22,
                  ),
                  onPressed: () {
                    _showFilterBottomSheet(context);
                  },
                ),
              ],
            ),
          ),

          // Main product feed list / grid
          Expanded(
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : displayedProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductFeed(displayedProducts, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedHourglass,
            size: 64,
            color: AppColors.borderLight,
          ),
          const SizedBox(height: 16),
          Text(
            'New drops coming soon',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are crafting premium ethnic pieces for this drop.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductFeed(List<Product> products, bool isDarkMode) {
    if (_layoutMode == 0) {
      // List Mode (1 column full-width details)
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductListItem(product, isDarkMode);
        },
      );
    } else {
      // Grid Mode (2 columns or 3 columns)
      final columns = _layoutMode == 1 ? 2 : 3;
      final childAspectRatio = _layoutMode == 1 ? 0.52 : 0.46;

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: _layoutMode == 1 ? 14 : 10,
          mainAxisSpacing: _layoutMode == 1 ? 14 : 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductGridItem(product, isDarkMode, _layoutMode == 1);
        },
      );
    }
  }

  Widget _buildProductListItem(Product product, bool isDarkMode) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return PressScaleEffect(
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(
            child: ProductDetailScreen(productId: product.slug),
            direction: AxisDirection.right,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF2F2F2)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: product.images[0],
                    width: 120,
                    height: 140,
                    fit: BoxFit.cover,
                    memCacheWidth: 240,
                  ),
                ),
                if (product.isOos)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SOLD OUT',
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!product.isOos && product.totalStockLeft < 6)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ONLY ${product.totalStockLeft} LEFT!',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.fabric,
                    style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toInt()}',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      if (product.originalPrice > product.price)
                        Text(
                          '₹${product.originalPrice.toInt()}',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight, decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildColorIndicatorDots(),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: product.isWishlisted ? Colors.red : Colors.black45,
                size: 20,
              ),
              onPressed: () {
                productProvider.toggleWishlist(product.id);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridItem(Product product, bool isDarkMode, bool showDetails) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return PressScaleEffect(
      onTap: () {
        Navigator.push(
          context,
          SmoothPageRoute(
            child: ProductDetailScreen(productId: product.slug),
            direction: AxisDirection.right,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Image box with border matching PLP screenshots
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF2F2F2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: product.images[0],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(color: const Color(0xFFF6F6F6)),
                      memCacheWidth: 360,
                    ),
                  ),
                ),
                
                // Out of stock overlay
                if (product.isOos)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SOLD OUT',
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // FOMO overlay
                if (!product.isOos && product.totalStockLeft < 6)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'ONLY ${product.totalStockLeft} LEFT!',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Wishlist heart overlay using HugeIcons
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        product.isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: product.isWishlisted ? Colors.red : Colors.black87,
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

          // Titles, price, and color indicators
          if (showDetails) ...[
            Text(
              product.fabric,
              style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            product.name,
            style: GoogleFonts.outfit(
              fontSize: showDetails ? 12.5 : 11,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
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
                  fontSize: showDetails ? 13 : 11.5,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              if (product.originalPrice > product.price)
                Text(
                  '₹${product.originalPrice.toInt()}',
                  style: GoogleFonts.outfit(
                    fontSize: showDetails ? 10.5 : 9.5,
                    color: AppColors.textSecondaryLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: 6),
            _buildColorIndicatorDots(),
          ],
        ],
      ),
    );
  }

  Widget _buildColorIndicatorDots() {
    final colors = [
      const Color(0xFF1C1C1C), // black
      const Color(0xFF904F90), // purple
      const Color(0xFF4361EE), // blue
      const Color(0xFF4CAF50), // green
    ];

    return Row(
      children: colors.map((col) {
        return Container(
          margin: const EdgeInsets.only(right: 4),
          width: 7.5,
          height: 7.5,
          decoration: BoxDecoration(
            color: col,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            Widget buildFilterChip(String label, List<String> selectedList, String value) {
              final isSelected = selectedList.contains(value);
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    if (isSelected) {
                      selectedList.remove(value);
                    } else {
                      selectedList.add(value);
                    }
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.black
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.black : const Color(0xFFE2E2E2),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'FILTERS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: Colors.black,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      _selectedSizes.clear();
                                      _selectedColors.clear();
                                      _selectedPatterns.clear();
                                      _selectedFits.clear();
                                      _selectedMaterials.clear();
                                      _hasPriceFilter = false;
                                      _minPrice = 500;
                                      _maxPrice = 12000;
                                    });
                                  },
                                  child: Text(
                                    'Clear All',
                                    style: GoogleFonts.outfit(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(20),
                              children: [
                                Text(
                                  'SIZE',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  children: [
                                    buildFilterChip('XS', _selectedSizes, 'XS'),
                                    buildFilterChip('S', _selectedSizes, 'S'),
                                    buildFilterChip('M', _selectedSizes, 'M'),
                                    buildFilterChip('L', _selectedSizes, 'L'),
                                    buildFilterChip('XL', _selectedSizes, 'XL'),
                                    buildFilterChip('XXL', _selectedSizes, 'XXL'),
                                    buildFilterChip('One Size', _selectedSizes, 'One Size'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'COLOR',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  children: [
                                    buildFilterChip('Indigo', _selectedColors, 'Indigo'),
                                    buildFilterChip('Crimson', _selectedColors, 'Crimson'),
                                    buildFilterChip('Pink', _selectedColors, 'Pink'),
                                    buildFilterChip('Mint', _selectedColors, 'Mint'),
                                    buildFilterChip('Mustard', _selectedColors, 'Mustard'),
                                    buildFilterChip('Peach', _selectedColors, 'Peach'),
                                    buildFilterChip('Black', _selectedColors, 'Black'),
                                    buildFilterChip('Ivory', _selectedColors, 'Ivory'),
                                    buildFilterChip('Lavender', _selectedColors, 'Lavender'),
                                    buildFilterChip('Gold', _selectedColors, 'Gold'),
                                    buildFilterChip('Orange', _selectedColors, 'Orange'),
                                    buildFilterChip('Fuchsia', _selectedColors, 'Fuchsia'),
                                    buildFilterChip('Emerald', _selectedColors, 'Emerald'),
                                    buildFilterChip('Blue', _selectedColors, 'Blue'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'PATTERN',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  children: [
                                    buildFilterChip('Floral', _selectedPatterns, 'Floral'),
                                    buildFilterChip('Block Print', _selectedPatterns, 'Block Print'),
                                    buildFilterChip('Printed', _selectedPatterns, 'Printed'),
                                    buildFilterChip('Zari Woven', _selectedPatterns, 'Zari Woven'),
                                    buildFilterChip('Embroidered', _selectedPatterns, 'Embroidered'),
                                    buildFilterChip('Solid', _selectedPatterns, 'Solid'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'FIT',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  children: [
                                    buildFilterChip('Flared Fit', _selectedFits, 'Flared Fit'),
                                    buildFilterChip('Regular Fit', _selectedFits, 'Regular Fit'),
                                    buildFilterChip('Straight Fit', _selectedFits, 'Straight Fit'),
                                    buildFilterChip('Relaxed Fit', _selectedFits, 'Relaxed Fit'),
                                    buildFilterChip('A-Line Fit', _selectedFits, 'A-Line Fit'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'MATERIAL',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  children: [
                                    buildFilterChip('Chanderi Silk', _selectedMaterials, 'Chanderi'),
                                    buildFilterChip('Cotton', _selectedMaterials, 'Cotton'),
                                    buildFilterChip('Katan Silk', _selectedMaterials, 'Katan Silk'),
                                    buildFilterChip('Georgette', _selectedMaterials, 'Georgette'),
                                    buildFilterChip('Velvet', _selectedMaterials, 'Velvet'),
                                    buildFilterChip('Organza', _selectedMaterials, 'Organza'),
                                    buildFilterChip('Linen', _selectedMaterials, 'Linen'),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PRICE RANGE',
                                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black),
                                    ),
                                    Switch.adaptive(
                                      activeColor: Colors.black,
                                      value: _hasPriceFilter,
                                      onChanged: (val) {
                                        setModalState(() {
                                          _hasPriceFilter = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (_hasPriceFilter) ...[
                                  RangeSlider(
                                    values: RangeValues(_minPrice, _maxPrice),
                                    min: 500,
                                    max: 12000,
                                    divisions: 23,
                                    labels: RangeLabels(
                                      '₹${_minPrice.toInt()}',
                                      '₹${_maxPrice.toInt()}',
                                    ),
                                    activeColor: Colors.black,
                                    inactiveColor: Colors.black12,
                                    onChanged: (RangeValues values) {
                                      setModalState(() {
                                        _minPrice = values.start;
                                        _maxPrice = values.end;
                                      });
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('₹${_minPrice.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                                      Text('₹${_maxPrice.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                                    ],
                                  ),
                                ] else
                                  Text(
                                    'Any price',
                                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
                                  ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _loadFilteredProducts();
                              },
                              child: Text(
                                'APPLY FILTERS',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
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
      },
    );
  }
}
