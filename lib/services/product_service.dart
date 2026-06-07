import 'dart:convert';
import '../features/product/models/product.dart';
import '../features/product/models/category_model.dart';
import '../features/product/models/collection_model.dart';
import 'api_client.dart';

class ProductService {
  static final List<String> _categories = [
    'All',
    'Kurtis',
    'Anarkalis',
    'Sarees',
    'Lehengas',
    'Fusion Wear',
  ];

  Future<List<String>> getCategories() async {
    try {
      final response = await ApiClient.get('/categories');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          final list = data.map((e) => e['name'] as String).toList();
          if (!list.contains('All')) list.insert(0, 'All');
          return list;
        }
      }
    } catch (_) {
      // Fallback to static category list if connection fails
    }
    return _categories;
  }

  Future<List<Product>> getProducts({
    String? category,
    String? query,
    List<String>? sizes,
    List<String>? colors,
    List<String>? patterns,
    List<String>? fits,
    List<String>? materials,
    double? minPrice,
    double? maxPrice,
  }) async {
    List<String> queryParams = [];
    if (category != null && category != 'All') {
      queryParams.add('category=${Uri.encodeComponent(category)}');
    }
    if (query != null && query.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(query)}');
    }
    if (sizes != null && sizes.isNotEmpty) {
      queryParams.add('size=${Uri.encodeComponent(sizes.join(','))}');
    }
    if (colors != null && colors.isNotEmpty) {
      queryParams.add('color=${Uri.encodeComponent(colors.join(','))}');
    }
    if (patterns != null && patterns.isNotEmpty) {
      queryParams.add('pattern=${Uri.encodeComponent(patterns.join(','))}');
    }
    if (fits != null && fits.isNotEmpty) {
      queryParams.add('fit=${Uri.encodeComponent(fits.join(','))}');
    }
    if (materials != null && materials.isNotEmpty) {
      queryParams.add('material=${Uri.encodeComponent(materials.join(','))}');
    }
    if (minPrice != null) {
      queryParams.add('minPrice=$minPrice');
    }
    if (maxPrice != null) {
      queryParams.add('maxPrice=$maxPrice');
    }
    String endpoint = '/products';
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await ApiClient.get(endpoint);
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] == true) {
        final List<dynamic> data = body['data'] ?? [];
        final List<Product> list = [];
        for (var item in data) {
          if (item is Map) {
            list.add(Product.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        return list;
      }
    }
    throw ApiException('Failed to load products');
  }

  Future<Product> getProductBySlug(String slug) async {
    final response = await ApiClient.get('/products/$slug');
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(body['data']);
        if (data.containsKey('product') && data['product'] is Map) {
          final productMap = Map<String, dynamic>.from(data['product']);
          if (data.containsKey('colorVariations')) {
            productMap['colorVariations'] = data['colorVariations'];
          }
          return Product.fromJson(productMap);
        }
        return Product.fromJson(data);
      }
    }
    throw ApiException('Product not found: $slug');
  }

  Future<Product> getProductById(String id) async {
    final response = await ApiClient.get('/products/$id');
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] == true && body['data'] is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(body['data']);
        if (data.containsKey('product') && data['product'] is Map) {
          final productMap = Map<String, dynamic>.from(data['product']);
          if (data.containsKey('colorVariations')) {
            productMap['colorVariations'] = data['colorVariations'];
          }
          return Product.fromJson(productMap);
        }
        return Product.fromJson(data);
      }
    }
    throw ApiException('Product not found: $id');
  }

  Future<List<Product>> getRecommendations(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => getProductById(id));
    final results = await Future.wait(futures);
    return results.toList();
  }

  Future<List<CategoryModel>> getCategoryObjects() async {
    try {
      final response = await ApiClient.get('/categories');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          return data.map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<CollectionModel>> getCollectionObjects() async {
    try {
      final response = await ApiClient.get('/collections');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          return data.map((e) => CollectionModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
