import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_app/Presentation/controller/checkout_cubit/checkout_cubit.dart';
import 'package:e_commerce_app/Presentation/controller/product_details_cubit/product_details_cubit.dart';
import 'package:e_commerce_app/domain/entities/cart_item.dart';
import 'package:e_commerce_app/domain/entities/location.dart';
import 'package:e_commerce_app/domain/entities/payment_card.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:e_commerce_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_app/domain/repositories/cart_repository.dart';
import 'package:e_commerce_app/domain/repositories/checkout_repository.dart';
import 'package:e_commerce_app/domain/repositories/location_repository.dart';
import 'package:e_commerce_app/domain/repositories/product_details_repository.dart';

const product = Product(
  id: 'p',
  name: 'Laptop',
  imgUrl: '',
  price: 50,
  category: 'Laptops',
  stock: 10,
);
const address = Location(
  id: 'a',
  city: 'Cairo',
  country: 'Egypt',
  recipient: 'Test',
  phone: '01234567890',
  street: 'Street',
  building: '1',
);

class Auth extends Fake implements AuthRepository {
  @override
  String? get currentUserId => 'user';
}

class Products extends Fake implements ProductDetailsRepository {
  CartItem? added;
  @override
  Future<Product> fetchProductDetails(String id) async => product;
  @override
  Future<void> addToCart(CartItem item, String userId) async {
    added = item;
  }
}

class Cart extends Fake implements CartRepository {
  @override
  Future<List<CartItem>> fetchCartItems(String userId) async => [
    const CartItem(
      id: 'c',
      product: product,
      size: ProductSize.none,
      quantity: 1,
    ),
  ];
}

class Addresses extends Fake implements LocationRepository {
  @override
  Future<List<Location>> fetchLocations(
    String userId, {
    bool chosen = false,
  }) async => [address];
}

class Checkout extends Fake implements CheckoutRepository {
  @override
  Future<Map<String, dynamic>> quote(String addressId) async => {
    'quoteId': 'quote_request_fixture',
    'items': [
      {
        'id': 'c',
        'product': {'id': 'p', 'price': 50},
        'quantity': 1,
        'size': 'none',
      },
    ],
    'address': {'city': 'Cairo', 'country': 'Egypt'},
    'subtotal': 50,
    'shipping': 10,
    'totalAmount': 60,
  };
  final ids = <String>[];
  @override
  Future<List<PaymentCard>> fetchPaymentMethods(String userId) async => [];
  @override
  Future<Map<String, dynamic>> placeOrder({
    required String requestId,
    required String userId,
    required List<CartItem> items,
    required double subtotal,
    required double shipping,
    required double totalAmount,
    required Location address,
    PaymentCard? paymentCard,
    bool isCashOnDelivery = false,
  }) async {
    ids.add(requestId);
    if (ids.length == 1) throw Exception('Connection interrupted');
    return {'id': 'server-order-id', 'totalAmount': 60};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('non-clothing products do not require a clothing size', () async {
    final repo = Products();
    final cubit = ProductDetailsCubit(
      productDetailsRepository: repo,
      authRepository: Auth(),
    );
    await cubit.getProductDetails('p');
    await cubit.addToCart('p');
    expect(repo.added?.size, ProductSize.none);
    for (var i = 0; i < 150; i++) {
      cubit.incrementCounter('p');
    }
    expect(cubit.quantity, 10);
    await cubit.close();
  });
  test(
    'retry after an interrupted checkout reuses the same idempotency key',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = Checkout();
      final cubit = CheckoutCubit(
        cartRepository: Cart(),
        checkoutRepository: repo,
        locationRepository: Addresses(),
        authRepository: Auth(),
      );
      await cubit.getCheckoutContent();
      await cubit.placeOrder(isCashOnDelivery: true);
      expect(cubit.state, isA<CheckoutLoaded>());
      await cubit.placeOrder(isCashOnDelivery: true);
      expect(repo.ids, hasLength(2));
      expect(repo.ids[1], repo.ids[0]);
      expect(cubit.state, isA<CheckoutOrderPlaced>());
      await cubit.close();
    },
  );
}
