import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_app/data/models/user_data.dart';
import 'package:e_commerce_app/data/datasources/product_local_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('profile serialization never persists a password', () {
    const user = UserData(
      id: 'u',
      username: 'User',
      email: 'u@example.com',
      createdAt: '2026-11-19T00:00:00Z',
    );
    expect(user.toMap().containsKey('password'), isFalse);
  });
  test('expired catalog cannot be used as fresh data', () async {
    SharedPreferences.setMockInitialValues({
      'cached_catalog_products_v1': jsonEncode([
        {
          'id': 'p',
          'name': 'Product',
          'price': 10,
          'category': 'General',
          'imgUrl': '',
        },
      ]),
      'cached_catalog_timestamp_v1':
          DateTime.now()
              .subtract(const Duration(days: 2))
              .millisecondsSinceEpoch,
    });
    expect(
      await ProductLocalCache.instance.getCachedProducts(
        ignoreExpiration: false,
      ),
      isNull,
    );
    expect(
      await ProductLocalCache.instance.getCachedProducts(
        ignoreExpiration: true,
      ),
      isNotEmpty,
    );
  });
}
