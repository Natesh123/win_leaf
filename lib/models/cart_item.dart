class CartItem {
  final int id;
  final String name;
  final String subtitle;
  final String imagePath;
  final double price;
  final String slug;
  int quantity;
  String? cartKey;

  final Map<String, dynamic>? extraData;

  CartItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imagePath,
    required this.price,
    this.slug = '',
    this.quantity = 1,
    this.cartKey,
    this.extraData,
  });
  CartItem copyWith({
    String? cartKey,
    int? quantity,
    double? price,
  }) {
    return CartItem(
      id: id,
      name: name,
      subtitle: subtitle,
      imagePath: imagePath,
      price: price ?? this.price,
      slug: slug,
      quantity: quantity ?? this.quantity,
      cartKey: cartKey ?? this.cartKey,
      extraData: extraData,
    );
  }
}
