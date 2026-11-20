import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/data/models/product_item_model.dart';
import 'package:e_commerce_app/domain/entities/product.dart';

class CatalogSearch {
  Future<List<Product>> search(String query) async {
    final prefix = query.trim().toLowerCase();
    if (prefix.isEmpty) {
      return [];
    }
    final results =
        await FirebaseFirestore.instance
            .collection('products')
            .where('active', isEqualTo: true)
            .orderBy('nameLower')
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .limit(50)
            .get();
    final trimmed = query.trim();
    final categoryExact =
        await FirebaseFirestore.instance
            .collection('products')
            .where('active', isEqualTo: true)
            .where('category', isEqualTo: trimmed)
            .limit(50)
            .get();
    final categoryLower =
        trimmed == prefix
            ? null
            : await FirebaseFirestore.instance
                .collection('products')
                .where('active', isEqualTo: true)
                .where('category', isEqualTo: prefix)
                .limit(50)
                .get();
    final products = <String, Product>{};
    for (final doc in [
      ...results.docs,
      ...categoryExact.docs,
      if (categoryLower != null) ...categoryLower.docs,
    ]) {
      products[doc.id] = ProductItemModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }
    return products.values.toList();
  }
}
