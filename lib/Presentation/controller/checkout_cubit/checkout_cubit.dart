import 'package:e_commerce_app/data/repositories/auth_repository_impl.dart';
import 'package:e_commerce_app/data/repositories/cart_repository_impl.dart';
import 'package:e_commerce_app/data/repositories/checkout_repository_impl.dart';
import 'package:e_commerce_app/data/repositories/location_repository_impl.dart';
import 'package:e_commerce_app/domain/entities/cart_item.dart';
import 'package:e_commerce_app/domain/entities/location.dart';
import 'package:e_commerce_app/domain/entities/payment_card.dart';
import 'package:e_commerce_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_app/domain/repositories/cart_repository.dart';
import 'package:e_commerce_app/domain/repositories/checkout_repository.dart';
import 'package:e_commerce_app/domain/repositories/location_repository.dart';
import 'package:e_commerce_app/services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_app/data/models/add_to_cart_model.dart';
import 'package:e_commerce_app/data/models/location_item_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    CartRepository? cartRepository,
    CheckoutRepository? checkoutRepository,
    LocationRepository? locationRepository,
    AuthRepository? authRepository,
  }) : _cartRepository = cartRepository ?? CartRepositoryImpl(),
       _checkoutRepository = checkoutRepository ?? CheckoutRepositoryImpl(),
       _locationRepository = locationRepository ?? LocationRepositoryImpl(),
       _authRepository = authRepository ?? AuthRepositoryImpl(),
       super(CheckoutInitial());

  final CartRepository _cartRepository;
  final CheckoutRepository _checkoutRepository;
  final LocationRepository _locationRepository;
  final AuthRepository _authRepository;

  Future<void> getCheckoutContent() async {
    emit(CheckoutLoading());
    try {
      final currentUserId = _authRepository.currentUserId;
      if (currentUserId == null) {
        emit(CheckoutError('User is not logged in'));
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final key = 'checkout_request_$currentUserId';
      final pending = prefs.getString(key);
      if (pending != null && await _checkoutRepository.receiptExists(pending)) {
        await prefs.remove(key);
        if (!isClosed) emit(CheckoutReceiptRecovered());
        return;
      }
      var cartItems = await _cartRepository.fetchCartItems(currentUserId);
      double shippingValue = cartItems.isEmpty ? 0 : 10;
      var subtotal = cartItems.fold(
        0.0,
        (previousValue, element) =>
            previousValue + (element.product.price * element.quantity),
      );
      var numOfProducts = cartItems.fold(
        0,
        (previousValue, element) => previousValue + element.quantity,
      );

      final paymentCards = await _checkoutRepository.fetchPaymentMethods(
        currentUserId,
      );
      PaymentCard? chosenPaymentCard;
      for (final card in paymentCards) {
        if (card.isChosen) {
          chosenPaymentCard = card;
          break;
        }
      }
      chosenPaymentCard ??= paymentCards.isNotEmpty ? paymentCards.first : null;

      final chosenLocations = await _locationRepository.fetchLocations(
        currentUserId,
        chosen: true,
      );
      Location? chosenAddress =
          chosenLocations.isNotEmpty ? chosenLocations.first : null;
      if (chosenAddress == null) {
        final allLocations = await _locationRepository.fetchLocations(
          currentUserId,
        );
        if (allLocations.isNotEmpty) {
          chosenAddress = allLocations.first;
        }
      }

      var demo = false;
      var total = subtotal + shippingValue;
      _requestId = null;
      if (chosenAddress != null && cartItems.isNotEmpty) {
        final quote = await _checkoutRepository.quote(chosenAddress.id);
        _requestId = quote['quoteId'] as String;
        demo = quote['paymentMethod'] == 'demo';
        total = (quote['totalAmount'] as num).toDouble();
        cartItems =
            (quote['items'] as List)
                .map((i) => AddToCartModel.fromMap(i as Map<String, dynamic>))
                .toList();
        numOfProducts = cartItems.fold(0, (sum, item) => sum + item.quantity);
        chosenAddress = LocationItemModel.fromMap({
          ...quote['address'] as Map<String, dynamic>,
          'id': chosenAddress.id,
        });
        subtotal = (quote['subtotal'] as num).toDouble();
        shippingValue = (quote['shipping'] as num).toDouble();
      }
      if (isClosed) return;
      emit(
        CheckoutLoaded(
          cartItems: cartItems,
          totalAmount: total,
          demo: demo,
          subtotal: subtotal,
          shippingValue: shippingValue,
          numOfProducts: numOfProducts,
          chosenPaymentCard: chosenPaymentCard,
          chosenAddress: chosenAddress,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(CheckoutError(e.toString()));
    }
  }

  String? _requestId;

  Future<void> placeOrder({bool isCashOnDelivery = true}) async {
    final currentState = state;
    if (currentState is! CheckoutLoaded) return;
    if (currentState.cartItems.isEmpty) {
      emit(CheckoutOrderError('Your cart is empty'));
      emit(currentState);
      return;
    }
    if (currentState.chosenAddress == null) {
      emit(CheckoutOrderError('Please select a shipping address'));
      emit(currentState);
      return;
    }
    if (!isCashOnDelivery && currentState.chosenPaymentCard == null) {
      emit(
        CheckoutOrderError(
          'Please select a payment card or choose Cash on Delivery',
        ),
      );
      emit(currentState);
      return;
    }

    emit(CheckoutPlacingOrder());
    try {
      final currentUserId = _authRepository.currentUserId;
      if (currentUserId == null) {
        emit(CheckoutOrderError('User is not logged in'));
        emit(currentState);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final key = 'checkout_request_$currentUserId';
      await prefs.setString(key, _requestId!);
      final order = await _checkoutRepository.placeOrder(
        requestId: _requestId!,
        userId: currentUserId,
        items: currentState.cartItems,
        subtotal: currentState.subtotal,
        shipping: currentState.shippingValue,
        totalAmount: currentState.totalAmount,
        address: currentState.chosenAddress!,
        paymentCard: currentState.chosenPaymentCard,
        isCashOnDelivery: isCashOnDelivery,
      );
      await prefs.remove(key);
      _requestId = null;
      try {
        await NotificationService.instance.showOrderPlacedNotification(
          orderId: order['id'] as String,
          totalAmount: (order['totalAmount'] as num).toDouble(),
        );
      } catch (_) {}
      if (isClosed) return;
      emit(CheckoutOrderPlaced());
    } catch (e) {
      if (isClosed) return;
      emit(CheckoutOrderError(e.toString()));
      emit(currentState);
    }
  }
}
