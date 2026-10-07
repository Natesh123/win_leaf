class category {
  final int id;
  final String name;
  final String slug;

  category({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory category.fromJson(Map<String, dynamic> json) {
    return category(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}
