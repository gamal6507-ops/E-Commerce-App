import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_app/Presentation/controller/cart_cubit/cart_cubit.dart';
import 'package:e_commerce_app/Presentation/controller/porfile_cubit/cubit/profile_cubit.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/data/models/user_data.dart';
import 'package:e_commerce_app/data/datasources/product_local_cache.dart';
import 'package:e_commerce_app/domain/entities/app_user.dart';
import 'package:e_commerce_app/domain/entities/cart_item.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:e_commerce_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_app/domain/repositories/cart_repository.dart';
import 'package:e_commerce_app/domain/repositories/profile_repository.dart';
import 'package:material_ui/material_ui.dart';

class _FakeAuth extends Fake implements AuthRepository {
  @override
  String? get currentUserId => 'u1';
}

class _FailingProfileRepo extends Fake implements ProfileRepository {
  @override
  Future<AppUser> getUserData(String userId) async => const AppUser(
    id: 'u1',
    username: 'User',
    email: 'u@example.com',
    createdAt: '2026-11-19T00:00:00Z',
  );

  @override
  Future<void> changeUserName(String userId, String newName) async {
    throw Exception('Update failed');
  }
}

class _StockCartRepo extends Fake implements CartRepository {
  CartItem item = const CartItem(
    id: 'c1',
    product: Product(
      id: 'p1',
      name: 'Item',
      imgUrl: '',
      price: 20,
      category: 'General',
      stock: 2,
    ),
    size: ProductSize.none,
    quantity: 2,
  );

  @override
  Future<List<CartItem>> fetchCartItems(String userId) async => [item];

  @override
  Future<void> setCartItem(String userId, CartItem cartItem) async {
    item = cartItem;
  }
}

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
  test(
    'profile update failure restores loaded user instead of spinning',
    () async {
      final cubit = ProfileCubit(
        profileRepository: _FailingProfileRepo(),
        authRepository: _FakeAuth(),
      );
      await cubit.getUserData();
      expect(cubit.state, isA<ProfileLoaded>());
      await cubit.updateUserName(name: 'New');
      expect(cubit.state, isA<ProfileLoaded>());
      await cubit.close();
    },
  );
  test('cart increment respects available product stock', () async {
    final repo = _StockCartRepo();
    final cubit = CartCubit(cartRepository: repo, authRepository: _FakeAuth());
    await cubit.getCartItems();
    await cubit.incrementCounter(repo.item);
    expect(repo.item.quantity, 2);
    await cubit.close();
  });
  test('order placed copy reflects pending review status', () {
    final en = AppLocalizations(const Locale('en'));
    final ar = AppLocalizations(const Locale('ar'));
    expect(en.translate('order_placed_sub'), contains('awaiting confirmation'));
    expect(ar.translate('order_placed_sub'), contains('قيد المراجعة'));
  });
}
