class CollectionModel {
  final String id;
  final String name;
  final String slug;
  final String image;
  final String description;

  CollectionModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
    this.description = '',
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'description': description,
    };
  }
}
