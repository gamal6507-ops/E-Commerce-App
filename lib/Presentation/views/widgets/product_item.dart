import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app/Presentation/controller/favorite_cubit/favorite_cubit.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/app_colors.dart';
import 'package:e_commerce_app/core/utils/app_route.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductItem extends StatefulWidget {
  final Product productItem;
  const ProductItem({super.key, required this.productItem});

  @override
  State<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  final ValueNotifier<bool> _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productItem = widget.productItem;
    final favoritCubit = BlocProvider.of<FavoriteCubit>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final softBg = isDark ? AppColors.surfaceSoftDark : AppColors.surfaceSoft;
    final baseBorderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.black;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: _hovered,
        builder: (context, hovered, child) {
          return Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    hovered
                        ? AppColors.accentColor.withValues(alpha: 0.7)
                        : baseBorderColor,
                width: hovered ? 1.4 : 1.0,
              ),
              boxShadow:
                  hovered
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.08,
                          ),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                      : null,
            ),
            padding: const EdgeInsets.all(11),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: softBg,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: CachedNetworkImage(
                          imageUrl: productItem.imgUrl,
                          fit: BoxFit.contain,
                          memCacheWidth: 420,
                          fadeInDuration: const Duration(milliseconds: 90),
                          fadeOutDuration: const Duration(milliseconds: 60),
                          placeholder:
                              (context, url) => const Center(
                                child: SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.grey1,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.yellow,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            productItem.averageRate.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (productItem.stock <= 0)
                    PositionedDirectional(
                      bottom: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.isArabic ? 'نفذت الكمية' : 'Out of stock',
                          style: const TextStyle(
                            color: AppColors.white1,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else if (productItem.requiresSize)
                    PositionedDirectional(
                      bottom: 6,
                      start: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'S–XL',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg.withValues(alpha: 0.94),
                      ),
                      child: BlocConsumer<FavoriteCubit, FavoriteState>(
                        bloc: favoritCubit,
                        listenWhen:
                            (previous, current) =>
                                (current is FavoriteRemoveError ||
                                    current is SetFavoriteLoadedError),
                        listener: (context, state) {
                          if (state is FavoriteRemoveError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.error)),
                            );
                          } else if (state is SetFavoriteLoadedError &&
                              state.productId == productItem.id) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.error)),
                            );
                          }
                        },
                        buildWhen: (previous, current) {
                          bool isLoadingForItem(FavoriteState s) =>
                              (s is SetFavoriteLoading &&
                                  s.productId == productItem.id) ||
                              (s is FavoriteRemoving &&
                                  s.productId == productItem.id);
                          if (isLoadingForItem(previous) !=
                              isLoadingForItem(current)) {
                            return true;
                          }
                          if (current is FavoriteLoaded &&
                              previous is FavoriteLoaded) {
                            final wasFav = previous.favoriteProducts.any(
                              (p) => p.id == productItem.id,
                            );
                            final isFavNow = current.favoriteProducts.any(
                              (p) => p.id == productItem.id,
                            );
                            return wasFav != isFavNow;
                          }
                          return current is FavoriteLoaded ||
                              current is FavoriteInitial ||
                              (current is SetFavoriteLoadedError &&
                                  current.productId == productItem.id);
                        },
                        builder: (context, state) {
                          final isFavLoading =
                              (state is SetFavoriteLoading &&
                                  state.productId == productItem.id) ||
                              (state is FavoriteRemoving &&
                                  state.productId == productItem.id);

                          if (isFavLoading) {
                            return const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                              ),
                            );
                          }

                          final isFav =
                              state is FavoriteLoaded
                                  ? state.favoriteProducts.any(
                                    (p) => p.id == productItem.id,
                                  )
                                  : productItem.isFavorite;

                          return InkWell(
                            onTap: () async {
                              if (FirebaseAuth.instance.currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.isArabic
                                          ? 'سجّل الدخول لحفظ المنتجات في المفضلة'
                                          : 'Sign in to save favorite items',
                                    ),
                                    action: SnackBarAction(
                                      label: context.tr('sign_in'),
                                      onPressed:
                                          () => Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pushNamed(AppRoute.loginRoute),
                                    ),
                                  ),
                                );
                                return;
                              }
                              await favoritCubit.setFavorite(productItem);
                            },
                            child: Icon(
                              isFav
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: isFav ? AppColors.red : textColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.trCategory(productItem.category).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? AppColors.textSecondaryDark : AppColors.grey1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              productItem.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'EGP ${productItem.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
