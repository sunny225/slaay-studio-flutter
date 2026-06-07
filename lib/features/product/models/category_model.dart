class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String image;
  final String description;
  final String? parentId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    this.description = '',
    this.parentId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      parentId: json['parentId'] is Map ? json['parentId']['_id'] : json['parentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'description': description,
      'parentId': parentId,
    };
  }
}
