class Product {
  final int id;
  final String name;
  final String description;
  final String shortDescription;
  final double price;
  final double regularPrice;
  final double? salePrice;
  final bool onSale;
  final String slug;
  final List<String> images;
  final List<String> categories;
  final double rating;
  final String weight;
  final Map<String, String> dimensions;
  final int points;
  final List<dynamic> metaData;
  final List<Map<String, dynamic>> attributes;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,

    required this.shortDescription,
    required this.price,
    required this.regularPrice,
    this.salePrice,
    required this.onSale,
    required this.images,
    required this.categories,
    required this.rating,
    required this.weight,
    required this.dimensions,
    required this.points,
    required this.metaData,
    required this.attributes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int points = 0;
    
    // Direct fetch from the new custom API field we added to WordPress
    if (json['wployalty_points'] != null) {
      points = int.tryParse(json['wployalty_points'].toString()) ?? 0;
    }

    // Fallback: Check metadata if the custom field isn't available yet
    if (points == 0 && json['meta_data'] != null) {
      for (var meta in json['meta_data']) {
        final key = meta['key'].toString().toLowerCase();
        final val = meta['value'];
        if (key.contains('points') && (key.contains('earn') || key.contains('loyalty'))) {
          if (val != null) {
            points = int.tryParse(val.toString()) ?? 0;
          }
        }
      }
    }

    final product = Product(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      shortDescription: json['short_description'] ?? '',
      price: double.tryParse(json['price'] ?? '0') ?? 0.0,
      regularPrice: double.tryParse(json['regular_price'] ?? '0') ?? 0.0,
      salePrice: double.tryParse(json['sale_price'] ?? ''),
      onSale: json['on_sale'] ?? false,
      images: (json['images'] as List?)
              ?.map((i) => i['src'] as String)
              .toList() ??
          [],
      categories: (json['categories'] as List?)
              ?.map((c) => c['name'] as String)
              .toList() ??
          [],
      rating: double.tryParse(json['average_rating'] ?? '0') ?? 0.0,
      weight: json['weight'] ?? '',
      dimensions: {
        'length': json['dimensions']?['length'] ?? '',
        'width': json['dimensions']?['width'] ?? '',
        'height': json['dimensions']?['height'] ?? '',
      },
      points: points,
      metaData: json['meta_data'] ?? [],
      attributes: (json['attributes'] as List?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ??
          [],
    );
    return product;
  }
}
