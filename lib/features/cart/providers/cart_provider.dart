import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../../product/models/product.dart';
import '../../../services/api_client.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  static const String _cartKey = 'user_shopping_cart';

  String? _appliedCouponCode;
  double _couponDiscount = 0.0;
  Timer? _syncTimer;

  List<CartItem> get items => _items;
  String? get appliedCouponCode => _appliedCouponCode;
  double get couponDiscount => _couponDiscount;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.05; // 5% GST standard for clothing in India
  double get shippingFee => _items.isEmpty ? 0.0 : (subtotal > 1500 ? 0.0 : 99.0); // Free shipping above ₹1500
  double get totalAmount => (subtotal + tax + shippingFee - _couponDiscount).clamp(0.0, double.infinity);
  int get totalItemsCount => _items.fold(0, (count, item) => count + item.quantity);

  Future<Map<String, dynamic>> validateAndApplyCoupon(String code, {String? paymentMethod}) async {
    if (code.trim().isEmpty) {
      return {'success': false, 'message': 'Please enter a coupon code'};
    }
    
    try {
      final response = await ApiClient.post('/coupons/validate', {
        'code': code.trim().toUpperCase(),
        'orderAmount': subtotal,
        'paymentMethod': ?paymentMethod,
      });

      final Map<String, dynamic> body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true && body['data'] != null) {
        final data = body['data'];
        final double discount = (data['discountAmount'] ?? data['discount'] ?? 0.0).toDouble();
        
        _appliedCouponCode = code.trim().toUpperCase();
        _couponDiscount = discount;
        notifyListeners();
        return {
          'success': true,
          'message': body['message'] ?? 'Coupon applied successfully!',
          'discount': discount,
        };
      } else {
        final String errorMsg = body['message'] ?? 'Invalid coupon code';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void removeCoupon() {
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    notifyListeners();
  }

  CartProvider() {
    _loadCart();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadCart();
    });
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    // If authenticated and not using a mock token, load from backend
    if (token != null && !token.startsWith('mock_')) {
      try {
        final response = await ApiClient.get('/cart');
        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] != null) {
            final List<dynamic> serverItems = body['data']['items'] ?? [];
            _items = serverItems.map((item) {
              if (item is Map) {
                return CartItem.fromJson(Map<String, dynamic>.from(item));
              }
              return CartItem(product: Product.fromJson({}), size: 'M');
            }).toList();
            notifyListeners();
            // Save to local storage for offline retrieval
            final List<Map<String, dynamic>> jsonList = _items.map((item) => item.toJson()).toList();
            await prefs.setString(_cartKey, jsonEncode(jsonList));
            return;
          }
        }
      } catch (_) {
        // Fallback to local storage on error
      }
    }

    final String? cartStr = prefs.getString(_cartKey);
    if (cartStr != null) {
      final List<dynamic> decoded = jsonDecode(cartStr);
      _items = decoded.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _items.map((item) => item.toJson()).toList();
    await prefs.setString(_cartKey, jsonEncode(jsonList));
    
    // Asynchronously push updates to backend
    syncCartToServer();
  }

  Future<void> syncCartToServer() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.startsWith('mock_')) {
      return; // Guest user or offline sandbox
    }

    try {
      final List<Map<String, dynamic>> syncItems = _items.map((item) {
        return {
          'product': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        };
      }).toList();

      await ApiClient.post('/cart/sync', {
        'items': syncItems,
      });
    } catch (_) {
      // Graceful error handling (silent offline persistence)
    }
  }

  Future<void> syncAndLoadCart() async {
    await syncCartToServer();
    await _loadCart();
  }

  Future<void> addToCart(Product product, String size, {int quantity = 1}) async {
    // Check if the item with same product and size already exists
    final index = _items.indexWhere(
      (item) => item.product.id == product.id && item.size == size,
    );

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, size: size, quantity: quantity));
    }
    
    await _saveCart();
    notifyListeners();
  }

  Future<void> removeFromCart(String productId, String size) async {
    _items.removeWhere((item) => item.product.id == productId && item.size == size);
    await _saveCart();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, String size, int quantity) async {
    final index = _items.indexWhere(
      (item) => item.product.id == productId && item.size == size,
    );
    
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      await _saveCart();
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    _appliedCouponCode = null;
    _couponDiscount = 0.0;
    await _saveCart();
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
