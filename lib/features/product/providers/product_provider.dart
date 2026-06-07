import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_client.dart';
import '../../../../services/product_service.dart';
import '../models/product.dart';
import '../models/category_model.dart';
import '../models/collection_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<Product> _products = [];
  List<String> _categories = [];
  List<CategoryModel> _categoryObjects = [];
  List<CollectionModel> _collectionObjects = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isApiPreloaded = false;
  List<String> _wishlistIds = [];
  Timer? _refreshTimer;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  List<CategoryModel> get categoryObjects => _categoryObjects;
  List<CollectionModel> get collectionObjects => _collectionObjects;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isPreloaded => _isApiPreloaded || (_products.isNotEmpty && _categories.isNotEmpty);
  List<String> get wishlistIds => _wishlistIds;

  static const String _wishlistKey = 'user_wishlist_ids';

  ProductProvider() {
    _initCacheAndFetch();
  }

  Future<void> _initCacheAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCategories = prefs.getStringList('cached_categories');
      final cachedCatObjsStr = prefs.getString('cached_category_objects');
      final cachedCollObjsStr = prefs.getString('cached_collection_objects');
      final cachedProdsStr = prefs.getString('cached_products');

      if (cachedCategories != null) {
        _categories = cachedCategories;
      }
      if (cachedCatObjsStr != null) {
        final List<dynamic> list = jsonDecode(cachedCatObjsStr);
        _categoryObjects = list.map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (cachedCollObjsStr != null) {
        final List<dynamic> list = jsonDecode(cachedCollObjsStr);
        _collectionObjects = list.map((e) => CollectionModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      if (cachedProdsStr != null) {
        final List<dynamic> list = jsonDecode(cachedProdsStr);
        _products = list.map((e) => Product.fromJson(Map<String, dynamic>.from(e))).toList();
      }

      if (_categories.isNotEmpty || _products.isNotEmpty) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cached products catalog: $e');
    }

    _isInitialized = true;
    notifyListeners();

    // Fetch fresh data concurrently in the background and wait for it
    try {
      await Future.wait([
        syncAndLoadWishlist(),
        fetchCategories(),
        fetchProducts(),
      ]);
    } catch (_) {
    } finally {
      _isApiPreloaded = true;
      notifyListeners();
    }

    // Start periodic background updates (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _refreshBackgroundData();
    });
  }

  Future<void> syncAndLoadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isMockToken = token == null || token.startsWith('mock_');

    if (!isMockToken) {
      try {
        // Sync local guest wishlist items to server first if any
        final localWishlist = prefs.getStringList(_wishlistKey) ?? [];
        if (localWishlist.isNotEmpty) {
          for (final id in localWishlist) {
            await ApiClient.post('/wishlist/add', {'productId': id});
          }
          // Clear local guest cache list so we don't spam next time
          await prefs.setStringList(_wishlistKey, []);
        }

        // Fetch user's active wishlist from backend
        final response = await ApiClient.get('/wishlist');
        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] != null) {
            final List<dynamic> serverWishlist = body['data']['wishlist'] ?? [];
            _wishlistIds = serverWishlist.map((item) {
              if (item is Map) {
                return item['_id'].toString();
              }
              return item.toString();
            }).toList();

            // Sync states on loaded products
            for (var p in _products) {
              p.isWishlisted = _wishlistIds.contains(p.id);
            }
            
            await prefs.setStringList(_wishlistKey, _wishlistIds);
            notifyListeners();
            return;
          }
        }
      } catch (_) {
        // Silent fallback
      }
    }

    _wishlistIds = prefs.getStringList(_wishlistKey) ?? [];
    for (var p in _products) {
      p.isWishlisted = _wishlistIds.contains(p.id);
    }
    notifyListeners();
  }

  Future<void> toggleWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isMockToken = token == null || token.startsWith('mock_');

    final exists = _wishlistIds.contains(productId);
    if (exists) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    
    // Sync change in current products list
    for (var p in _products) {
      if (p.id == productId) {
        p.isWishlisted = _wishlistIds.contains(productId);
      }
    }

    await prefs.setStringList(_wishlistKey, _wishlistIds);
    notifyListeners();

    // Sync with server if logged in
    if (!isMockToken) {
      try {
        if (exists) {
          await ApiClient.delete('/wishlist/remove/$productId');
        } else {
          await ApiClient.post('/wishlist/add', {'productId': productId});
        }
      } catch (_) {
        // Silent fallback
      }
    }
  }

  Future<void> fetchCategories() async {
    try {
      final freshCategories = await _productService.getCategories();
      final freshCatObjs = await _productService.getCategoryObjects();
      final freshCollObjs = await _productService.getCollectionObjects();

      _categories = freshCategories;
      _categoryObjects = freshCatObjs;
      _collectionObjects = freshCollObjs;
      notifyListeners();

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_categories', _categories);
      await prefs.setString('cached_category_objects', jsonEncode(_categoryObjects.map((e) => e.toJson()).toList()));
      await prefs.setString('cached_collection_objects', jsonEncode(_collectionObjects.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> fetchProducts() async {
    final hasCache = _products.isNotEmpty;
    if (!hasCache) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final freshProducts = await _productService.getProducts(
        category: _selectedCategory,
        query: _searchQuery,
      );
      
      _products = freshProducts;
      // Update wishlist states on fetched products
      for (var p in _products) {
        p.isWishlisted = _wishlistIds.contains(p.id);
      }

      // Cache the default list of products (All category, empty search query)
      if (_selectedCategory == 'All' && _searchQuery.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_products', jsonEncode(_products.map((e) => e.toJson()).toList()));
      }
    } catch (_) {} finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    fetchProducts();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    fetchProducts();
  }

  void updateProductStock(String productId, int newStock, List<dynamic>? newVariations) {
    bool updated = false;
    for (var i = 0; i < _products.length; i++) {
      if (_products[i].id == productId) {
        _products[i].stock = newStock;
        if (newVariations != null && _products[i].hasVariations) {
          for (var vJson in newVariations) {
            final sku = vJson['sku']?.toString();
            final vStock = (vJson['stock'] as num?)?.toInt();
            if (sku != null && vStock != null) {
              final varIdx = _products[i].variations.indexWhere((v) => v.sku == sku);
              if (varIdx > -1) {
                _products[i].variations[varIdx].stock = vStock;
              }
            }
          }
        }
        updated = true;
      }
    }
    
    if (updated) {
      debugPrint('[SSE] Locally updated stock for product $productId to $newStock');
      notifyListeners();
      
      // Update cache
      if (_selectedCategory == 'All' && _searchQuery.isEmpty) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('cached_products', jsonEncode(_products.map((e) => e.toJson()).toList()));
        });
      }
    }
  }

  Future<void> _refreshBackgroundData() async {
    await syncAndLoadWishlist();
    await fetchCategories();
    if (_selectedCategory == 'All' && _searchQuery.isEmpty) {
      await fetchProducts();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
