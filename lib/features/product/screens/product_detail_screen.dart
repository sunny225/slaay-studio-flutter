import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/screens/main_navigation_wrapper.dart';
import '../../../services/product_service.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/press_scale_effect.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../core/widgets/liquid_background.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final PageController _pageController = PageController();
  
  String? _selectedSize;
  String? _selectedColor;
  ProductVariation? _selectedVariation;
  int _activeImageIndex = 0;
  Product? _product;
  List<Product> _recommendedProducts = [];
  bool _isLoading = true;
  int _quantity = 1;
  final int _selectedColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProductData() async {
    try {
      final product = await _productService.getProductById(widget.productId);
      List<Product> recommendations = await _productService.getRecommendations(product.completeTheLookIds);
      
      if (recommendations.length < 2) {
        try {
          final pinkShirt = await _productService.getProductBySlug('regular-fit-linen-blend-pink-shirt');
          final greenShirt = await _productService.getProductBySlug('regular-fit-linen-blend-light-green-shirt');
          if (!recommendations.any((r) => r.slug == pinkShirt.slug) && widget.productId != pinkShirt.slug) {
            recommendations.add(pinkShirt);
          }
          if (!recommendations.any((r) => r.slug == greenShirt.slug) && widget.productId != greenShirt.slug) {
            recommendations.add(greenShirt);
          }
        } catch (_) {}
      }

      setState(() {
        _product = product;
        _recommendedProducts = recommendations;
        _isLoading = false;
        
        if (product.hasVariations && product.variations.isNotEmpty) {
          ProductVariation firstVar = product.variations.first;
          try {
            firstVar = product.variations.firstWhere((v) => v.stock > 0);
          } catch (_) {
            firstVar = product.variations.first;
          }
          
          final hasSizes = product.variations.any((v) => v.size != null && v.size!.isNotEmpty);
          final hasColors = product.variations.any((v) => v.color != null && v.color!.isNotEmpty);
          
          String? initialSize;
          if (hasSizes) {
            try {
              initialSize = product.variations.firstWhere((v) => v.size != null && v.size!.isNotEmpty && v.stock > 0).size;
            } catch (_) {
              initialSize = firstVar.size;
            }
          }
          String? initialColor;
          if (hasColors) {
            try {
              initialColor = product.variations.firstWhere((v) => v.color != null && v.color!.isNotEmpty && v.stock > 0).color;
            } catch (_) {
              initialColor = firstVar.color;
            }
          }
          
          _selectedSize = initialSize;
          _selectedColor = initialColor;
          
          try {
            _selectedVariation = product.variations.firstWhere(
              (v) => (hasSizes ? v.size == initialSize : true) && (hasColors ? v.color == initialColor : true),
            );
          } catch (_) {
            _selectedVariation = firstVar;
          }
        } else {
          if (product.sizes.isNotEmpty) {
            _selectedSize = product.sizes[0];
          }
        }
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isSizeOutOfStock(String size) {
    if (_product == null) return true;
    if (!_product!.hasVariations) {
      return _product!.stock <= 0;
    }
    
    final variations = _product!.variations;
    final hasColors = variations.any((v) => v.color != null && v.color!.isNotEmpty);
    
    if (hasColors && _selectedColor != null) {
      final match = variations.firstWhere(
        (v) => v.size == size && v.color == _selectedColor,
        orElse: () => ProductVariation(sku: '', name: '', price: 0, stock: 0, images: []),
      );
      return match.stock <= 0;
    } else {
      final sizeVariations = variations.where((v) => v.size == size).toList();
      if (sizeVariations.isEmpty) return true;
      return sizeVariations.every((v) => v.stock <= 0);
    }
  }

  bool _isColorOutOfStock(String colorName) {
    if (_product == null) return true;
    if (!_product!.hasVariations) {
      return _product!.stock <= 0;
    }
    
    final variations = _product!.variations;
    final hasSizes = variations.any((v) => v.size != null && v.size!.isNotEmpty);
    
    if (hasSizes && _selectedSize != null) {
      final match = variations.firstWhere(
        (v) => v.color == colorName && v.size == _selectedSize,
        orElse: () => ProductVariation(sku: '', name: '', price: 0, stock: 0, images: []),
      );
      return match.stock <= 0;
    } else {
      final colorVariations = variations.where((v) => v.color == colorName).toList();
      if (colorVariations.isEmpty) return true;
      return colorVariations.every((v) => v.stock <= 0);
    }
  }

  void _updateSelectedVariation(String? size, String? color) {
    if (_product == null || !_product!.hasVariations || _product!.variations.isEmpty) return;
    
    final variations = _product!.variations;
    final hasSizes = variations.any((v) => v.size != null && v.size!.isNotEmpty);
    final hasColors = variations.any((v) => v.color != null && v.color!.isNotEmpty);

    ProductVariation match;
    if (hasSizes && hasColors) {
      match = variations.firstWhere(
        (v) => v.size == size && v.color == color,
        orElse: () => variations.firstWhere(
          (v) => v.size == size,
          orElse: () => variations.firstWhere(
            (v) => v.color == color,
            orElse: () => variations.first,
          ),
        ),
      );
    } else if (hasSizes) {
      match = variations.firstWhere(
        (v) => v.size == size,
        orElse: () => variations.first,
      );
    } else if (hasColors) {
      match = variations.firstWhere(
        (v) => v.color == color,
        orElse: () => variations.first,
      );
    } else {
      match = variations.first;
    }
    
    setState(() {
      _selectedSize = hasSizes ? match.size : null;
      _selectedColor = hasColors ? match.color : null;
      _selectedVariation = match;
      _activeImageIndex = 0;
    });
  }

  Color _parseHexColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  void _handleAddToCart(CartProvider cartProvider) {
    if (_product == null) return;
    
    String cartSize = 'Default';
    final hasSizes = _product!.hasVariations && _product!.variations.any((v) => v.size != null && v.size!.isNotEmpty);
    final hasColors = _product!.hasVariations && _product!.variations.any((v) => v.color != null && v.color!.isNotEmpty);

    if (_product!.hasVariations) {
      if (hasSizes && hasColors) {
        if (_selectedSize == null || _selectedColor == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select size and color!'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        cartSize = "$_selectedSize / $_selectedColor";
      } else if (hasSizes) {
        if (_selectedSize == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a size!'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        cartSize = _selectedSize!;
      } else if (hasColors) {
        if (_selectedColor == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a color!'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        cartSize = _selectedColor!;
      } else {
        cartSize = _selectedVariation?.name ?? 'Default';
      }
    } else {
      if (_selectedSize == null && _product!.sizes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a size first!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      cartSize = _selectedSize ?? 'M';
    }

    // Trigger haptic vibration feedback
    HapticFeedback.mediumImpact();

    final bool isAlreadyInCart = cartProvider.items.any(
      (item) => item.product.id == _product!.id && item.size == cartSize,
    );

    if (!isAlreadyInCart) {
      final finalProduct = Product(
        id: _product!.id,
        slug: _product!.slug,
        name: _product!.name,
        description: _product!.description,
        price: _selectedVariation != null ? _selectedVariation!.price : _product!.price,
        originalPrice: _selectedVariation != null ? (_selectedVariation!.comparePrice ?? _selectedVariation!.price) : _product!.originalPrice,
        images: (_selectedVariation != null && _selectedVariation!.images.isNotEmpty) ? _selectedVariation!.images : _product!.images,
        sizes: _product!.sizes,
        category: _product!.category,
        rating: _product!.rating,
        reviewsCount: _product!.reviewsCount,
        fabric: _product!.fabric,
        occasion: _product!.occasion,
        fit: _product!.fit,
        color: _product!.color,
        pattern: _product!.pattern,
        details: _product!.details,
        completeTheLookIds: _product!.completeTheLookIds,
        collections: _product!.collections,
        hasVariations: _product!.hasVariations,
        variations: _product!.variations,
        isWishlisted: _product!.isWishlisted,
        createdAt: _product!.createdAt,
      );
      cartProvider.addToCart(finalProduct, cartSize, quantity: _quantity);
    }

    // Show custom confirmation bottom sheet
    _showAddedToCartBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    final bool isOutOfStock = _product != null && (_product!.hasVariations
        ? (_selectedVariation != null && _selectedVariation!.stock <= 0)
        : false);

    if (_isLoading) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const ProductDetailSkeleton(),
        ),
      );
    }

    if (_product == null) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Product Details')),
          body: const Center(child: Text('Product not found.')),
        ),
      );
    }

    return LiquidBackground(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
        body: Stack(
          children: [
          // Main Scrollable View
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Swiper
                Stack(
                  children: [
                    SizedBox(
                      height: size.height * 0.58,
                      width: double.infinity,
                      child: Builder(
                        builder: (context) {
                          final images = (_selectedVariation != null && _selectedVariation!.images.isNotEmpty)
                              ? _selectedVariation!.images
                              : _product!.images;
                          return PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _activeImageIndex = index;
                              });
                            },
                            itemCount: images.length,
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.cover,
                                memCacheWidth: 800,
                              );
                            },
                          );
                        }
                      ),
                    ),
                    
                    // Floating Back Action (White circle)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Theme.of(context).platform == TargetPlatform.iOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: const Color(0xFF121111), size: Theme.of(context).platform == TargetPlatform.iOS ? 18 : 22),
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
                    
                    // Floating Wishlist Action (White circle)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 16,
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            _product!.isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: _product!.isWishlisted ? Colors.red : const Color(0xFF121111),
                            size: 20,
                          ),
                          onPressed: () {
                            productProvider.toggleWishlist(_product!.id);
                            setState(() {
                              _product!.isWishlisted = !_product!.isWishlisted;
                            });
                          },
                        ),
                      ),
                    ),

                    // Dot Indicators
                    Builder(
                      builder: (context) {
                        final images = (_selectedVariation != null && _selectedVariation!.images.isNotEmpty)
                            ? _selectedVariation!.images
                            : _product!.images;
                        if (images.length <= 1) return const SizedBox.shrink();
                        return Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: _activeImageIndex == index ? 22 : 6,
                                decoration: BoxDecoration(
                                  color: _activeImageIndex == index ? AppColors.accent : Colors.white60,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),

                // Info Section
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Occasion / Tag line
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _product!.occasion.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Title & Quantity Selector Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              _product!.name,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF121111),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(19),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove, size: 16, color: Color(0xFF121111)),
                                  onPressed: () {
                                    if (_quantity > 1) {
                                      setState(() {
                                        _quantity--;
                                      });
                                    }
                                  },
                                ),
                                Text(
                                  _quantity.toString(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF121111),
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF121111)),
                                  onPressed: () {
                                    setState(() {
                                      _quantity++;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Ratings Summary Row
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _product!.rating.toString(),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF121111),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${_product!.reviewsCount} reviews)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF787676),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stock status / FOMO indicator
                      Builder(
                        builder: (context) {
                          int currentStock = 10;
                          if (_product!.hasVariations) {
                            if (_selectedVariation != null) {
                              currentStock = _selectedVariation!.stock;
                            } else {
                              currentStock = _product!.totalStockLeft;
                            }
                          } else {
                            currentStock = _product!.stock;
                          }

                          if (currentStock <= 0) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'OUT OF STOCK - Please select another combination',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (currentStock < 6) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF4E342E) : const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDarkMode ? const Color(0xFF8D6E63) : const Color(0xFFFFB74D)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.flash_on, color: Color(0xFFE65100), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'HURRY, ONLY $currentStock LEFT!',
                                      style: GoogleFonts.outfit(
                                        color: isDarkMode ? const Color(0xFFFFCC80) : const Color(0xFFE65100),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Choose Size & Color Row
                      Builder(
                        builder: (context) {
                          final List<String> sizesList = _product!.hasVariations
                              ? _product!.variations
                                  .map((v) => v.size)
                                  .where((s) => s != null && s.isNotEmpty)
                                  .cast<String>()
                                  .toSet()
                                  .toList()
                              : _product!.sizes;
                          
                          final uniqueColors = <Map<String, String>>[];
                          
                          // Check if we have sibling variations from the database
                          if (_product!.siblingVariations.isNotEmpty) {
                            // Add current product color
                            uniqueColors.add({
                              'id': _product!.id,
                              'slug': _product!.slug,
                              'name': _product!.color,
                              'hex': _product!.colorHex ?? '#800020',
                              'isCurrent': 'true',
                            });
                            
                            // Add sibling colors
                            for (final sibling in _product!.siblingVariations) {
                              if (!uniqueColors.any((c) => c['name'] == sibling.color)) {
                                uniqueColors.add({
                                  'id': sibling.id,
                                  'slug': sibling.slug,
                                  'name': sibling.color,
                                  'hex': sibling.colorHex,
                                  'isCurrent': 'false',
                                });
                              }
                            }
                          } else if (_product!.hasVariations) {
                            for (final v in _product!.variations) {
                              if (v.color != null && v.color!.isNotEmpty && v.colorHex != null && v.colorHex!.isNotEmpty) {
                                if (!uniqueColors.any((c) => c['name'] == v.color)) {
                                  uniqueColors.add({
                                    'id': '',
                                    'slug': '',
                                    'name': v.color!,
                                    'hex': v.colorHex!,
                                    'isCurrent': 'false',
                                  });
                                }
                              }
                            }
                          }
                          
                          final showSizes = sizesList.isNotEmpty;
                          final showColors = uniqueColors.isNotEmpty;
                          
                          if (!showSizes && !showColors) return const SizedBox.shrink();

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Choose Size column
                              if (showSizes)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Choose Size',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : const Color(0xFF121111),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: sizesList.map((size) {
                                          final isSelected = _selectedSize == size;
                                          final isOos = _isSizeOutOfStock(size);
                                          return GestureDetector(
                                            onTap: () {
                                              if (_product!.hasVariations) {
                                                _updateSelectedVariation(size, _selectedColor);
                                              } else {
                                                setState(() {
                                                  _selectedSize = size;
                                                });
                                              }
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isSelected 
                                                        ? (isDarkMode ? Colors.white : const Color(0xFF121111)) 
                                                        : Colors.transparent,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected 
                                                          ? Colors.transparent 
                                                          : (isOos 
                                                              ? (isDarkMode ? Colors.white12 : Colors.grey.shade300) 
                                                              : const Color(0xFFA3A1A2)),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    size,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isSelected 
                                                          ? (isDarkMode ? Colors.black : Colors.white) 
                                                          : (isOos 
                                                              ? (isDarkMode ? Colors.white24 : Colors.black26) 
                                                              : (isDarkMode ? Colors.white : const Color(0xFF121111))),
                                                    ),
                                                  ),
                                                ),
                                                if (isOos)
                                                  Positioned(
                                                    width: 32,
                                                    height: 32,
                                                    child: CustomPaint(
                                                      painter: DiagonalLinePainter(
                                                        isDarkMode ? Colors.white24 : Colors.black26,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              if (showSizes && showColors) const SizedBox(width: 24),

                              // Color column
                              if (showColors)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Color',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : const Color(0xFF121111),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: uniqueColors.map((colorData) {
                                        final colorName = colorData['name']!;
                                        final colorHex = colorData['hex']!;
                                        final isCurrent = colorData['isCurrent'] == 'true';
                                        final isSelected = _product!.siblingVariations.isNotEmpty
                                            ? isCurrent
                                            : (_selectedColor == colorName);
                                        final circleColor = _parseHexColor(colorHex);
                                        final isOos = _product!.siblingVariations.isNotEmpty 
                                            ? false 
                                            : _isColorOutOfStock(colorName);
                                        return GestureDetector(
                                          onTap: () {
                                            if (_product!.siblingVariations.isNotEmpty) {
                                              if (!isCurrent) {
                                                // Navigate to sibling product detail smoothly
                                                Navigator.pushReplacement(
                                                  context,
                                                  SmoothPageRoute(
                                                    child: ProductDetailScreen(productId: colorData['slug']!),
                                                    direction: AxisDirection.right,
                                                  ),
                                                );
                                              }
                                            } else {
                                              _updateSelectedVariation(_selectedSize, colorName);
                                            }
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isSelected 
                                                        ? (isDarkMode ? Colors.white : const Color(0xFF121111)) 
                                                        : Colors.transparent,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Tooltip(
                                                  message: colorName,
                                                  child: Opacity(
                                                    opacity: isOos ? 0.35 : 1.0,
                                                    child: Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: circleColor,
                                                        shape: BoxShape.circle,
                                                        border: colorHex.toLowerCase() == '#ffffff' || colorHex.toLowerCase() == '#faf9f6'
                                                            ? Border.all(color: Colors.grey.shade300, width: 0.5)
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (isOos)
                                                Positioned(
                                                  width: 24,
                                                  height: 24,
                                                  child: CustomPaint(
                                                    painter: DiagonalLinePainter(
                                                      isDarkMode ? Colors.white54 : Colors.black45,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                            ],
                          );
                        }
                      ),
                      
                      const Divider(height: 40, color: AppColors.borderLight),

                      // Product Specifications Layout
                      Text(
                        'Product Details & Quality',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildSpecificationGrid(isDarkMode),
                      const SizedBox(height: 18),
                      Text(
                        _product!.description,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: (isDarkMode ? AppColors.textSecondaryDark : AppColors.textPrimaryLight).withValues(alpha: 0.85),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      
                      // Details Bullet items
                      Column(
                        children: _product!.details.map((detail) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 7.0, right: 10.0),
                                  child: Icon(Icons.circle, size: 5, color: AppColors.primary),
                                ),
                                Expanded(
                                  child: Text(
                                    detail,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13, 
                                      height: 1.45,
                                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 40, color: AppColors.borderLight),

                      // Complete The Look recommendations
                      if (_recommendedProducts.isNotEmpty) ...[
                        Text(
                          'Complete The Look',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recommendedProducts.length,
                            itemBuilder: (context, index) {
                              final item = _recommendedProducts[index];
                              return _buildRecommendationCard(context, item, isDarkMode);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 120), // Height spacer for floating footer bar
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Bottom Add to Cart Button (Solid Charcoal Capsule)
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: isOutOfStock ? Colors.grey : const Color(0xFF121111),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_product == null) return;
                      if (isOutOfStock) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This variation is currently out of stock.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      String cartSize = 'Default';
                      final hasSizes = _product!.hasVariations && _product!.variations.any((v) => v.size != null && v.size!.isNotEmpty);
                      final hasColors = _product!.hasVariations && _product!.variations.any((v) => v.color != null && v.color!.isNotEmpty);

                      if (_product!.hasVariations) {
                        if (hasSizes && hasColors) {
                          if (_selectedSize == null || _selectedColor == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select size and color!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          cartSize = "$_selectedSize / $_selectedColor";
                        } else if (hasSizes) {
                          if (_selectedSize == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a size!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          cartSize = _selectedSize!;
                        } else if (hasColors) {
                          if (_selectedColor == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a color!'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          cartSize = _selectedColor!;
                        } else {
                          cartSize = _selectedVariation?.name ?? 'Default';
                        }
                      } else {
                        if (_selectedSize == null && _product!.sizes.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a size first!'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        cartSize = _selectedSize ?? 'M';
                      }

                      final bool isAlreadyInCart = cartProvider.items.any(
                        (item) => item.product.id == _product!.id && item.size == cartSize,
                      );

                      if (isAlreadyInCart) {
                        // Navigate to Cart/Bag Tab (index 3)
                        MainNavigationWrapper.activeTabNotifier.value = 3;
                        if (Navigator.canPop(context)) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        } else {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
                            (route) => false,
                          );
                        }
                      } else {
                        _handleAddToCart(cartProvider);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Builder(
                        builder: (context) {
                          final String cartSize = (_product != null && _product!.hasVariations)
                              ? "$_selectedSize / $_selectedColor"
                              : (_selectedSize ?? 'M');
                          final bool isAlreadyInCart = _product != null && _selectedSize != null && cartProvider.items.any(
                            (item) => item.product.id == _product!.id && item.size == cartSize,
                          );
                          
                          final currentPrice = _selectedVariation != null ? _selectedVariation!.price : _product!.price;
                          final currentOriginalPrice = _selectedVariation != null ? (_selectedVariation!.comparePrice ?? _selectedVariation!.price) : _product!.originalPrice;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isOutOfStock
                                    ? Icons.hourglass_empty
                                    : (isAlreadyInCart ? Icons.shopping_bag : Icons.shopping_bag_outlined),
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isOutOfStock
                                    ? 'Out of Stock'
                                    : (isAlreadyInCart
                                        ? 'Go to Bag'
                                        : 'Add to Cart | ₹${(currentPrice * _quantity).toInt()}'),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (!isOutOfStock && !isAlreadyInCart && currentOriginalPrice > currentPrice) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '₹${(currentOriginalPrice * _quantity).toInt()}',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          );
                        }
                      ),
                    ),
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

  Widget _buildSpecificationGrid(bool isDarkMode) {
    Widget cell(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : AppColors.borderLight.withValues(alpha: 0.6),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9.5, 
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12.5, 
                fontWeight: FontWeight.bold, 
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        cell('Fabric', _product!.fabric),
        cell('Fit Style', _product!.fit),
        cell('Occasion', _product!.occasion),
      ],
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Product item, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: item.slug),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 0.82,
                child: CachedNetworkImage(
                  imageUrl: item.images[0],
                  fit: BoxFit.cover,
                  memCacheWidth: 260,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: GoogleFonts.outfit(
                fontSize: 12, 
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              '₹${item.price.toInt()}',
              style: GoogleFonts.outfit(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: isDarkMode ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showAddedToCartBottomSheet(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return AddedToCartBottomSheet(
          recommendedProducts: _recommendedProducts,
          parentContext: context,
        );
      },
    ).then((result) {
      if (result == 'go_to_bag') {
        // Navigate to Cart/Bag Tab (index 3)
        MainNavigationWrapper.activeTabNotifier.value = 3;
        if (Navigator.canPop(context)) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
            (route) => false,
          );
        }
      }
    });
  }
}

class AddedToCartBottomSheet extends StatelessWidget {
  final List<Product> recommendedProducts;
  final BuildContext parentContext;

  const AddedToCartBottomSheet({
    super.key,
    required this.recommendedProducts,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
            
            // Row 1: Left added info, Right VIEW BAG flat button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Added to bag!',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'FREE 1-2 day delivery on 5k+ pincodes',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: isDarkMode ? Colors.white60 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PressScaleEffect(
                  onTap: () {
                    // Close bottom sheet and return 'go_to_bag'
                    Navigator.pop(context, 'go_to_bag');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'VIEW BAG',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        fontSize: 13,
                        color: isDarkMode ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // YOU MAY ALSO LIKE title
            Center(
              child: Text(
                'YOU MAY ALSO LIKE',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Horizontal recommendations list
            SizedBox(
              height: 220,
              child: recommendedProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'Loading recommendations...',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedProducts.length,
                      itemBuilder: (listContext, index) {
                        final item = recommendedProducts[index];
                        return _RecommendationCard(
                          item: item,
                          isDarkMode: isDarkMode,
                          parentContext: parentContext,
                          sheetContext: context,
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

class _RecommendationCard extends StatelessWidget {
  final Product item;
  final bool isDarkMode;
  final BuildContext parentContext;
  final BuildContext sheetContext;

  const _RecommendationCard({
    required this.item,
    required this.isDarkMode,
    required this.parentContext,
    required this.sheetContext,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.originalPrice > item.price;
    
    return GestureDetector(
      onTap: () {
        // Dismiss bottom sheet
        Navigator.pop(sheetContext);
        // Replace with new product details screen
        Navigator.pushReplacement(
          parentContext,
          SmoothPageRoute(
            child: ProductDetailScreen(productId: item.slug),
            direction: AxisDirection.right,
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
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
                        imageUrl: item.images[0],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(color: const Color(0xFFF6F6F6)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<ProductProvider>(
                      builder: (context, productProvider, child) {
                        final isWishlisted = productProvider.wishlistIds.contains(item.id);
                        return GestureDetector(
                          onTap: () {
                            productProvider.toggleWishlist(item.id);
                          },
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white.withValues(alpha: 0.85),
                            child: Icon(
                              isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                              color: isWishlisted ? Colors.red : Colors.black87,
                              size: 15,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (hasDiscount) ...[
                  Text(
                    '₹${item.originalPrice.toInt()}',
                    style: GoogleFonts.outfit(
                      fontSize: 10.5,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '₹${item.price.toInt()}',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? AppColors.accent : AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  final Color color;
  DiagonalLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
