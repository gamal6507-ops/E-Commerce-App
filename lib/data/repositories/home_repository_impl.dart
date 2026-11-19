import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/data/datasources/firestore_services.dart';
import 'package:e_commerce_app/data/datasources/product_local_cache.dart';
import 'package:e_commerce_app/data/datasources/external_catalog_service.dart';
import 'package:e_commerce_app/data/models/product_item_model.dart';
import 'package:e_commerce_app/domain/entities/carousel_item.dart';
import 'package:e_commerce_app/domain/entities/category.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:e_commerce_app/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  List<ProductItemModel> _products = [];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  @override
  bool get hasMore => _hasMore;
  @override
  Future<List<Product>> fetchProducts({bool loadMore = false}) async {
    try {
      if (loadMore && !_hasMore) {
        return _products;
      }
      if (!loadMore) {
        _cursor = null;
        _products = [];
      }
      Query<Map<String, dynamic>> query = FirestoreServices.instance.firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .orderBy(FieldPath.documentId)
          .limit(40);
      if (loadMore && _cursor != null) {
        query = query.startAfterDocument(_cursor!);
      }
      final page = await query.get();
      _hasMore = page.docs.length == 40;
      if (page.docs.isNotEmpty) {
        _cursor = page.docs.last;
      }
      final products = [
        ..._products,
        ...page.docs.map(
          (doc) => ProductItemModel.fromMap({...doc.data(), 'id': doc.id}),
        ),
      ];
      await ProductLocalCache.instance.clearAll();
      await ProductLocalCache.instance.cacheProducts(products);
      _products = products;
      return products;
    } catch (_) {
      final cached = await ProductLocalCache.instance.getCachedProducts(
        ignoreExpiration: false,
      );
      if (cached != null) {
        _hasMore = false;
        _products = cached;
        return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<Category>> fetchCategories() async =>
      ExternalCatalogService.instance.buildCategoriesFromProducts(_products);
  @override
  Future<List<CarouselItem>> fetchCarouselItems() async =>
      ExternalCatalogService.instance.buildCarouselFromProducts(_products);
}
