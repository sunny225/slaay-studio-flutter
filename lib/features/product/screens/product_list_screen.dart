import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../models/collection_model.dart';
import '../models/category_model.dart';
import 'product_detail_screen.dart';
import 'search_screen.dart';
import 'dart:ui';
import '../../../services/product_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/press_scale_effect.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../core/widgets/liquid_background.dart';

class ProductListScreen extends StatefulWidget {
  final String collectionName;

  const ProductListScreen({
    super.key,
    required this.collectionName,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // 0: List View (1 column), 1: Grid 2x2 (2 columns), 2: Grid 3x3 (3 columns)
  int _layoutMode = 1;
  String _selectedSubFilter = 'ALL';

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
        category: widget.collectionName,
        sizes: _selectedSizes.isNotEmpty ? _selectedSizes : null,
        colors: _selectedColors.isNotEmpty ? _selectedColors : null,
        patterns: _selectedPatterns.isNotEmpty ? _selectedPatterns : null,
        fits: _selectedFits.isNotEmpty ? _selectedFits : null,
        materials: _selectedMaterials.isNotEmpty ? _selectedMaterials : null,
        minPrice: _hasPriceFilter ? _minPrice : null,
        maxPrice: _hasPriceFilter ? _maxPrice : null,
      );

      if (mounted) {
        setState(() {
          _filteredProducts = products;
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
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Look up collection by name
    final matchedCol = productProvider.collectionObjects.firstWhere(
      (col) => col.name.toLowerCase() == widget.collectionName.toLowerCase(),
      orElse: () => CollectionModel(id: '', name: '', slug: '', image: ''),
    );

    final parentCategory = productProvider.categoryObjects.firstWhere(
      (c) => c.name.toLowerCase() == widget.collectionName.toLowerCase() || 
             c.slug.toLowerCase() == widget.collectionName.toLowerCase(),
      orElse: () => CategoryModel(id: '', name: '', slug: '', image: ''),
    );

    List<CategoryModel> childCategories = [];
    if (parentCategory.id.isNotEmpty) {
      childCategories = productProvider.categoryObjects
          .where((c) => c.parentId == parentCategory.id)
          .toList();
    }

    // Filter products for this collection / category (including subcategories)
    final categoryProducts = _filteredProducts ?? productProvider.products.where((p) {
      final matchesCategory = p.category.toLowerCase() == widget.collectionName.toLowerCase();
      final matchesSubcategory = childCategories.isNotEmpty && 
          childCategories.any((sub) => p.category.toLowerCase() == sub.name.toLowerCase() || p.category.toLowerCase() == sub.slug.toLowerCase());
      final matchesCollection = matchedCol.id.isNotEmpty && p.collections.contains(matchedCol.id);
      return matchesCategory || matchesSubcategory || matchesCollection;
    }).toList();

    final List<String> activeSubFilters = ['ALL', 'NEW'];
    
    // Dynamically collect unique categories of products in this catalog view
    final Set<String> categoriesInCatalog = categoryProducts.map((p) => p.category).toSet();
    
    if (matchedCol.id.isNotEmpty) {
      // For collections, dynamically add categories of products in this collection
      activeSubFilters.addAll(categoriesInCatalog.map((c) => c.toUpperCase()));
    } else if (childCategories.isNotEmpty) {
      // For parent categories, show child subcategories
      activeSubFilters.addAll(childCategories.map((c) => c.name.toUpperCase()));
    }

    var displayedProducts = categoryProducts;
    if (_selectedSubFilter != 'ALL') {
      final isChildCat = childCategories.any((c) => c.name.toUpperCase() == _selectedSubFilter);
      if (isChildCat) {
        final matchedSub = childCategories.firstWhere((c) => c.name.toUpperCase() == _selectedSubFilter);
        displayedProducts = displayedProducts.where((p) => 
          p.category.toLowerCase() == matchedSub.name.toLowerCase() ||
          p.category.toLowerCase() == matchedSub.slug.toLowerCase()
        ).toList();
      } else if (_selectedSubFilter == 'NEW') {
        final sortedProducts = List<Product>.from(displayedProducts);
        sortedProducts.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        final countToShow = (sortedProducts.length * 0.4).round().clamp(3, sortedProducts.length);
        displayedProducts = sortedProducts.take(countToShow).toList();
      } else {
        // Fallback or collection categories match (case-insensitive exact category or contains check)
        displayedProducts = displayedProducts.where((p) => 
          p.category.toLowerCase() == _selectedSubFilter.toLowerCase() ||
          p.fit.toLowerCase().contains(_selectedSubFilter.toLowerCase()) ||
          p.category.toLowerCase().contains(_selectedSubFilter.toLowerCase())
        ).toList();
      }
    }

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              icon: Icon(Theme.of(context).platform == TargetPlatform.iOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: const Color(0xFF121111), size: Theme.of(context).platform == TargetPlatform.iOS ? 16 : 22),
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
          widget.collectionName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF121111),
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
                color: Colors.white,
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
                icon: const Icon(Icons.search, color: Color(0xFF121111), size: 18),
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
              itemCount: activeSubFilters.length,
              itemBuilder: (context, index) {
                final filter = activeSubFilters[index];
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
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.black : const Color(0xFFE2E2E2),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
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
                // Layout Switcher Buttons matching screenshot order: 2x2 grid, 3x3 grid, list view
                Row(
                  children: [
                    // Grid 2x2 View mode (2 columns)
                    IconButton(
                      icon: Icon(
                        Icons.grid_view,
                        color: _layoutMode == 1 ? Colors.black : Colors.black26,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _layoutMode = 1),
                    ),
                    // Grid 3x3 View mode (3 columns)
                    IconButton(
                      icon: Icon(
                        Icons.grid_on,
                        color: _layoutMode == 2 ? Colors.black : Colors.black26,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _layoutMode = 2),
                    ),
                    // List View mode (1 column)
                    IconButton(
                      icon: Icon(
                        Icons.view_headline,
                        color: _layoutMode == 0 ? Colors.black : Colors.black26,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _layoutMode = 0),
                    ),
                  ],
                ),

                // Filter Option on the right end - just the tune icon matching Screenshot 5
                IconButton(
                  icon: Icon(
                    Icons.tune,
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
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.borderLight),
          const SizedBox(height: 16),
          Text(
            'Collection coming soon',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are crafting premium ethnic pieces for this category.',
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
                color: product.isWishlisted ? AppColors.error : Colors.black45,
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

                // Wishlist heart overlay
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
                        color: product.isWishlisted ? AppColors.error : Colors.black87,
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
              color: Colors.black,
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
                  color: Colors.black,
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
              final primaryColor = isDarkMode ? Colors.white : Colors.black;
              final textColor = isSelected
                  ? (isDarkMode ? Colors.black : Colors.white)
                  : (isDarkMode ? Colors.white70 : Colors.black87);
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
                        ? primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : (isDarkMode ? Colors.white24 : const Color(0xFFE2E2E2)),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }

            final productProvider = Provider.of<ProductProvider>(context, listen: false);
            final rawProductsInCatalog = _filteredProducts ?? productProvider.products;

            // Look up collection by name
            final matchedCol = productProvider.collectionObjects.firstWhere(
              (col) => col.name.toLowerCase() == widget.collectionName.toLowerCase(),
              orElse: () => CollectionModel(id: '', name: '', slug: '', image: ''),
            );

            final parentCategory = productProvider.categoryObjects.firstWhere(
              (c) => c.name.toLowerCase() == widget.collectionName.toLowerCase() || 
                     c.slug.toLowerCase() == widget.collectionName.toLowerCase(),
              orElse: () => CategoryModel(id: '', name: '', slug: '', image: ''),
            );

            List<CategoryModel> childCategories = [];
            if (parentCategory.id.isNotEmpty) {
              childCategories = productProvider.categoryObjects
                  .where((c) => c.parentId == parentCategory.id)
                  .toList();
            }

            final categoryProducts = rawProductsInCatalog.where((p) {
              final matchesCategory = p.category.toLowerCase() == widget.collectionName.toLowerCase();
              final matchesSubcategory = childCategories.isNotEmpty && 
                  childCategories.any((sub) => p.category.toLowerCase() == sub.name.toLowerCase() || p.category.toLowerCase() == sub.slug.toLowerCase());
              final matchesCollection = matchedCol.id.isNotEmpty && p.collections.contains(matchedCol.id);
              return matchesCategory || matchesSubcategory || matchesCollection;
            }).toList();

            // Extract unique available sizes
            final availableSizes = categoryProducts
                .expand((p) => p.sizes)
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList();
            const sizeOrder = {'XS': 0, 'S': 1, 'M': 2, 'L': 3, 'XL': 4, 'XXL': 5, '3XL': 6, 'One Size': 100};
            availableSizes.sort((a, b) {
              final orderA = sizeOrder[a] ?? 50;
              final orderB = sizeOrder[b] ?? 50;
              return orderA.compareTo(orderB);
            });

            // Extract unique available colors
            final availableColors = categoryProducts
                .map((p) => p.color)
                .where((c) => c.isNotEmpty && c.toLowerCase() != 'multi')
                .toSet()
                .toList();
            availableColors.sort();

            // Extract unique patterns
            final availablePatterns = categoryProducts
                .map((p) => p.pattern)
                .where((pat) => pat.isNotEmpty)
                .toSet()
                .toList();
            availablePatterns.sort();

            // Extract unique fits
            final availableFits = categoryProducts
                .map((p) => p.fit)
                .where((f) => f.isNotEmpty)
                .toSet()
                .toList();
            availableFits.sort();

            // Extract unique materials
            final availableMaterials = categoryProducts
                .map((p) => p.fabric)
                .where((m) => m.isNotEmpty)
                .toSet()
                .toList();
            availableMaterials.sort();

            final headerTextColor = isDarkMode ? Colors.white : Colors.black;

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
                              color: isDarkMode ? Colors.white24 : Colors.black26,
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
                                    color: headerTextColor,
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
                                if (availableSizes.isNotEmpty) ...[
                                  Text(
                                    'SIZE',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: headerTextColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    children: availableSizes.map((size) {
                                      return buildFilterChip(size, _selectedSizes, size);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (availableColors.isNotEmpty) ...[
                                  Text(
                                    'COLOR',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: headerTextColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    children: availableColors.map((color) {
                                      return buildFilterChip(color, _selectedColors, color);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (availablePatterns.isNotEmpty) ...[
                                  Text(
                                    'PATTERN',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: headerTextColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    children: availablePatterns.map((pat) {
                                      return buildFilterChip(pat, _selectedPatterns, pat);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (availableFits.isNotEmpty) ...[
                                  Text(
                                    'FIT',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: headerTextColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    children: availableFits.map((fit) {
                                      return buildFilterChip(fit, _selectedFits, fit);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (availableMaterials.isNotEmpty) ...[
                                  Text(
                                    'MATERIAL',
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: headerTextColor),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    children: availableMaterials.map((mat) {
                                      return buildFilterChip(mat, _selectedMaterials, mat);
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PRICE RANGE',
                                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: headerTextColor),
                                    ),
                                    Switch.adaptive(
                                      activeColor: isDarkMode ? Colors.white : Colors.black,
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
                                    activeColor: isDarkMode ? Colors.white : Colors.black,
                                    inactiveColor: isDarkMode ? Colors.white24 : Colors.black12,
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
                                      Text('₹${_minPrice.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: headerTextColor)),
                                      Text('₹${_maxPrice.toInt()}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: headerTextColor)),
                                    ],
                                  ),
                                ] else
                                  Text(
                                    'Any price',
                                    style: GoogleFonts.outfit(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54),
                                  ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? Colors.white : Colors.black,
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
                                  color: isDarkMode ? Colors.black : Colors.white,
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
