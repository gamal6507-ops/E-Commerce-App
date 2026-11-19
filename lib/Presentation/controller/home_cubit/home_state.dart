part of 'home_cubit.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  HomeLoaded({
    required this.carouselItems,
    required this.products,
    required this.categories,
    this.hasMore = false,
    this.loadingMore = false,
  });

  final List<CarouselItem> carouselItems;
  final List<Product> products;
  final List<Category> categories;
  final bool hasMore;
  final bool loadingMore;
}

final class HomeError extends HomeState {
  HomeError(this.message);

  final String message;
}
