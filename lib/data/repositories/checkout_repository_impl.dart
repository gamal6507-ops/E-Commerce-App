import 'package:e_commerce_app/data/datasources/store_api.dart';
import 'package:e_commerce_app/domain/entities/cart_item.dart';
import 'package:e_commerce_app/domain/entities/location.dart';
import 'package:e_commerce_app/domain/entities/payment_card.dart';
import 'package:e_commerce_app/domain/repositories/checkout_repository.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  @override
  Future<bool> receiptExists(String requestId) async {
    final receipt = await StoreApi.instance.request(
      'receipt',
      method: 'POST',
      body: {'requestId': requestId},
    );
    return receipt['found'] == true;
  }

  @override
  Future<Map<String, dynamic>> quote(String addressId) => StoreApi.instance
      .request('quote', method: 'POST', body: {'addressId': addressId});
  @override
  Future<void> setNewCard(String userId, PaymentCard card) async =>
      throw UnsupportedError(
        'Card payments are not configured. Use cash on delivery.',
      );
  @override
  Future<void> deletePaymentCard(String userId, String paymentId) async =>
      throw UnsupportedError('Card storage is disabled');
  @override
  Future<List<PaymentCard>> fetchPaymentMethods(String userId) async => [];
  @override
  Future<PaymentCard> fetchSinglePaymentMethod(
    String userId,
    String paymentId,
  ) async => throw UnsupportedError('Card storage is disabled');
  @override
  Future<List<Map<String, dynamic>>> fetchOrders(String userId) async {
    final data = await StoreApi.instance.request('orders');
    return (data['orders'] as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required List<CartItem> items,
    required double subtotal,
    required double shipping,
    required double totalAmount,
    required Location address,
    PaymentCard? paymentCard,
    bool isCashOnDelivery = false,
    required String requestId,
  }) async {
    if (!isCashOnDelivery) {
      throw UnsupportedError('Card payments are not configured');
    }
    return StoreApi.instance.request(
      'checkout',
      method: 'POST',
      body: {
        'addressId': address.id,
        'requestId': requestId,
        'expectedAmount': totalAmount,
      },
    );
  }
}
