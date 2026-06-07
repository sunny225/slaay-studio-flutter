class CmsLayoutComponent {
  final String type; // 'hero_slider', 'search_bar', 'category_list', 'promo_banner', 'product_grid'
  final String? title;
  final List<CmsItem> items;
  final Map<String, dynamic> attributes;

  CmsLayoutComponent({
    required this.type,
    this.title,
    required this.items,
    this.attributes = const {},
  });

  factory CmsLayoutComponent.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    final cmsItems = list.map((i) {
      if (i is Map) {
        return CmsItem.fromJson(Map<String, dynamic>.from(i));
      }
      return CmsItem();
    }).toList();

    Map<String, dynamic> attrs = {};
    if (json['attributes'] is Map) {
      attrs = Map<String, dynamic>.from(json['attributes']);
    }

    return CmsLayoutComponent(
      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String?,
      items: cmsItems,
      attributes: attrs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'items': items.map((i) => i.toJson()).toList(),
      'attributes': attributes,
    };
  }
}

class CmsItem {
  final String? type;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? ctaText;
  final String? actionLink; // e.g. 'category/Kurtis', 'product/slug-id'
  final Map<String, dynamic> attributes;

  CmsItem({
    this.type,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.ctaText,
    this.actionLink,
    this.attributes = const {},
  });

  factory CmsItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> attrs = {};
    if (json['attributes'] is Map) {
      attrs = Map<String, dynamic>.from(json['attributes']);
    }
    return CmsItem(
      type: json['type'] as String?,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ctaText: json['ctaText'] as String?,
      actionLink: json['actionLink'] as String?,
      attributes: attrs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'ctaText': ctaText,
      'actionLink': actionLink,
      'attributes': attributes,
    };
  }
}
