class ProductVariation {
  final String sku;
  final String name;
  final double price;
  final double? comparePrice;
  int stock;
  final List<String> images;
  final String? color;
  final String? colorHex;
  final String? size;

  ProductVariation({
    required this.sku,
    required this.name,
    required this.price,
    this.comparePrice,
    required this.stock,
    required this.images,
    this.color,
    this.colorHex,
    this.size,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      sku: json['sku'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      comparePrice: (json['comparePrice'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      color: json['color'],
      colorHex: json['colorHex'],
      size: json['size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'name': name,
      'price': price,
      'comparePrice': comparePrice,
      'stock': stock,
      'images': images,
      'color': color,
      'colorHex': colorHex,
      'size': size,
    };
  }
}

class SiblingVariation {
  final String id;
  final String name;
  final String slug;
  final String color;
  final String colorHex;
  final double price;
  final double? originalPrice;
  final String imageUrl;

  SiblingVariation({
    required this.id,
    required this.name,
    required this.slug,
    required this.color,
    required this.colorHex,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
  });

  factory SiblingVariation.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    final imageUrl = images != null && images.isNotEmpty
        ? images.first.toString()
        : 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=500';
    return SiblingVariation(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      color: json['color'] ?? '',
      colorHex: json['colorHex'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['comparePrice'] as num?)?.toDouble() ?? (json['originalPrice'] as num?)?.toDouble(),
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'color': color,
      'colorHex': colorHex,
      'price': price,
      'originalPrice': originalPrice,
      'images': [imageUrl],
    };
  }
}

class Product {
  final String id;
  final String slug;
  final String name;
  final String description;
  final double price;
  final double originalPrice;
  final List<String> images;
  final List<String> sizes;
  final String category;
  final double rating;
  final int reviewsCount;
  final String fabric;
  final String occasion;
  final String fit;
  final String color;
  final String? colorHex;
  final String? styleCode;
  final String pattern;
  final List<String> details;
  final List<String> completeTheLookIds;
  final List<String> collections;
  final bool hasVariations;
  final List<ProductVariation> variations;
  final List<SiblingVariation> siblingVariations;
  bool isWishlisted;
  final DateTime? createdAt;
  int stock;

  Product({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.images,
    required this.sizes,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.fabric,
    required this.occasion,
    required this.fit,
    this.color = 'Multi',
    this.colorHex,
    this.styleCode,
    this.pattern = 'Solid',
    required this.details,
    required this.completeTheLookIds,
    this.collections = const [],
    this.hasVariations = false,
    this.variations = const [],
    this.siblingVariations = const [],
    this.isWishlisted = false,
    this.createdAt,
    this.stock = 0,
  });

  int get discountPercentage {
    if (originalPrice <= 0 || price >= originalPrice) return 0;
    return (((originalPrice - price) / originalPrice) * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse nested ratings object if available
    final ratingsObj = json['ratings'] as Map<String, dynamic>?;
    final avgRating = (ratingsObj?['average'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble() ?? 4.5;
    final rCount = (ratingsObj?['count'] as num?)?.toInt() ?? json['reviewsCount'] ?? 120;

    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      slug: json['slug'] ?? '',
      name: json['name'] ?? '',
      description: json['shortDescription'] ?? json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['comparePrice'] as num?)?.toDouble() ?? (json['originalPrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      images: json['images'] != null && (json['images'] as List).isNotEmpty 
          ? List<String>.from(json['images']) 
          : ['https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=500'],
      sizes: json['sizes'] != null && (json['sizes'] as List).isNotEmpty 
          ? List<String>.from(json['sizes']) 
          : ['S', 'M', 'L', 'XL'], // Default sizes for clothing
      category: json['category'] ?? '',
      rating: avgRating,
      reviewsCount: rCount,
      fabric: json['fabric'] ?? 'Premium Silk Blend',
      occasion: json['occasion'] ?? 'Festive / Formal',
      fit: json['fit'] ?? 'Regular Fit',
      color: json['color'] ?? 'Multi',
      colorHex: json['colorHex'],
      styleCode: json['styleCode'],
      pattern: json['pattern'] ?? 'Solid',
      details: List<String>.from(json['details'] ?? [
        'Premium quality fabric and stitching',
        'Dry clean only for gold details',
      ]),
      completeTheLookIds: List<String>.from(json['completeTheLookIds'] ?? []),
      collections: List<String>.from((json['collections'] ?? []).map((e) => e is Map ? (e['_id'] ?? '').toString() : e.toString())),
      hasVariations: json['hasVariations'] ?? false,
      variations: json['variations'] != null
          ? (json['variations'] as List).map((v) => ProductVariation.fromJson(Map<String, dynamic>.from(v))).toList()
          : [],
      siblingVariations: json['colorVariations'] != null
          ? (json['colorVariations'] as List).map((v) => SiblingVariation.fromJson(Map<String, dynamic>.from(v))).toList()
          : [],
      isWishlisted: json['isWishlisted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'images': images,
      'sizes': sizes,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'fabric': fabric,
      'occasion': occasion,
      'fit': fit,
      'color': color,
      'colorHex': colorHex,
      'styleCode': styleCode,
      'pattern': pattern,
      'details': details,
      'completeTheLookIds': completeTheLookIds,
      'collections': collections,
      'hasVariations': hasVariations,
      'variations': variations.map((v) => v.toJson()).toList(),
      'colorVariations': siblingVariations.map((v) => v.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'stock': stock,
    };
  }

  bool get isOos => hasVariations ? (variations.isEmpty || variations.every((v) => v.stock <= 0)) : stock <= 0;
  int get totalStockLeft => hasVariations ? variations.fold<int>(0, (sum, v) => sum + v.stock) : stock;
}
