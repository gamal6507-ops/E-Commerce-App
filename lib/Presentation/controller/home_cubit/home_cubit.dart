import 'package:e_commerce_app/data/datasources/external_catalog_service.dart';
import 'package:e_commerce_app/data/datasources/product_local_cache.dart';
import 'package:e_commerce_app/data/repositories/auth_repository_impl.dart';
import 'package:e_commerce_app/data/repositories/favorite_repository_impl.dart';
import 'package:e_commerce_app/data/repositories/home_repository_impl.dart';
import 'package:e_commerce_app/domain/entities/carousel_item.dart';
import 'package:e_commerce_app/domain/entities/category.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:e_commerce_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_app/domain/repositories/favorite_repository.dart';
import 'package:e_commerce_app/domain/repositories/home_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    HomeRepository? homeRepository,
    FavoriteRepository? favoriteRepository,
    AuthRepository? authRepository,
  }) : _homeRepository = homeRepository ?? HomeRepositoryImpl(),
       _favoriteRepository = favoriteRepository ?? FavoriteRepositoryImpl(),
       _authRepository = authRepository ?? AuthRepositoryImpl(),
       super(HomeInitial());

  final HomeRepository _homeRepository;
  final FavoriteRepository _favoriteRepository;
  final AuthRepository _authRepository;

  bool _loading = false;
  Future<void> getHomeData({bool loadMore = false}) async {
    if (_loading) {
      return;
    }
    _loading = true;
    final previous = state;
    var servedCache = false;
    if (loadMore && previous is HomeLoaded) {
      emit(
        HomeLoaded(
          carouselItems: previous.carouselItems,
          products: previous.products,
          categories: previous.categories,
          hasMore: previous.hasMore,
          loadingMore: true,
        ),
      );
    } else {
      if (_homeRepository is HomeRepositoryImpl) {
        final cached = await ProductLocalCache.instance.getCachedProducts(
          ignoreExpiration: false,
        );
        if (!isClosed && cached != null && cached.isNotEmpty) {
          servedCache = true;
          emit(
            HomeLoaded(
              carouselItems: ExternalCatalogService.instance
                  .buildCarouselFromProducts(cached),
              products: cached,
              categories: ExternalCatalogService.instance
                  .buildCategoriesFromProducts(cached),
              hasMore: cached.length == 200,
            ),
          );
        }
      }
      if (!servedCache && !isClosed) {
        emit(HomeLoading());
      }
    }
    try {
      final currentUserId = _authRepository.currentUserId;
      final products = await _homeRepository.fetchProducts(loadMore: loadMore);
      final carouselItems = await _homeRepository.fetchCarouselItems();
      final categories = await _homeRepository.fetchCategories();
      final favoriteProducts =
          currentUserId != null
              ? await _favoriteRepository.getFavorites(currentUserId)
              : <Product>[];
      final favoriteIds = favoriteProducts.map((item) => item.id).toSet();

      final List<Product> finalProducts =
          products.map((product) {
            return product.copyWith(
              isFavorite: favoriteIds.contains(product.id),
            );
          }).toList();
      if (isClosed) return;
      emit(
        HomeLoaded(
          carouselItems: carouselItems,
          products: finalProducts,
          categories: categories,
          hasMore: _homeRepository.hasMore,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (!servedCache) {
        emit(HomeError(e.toString()));
      }
    } finally {
      _loading = false;
    }
  }
}
