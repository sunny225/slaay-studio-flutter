import 'dart:convert';
import '../features/home/models/cms_layout_component.dart';
import 'api_client.dart';

class CmsService {
  // Pre-configured dynamic JSON representation of SLAAY Home screen components
  static const String _fallbackLayoutJson = '''
  {
    "success": true,
    "data": [
      {
        "type": "search_bar",
        "title": "Search Bar Config",
        "items": [
          {
            "title": "Search Luxury Kurtas, Sarees, Dupattas..."
          }
        ]
      },
      {
        "type": "hero_slider",
        "items": [
          {
            "title": "The Premium\\nChanderi Story",
            "subtitle": "Flat 50% Off | Handcrafted Luxury Collection",
            "imageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=800&auto=format&fit=crop",
            "ctaText": "EXPLORE EDIT",
            "actionLink": "category/Anarkalis",
            "attributes": {
              "tag": "FESTIVE EDIT"
            }
          },
          {
            "title": "Heritage Silk\\nCollection",
            "subtitle": "Silk Mark Certified | Royal Festive Drapes",
            "imageUrl": "https://images.unsplash.com/photo-1610030469983-98e550d6193c?q=80&w=800&auto=format&fit=crop",
            "ctaText": "VIEW HERITAGE",
            "actionLink": "category/Sarees",
            "attributes": {
              "tag": "ROYAL SILKS"
            }
          },
          {
            "title": "Modern Indowestern\\nFusion Wear",
            "subtitle": "Geometric Silhouettes | Breathe Easy Linens",
            "imageUrl": "https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?q=80&w=800&auto=format&fit=crop",
            "ctaText": "SHOP FUSION",
            "actionLink": "category/Fusion Wear",
            "attributes": {
              "tag": "CONTEMPORARY"
            }
          }
        ]
      },
      {
        "type": "category_list",
        "title": "Discover Categories",
        "items": []
      },
      {
        "type": "promo_banner",
        "title": "CMS Curated Spotlight",
        "items": [
          {
            "title": "Banarasi Bridal Masterpieces",
            "subtitle": "Up to 40% Off | Heirloom Weaves",
            "imageUrl": "https://images.unsplash.com/photo-1621184455862-c163dfb30e0f?q=80&w=800&auto=format&fit=crop",
            "ctaText": "VIEW EXCLUSIVE",
            "actionLink": "product/royal-crimson-banarasi-saree"
          }
        ]
      },
      {
        "type": "product_grid",
        "title": "Trending Edits",
        "items": []
      }
    ]
  }
  ''';

  Future<List<CmsLayoutComponent>> getHomeLayout() async {
    try {
      final response = await ApiClient.get('/cms/home-layout?platform=mobile');
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          return data.map((item) {
            if (item is Map) {
              return CmsLayoutComponent.fromJson(Map<String, dynamic>.from(item));
            }
            return CmsLayoutComponent(type: 'unknown', items: []);
          }).toList();
        }
      }
    } catch (_) {
      // Fallback on connection error or missing endpoint (API Sandbox)
    }

    // Default structure parsed from mock layout schema
    final Map<String, dynamic> body = jsonDecode(_fallbackLayoutJson);
    final List<dynamic> data = body['data'] ?? [];
    return data.map((item) => CmsLayoutComponent.fromJson(item as Map<String, dynamic>)).toList();
  }
}
