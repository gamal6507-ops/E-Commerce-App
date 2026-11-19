enum ProductSize {
  none,
  S,
  M,
  L,
  // ignore: constant_identifier_names
  XL;

  static ProductSize fromString(String size) {
    switch (size.toUpperCase()) {
      case 'S':
        return ProductSize.S;
      case 'M':
        return ProductSize.M;
      case 'L':
        return ProductSize.L;
      case 'XL':
        return ProductSize.XL;
      default:
        return ProductSize.none;
    }
  }
}

class Product {
  final String id;
  final String name;
  final String imgUrl;
  final String description;
  final double price;
  final bool requiresSize;
  final int stock;
  final bool isFavorite;
  final String category;
  final double averageRate;

  const Product({
    required this.id,
    required this.name,
    required this.imgUrl,
    this.description =
        'Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum is simply dummy text of the printing and typesetting industry Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
    required this.price,
    this.requiresSize = false,
    this.stock = 0,
    this.isFavorite = false,
    required this.category,
    this.averageRate = 4.5,
  });

  Product copyWith({
    String? id,
    String? name,
    String? imgUrl,
    String? description,
    double? price,
    bool? isFavorite,
    String? category,
    double? averageRate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      imgUrl: imgUrl ?? this.imgUrl,
      description: description ?? this.description,
      price: price ?? this.price,
      requiresSize: requiresSize,
      stock: stock,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      averageRate: averageRate ?? this.averageRate,
    );
  }
}
