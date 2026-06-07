import '../../product/models/product.dart';

class CartItem {
  final Product product;
  final String size;
  int quantity;

  CartItem({
    required this.product,
    required this.size,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  bool get isOutOfStock {
    if (product.hasVariations) {
      try {
        final term = size.toLowerCase().trim();
        final matchedVar = product.variations.firstWhere((v) {
          final vSku = (v.sku).toLowerCase().trim();
          final vName = (v.name).toLowerCase().trim();
          return vSku == term ||
              vName == term ||
              term.replaceAll('size_', '') == vName ||
              term.replaceAll('size_', '') == vSku;
        });
        return matchedVar.stock <= 0;
      } catch (_) {
        return true;
      }
    }
    return false;
  }

  int get stockLeft {
    if (product.hasVariations) {
      try {
        final term = size.toLowerCase().trim();
        final matchedVar = product.variations.firstWhere((v) {
          final vSku = (v.sku).toLowerCase().trim();
          final vName = (v.name).toLowerCase().trim();
          return vSku == term ||
              vName == term ||
              term.replaceAll('size_', '') == vName ||
              term.replaceAll('size_', '') == vSku;
        });
        return matchedVar.stock;
      } catch (_) {
        return 0;
      }
    }
    return 10; // Default high stock for standard items
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    String parsedSize = json['size'] ?? json['variant'] ?? 'M';
    if (json['selectedVariation'] != null && json['selectedVariation'] is Map) {
      parsedSize = json['selectedVariation']['name'] ?? parsedSize;
    }
    
    final productJson = json['product'] != null && json['product'] is Map
        ? Map<String, dynamic>.from(json['product'])
        : <String, dynamic>{};
        
    if (json['image'] != null && json['image'].toString().isNotEmpty) {
      if (productJson['images'] == null || (productJson['images'] as List).isEmpty) {
        productJson['images'] = [json['image']];
      }
    }
    
    if (json['price'] != null) {
      productJson['price'] = json['price'];
    }
    
    return CartItem(
      product: Product.fromJson(productJson),
      size: parsedSize,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'size': size,
      'quantity': quantity,
    };
  }
}
