import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app/Presentation/controller/home_cubit/home_cubit.dart';
import 'package:e_commerce_app/Presentation/views/widgets/product_item.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/app_colors.dart';
import 'package:e_commerce_app/core/utils/app_route.dart';
import 'package:e_commerce_app/core/utils/responsive.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

enum ProductSort { featured, priceLowHigh, priceHighLow, topRated }

class HomeTabView extends StatefulWidget {
  final StoreDepartment selectedDepartment;
  final ValueChanged<StoreDepartment>? onDepartmentSelected;
  final String? selectedCategory;
  final ValueChanged<String?>? onCategorySelected;
  final VoidCallback? onShowAll;

  const HomeTabView({
    super.key,
    this.selectedDepartment = StoreDepartment.all,
    this.onDepartmentSelected,
    this.selectedCategory,
    this.onCategorySelected,
    this.onShowAll,
  });

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  ProductSort _sort = ProductSort.featured;
  List<Product>? _cachedSource;
  StoreDepartment? _cachedDepartment;
  String? _cachedCategory;
  ProductSort? _cachedSort;
  List<Product> _cachedFiltered = const [];

  String _departmentLabel(BuildContext context, StoreDepartment department) {
    final ar = context.isArabic;
    return switch (department) {
      StoreDepartment.all => ar ? 'كل المتجر' : 'All Store',
      StoreDepartment.fashion => ar ? 'الملابس والأزياء' : 'Clothing & Fashion',
      StoreDepartment.market => ar ? 'الماركت والبقالة' : 'Market & Pantry',
      StoreDepartment.living => ar ? 'المنزل والأثاث' : 'Home & Living',
      StoreDepartment.tech => ar ? 'الإلكترونيات' : 'Electronics',
      StoreDepartment.sports => ar ? 'الرياضة والمركبات' : 'Sports & Auto',
    };
  }

  IconData _departmentIcon(StoreDepartment department) {
    return switch (department) {
      StoreDepartment.all => Icons.storefront_outlined,
      StoreDepartment.fashion => Icons.checkroom_rounded,
      StoreDepartment.market => Icons.shopping_basket_outlined,
      StoreDepartment.living => Icons.chair_outlined,
      StoreDepartment.tech => Icons.devices_outlined,
      StoreDepartment.sports => Icons.sports_soccer_outlined,
    };
  }

  List<Product> _filterAndSort(List<Product> products) {
    if (identical(products, _cachedSource) &&
        _cachedDepartment == widget.selectedDepartment &&
        _cachedCategory == widget.selectedCategory &&
        _cachedSort == _sort) {
      return _cachedFiltered;
    }

    var list =
        products.where((p) {
          if (widget.selectedCategory != null) {
            return p.category.toLowerCase() ==
                widget.selectedCategory!.toLowerCase();
          }
          if (widget.selectedDepartment != StoreDepartment.all) {
            return ResponsiveLayout.departmentForCategory(p.category) ==
                widget.selectedDepartment;
          }
          return true;
        }).toList();

    switch (_sort) {
      case ProductSort.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSort.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSort.topRated:
        list.sort((a, b) => b.averageRate.compareTo(a.averageRate));
        break;
      case ProductSort.featured:
        break;
    }

    _cachedSource = products;
    _cachedDepartment = widget.selectedDepartment;
    _cachedCategory = widget.selectedCategory;
    _cachedSort = _sort;
    _cachedFiltered = list;
    return list;
  }

  Widget _buildCarouselBanner(
    BuildContext context,
    HomeLoaded state, {
    required double height,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: FlutterCarousel.builder(
        itemCount: state.carouselItems.length,
        itemBuilder: (context, itemIndex, pageViewIndex) {
          final banner = state.carouselItems[itemIndex];
          final productMatch = state.products.where((p) => p.id == banner.id);
          final product = productMatch.isNotEmpty ? productMatch.first : null;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: GestureDetector(
              onTap: () {
                if (product != null) {
                  Navigator.of(context, rootNavigator: true).pushNamed(
                    AppRoute.productDetailsRoute,
                    arguments: banner.id,
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color:
                          isDark
                              ? AppColors.surfaceCardDark
                              : AppColors.primaryColor,
                    ),
                    CachedNetworkImage(
                      imageUrl: banner.imgUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                      errorWidget:
                          (context, url, error) => const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: AppColors.grey1,
                            ),
                          ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.78),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      bottom: 18,
                      right: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.tr('featured').toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.white1,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product?.name ??
                                (context.isArabic
                                    ? 'تشكيلات الملابس والماركت'
                                    : 'Curated Fashion & Market'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white1,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (product != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'EGP ${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.accentSoft,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        options: FlutterCarouselOptions(
          height: height,
          viewportFraction: 1.0,
          showIndicator: true,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 5),
          slideIndicator: CircularWaveSlideIndicator(),
        ),
      ),
    );
  }

  Widget _buildDesktopEditorialHero(BuildContext context, HomeLoaded state) {
    final ar = context.isArabic;
    return Container(
      height: 310,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF141824), Color(0xFF232C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    ar
                        ? 'أزياء • بقالة وماركت • توصيل سريع'
                        : 'FASHION • MARKET • EVERYDAY ESSENTIALS',
                    style: const TextStyle(
                      color: AppColors.accentSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  ar
                      ? 'أناقة يومية وكل احتياجات الماركت في مكان واحد'
                      : 'Elevated Wardrobe &\nEveryday Market Store',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: AppColors.white1,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ar
                      ? 'تصفح تشكيلة الملابس والأحذية والبقالة والإلكترونيات مع الدفع عند الاستلام.'
                      : 'Shop apparel, footwear, groceries, home essentials and tech with cash on delivery.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white1.withValues(alpha: 0.78),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        foregroundColor: AppColors.white1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        widget.onCategorySelected?.call(null);
                        widget.onDepartmentSelected?.call(
                          StoreDepartment.fashion,
                        );
                      },
                      icon: const Icon(Icons.checkroom_rounded, size: 18),
                      label: Text(ar ? 'تسوق الملابس' : 'Shop Clothing'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white1,
                        side: BorderSide(
                          color: AppColors.white1.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        widget.onCategorySelected?.call(null);
                        widget.onDepartmentSelected?.call(
                          StoreDepartment.market,
                        );
                      },
                      icon: const Icon(
                        Icons.shopping_basket_outlined,
                        size: 18,
                      ),
                      label: Text(ar ? 'تسوق الماركت' : 'Browse Market'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (state.carouselItems.isNotEmpty) ...[
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: _buildCarouselBanner(context, state, height: 262),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.black;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.grey1;
    final ar = context.isArabic;

    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VERVE STORE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ar
                    ? 'متجر الملابس والماركت • الدفع عند الاستلام'
                    : 'Fashion & Market Store • Cash on Delivery',
                style: TextStyle(color: subtextColor, fontSize: 12.5),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed:
                    () => launchUrl(
                      Uri.parse('https://wa.me/201095930009'),
                      mode: LaunchMode.externalApplication,
                    ),
                icon: const Icon(Icons.chat_outlined, size: 17),
                label: Text(ar ? 'دعم واتساب' : 'WhatsApp Support'),
              ),
              if (kIsWeb)
                OutlinedButton.icon(
                  onPressed:
                      () => launchUrl(
                        Uri.parse('${Uri.base.origin}/download/android'),
                        mode: LaunchMode.externalApplication,
                      ),
                  icon: const Icon(Icons.android_rounded, size: 17),
                  label: Text(ar ? 'تطبيق الأندرويد' : 'Android App'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.black;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.grey1;

    return BlocBuilder<HomeCubit, HomeState>(
      bloc: BlocProvider.of<HomeCubit>(context),
      buildWhen:
          (previous, current) =>
              current is HomeLoaded ||
              current is HomeLoading ||
              current is HomeError,
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else if (state is HomeLoaded) {
          final displayedProducts = _filterAndSort(state.products);
          final categoryChips = [
            'All',
            ...state.categories
                .where((c) => c.name != 'All Products')
                .where(
                  (c) =>
                      widget.selectedDepartment == StoreDepartment.all ||
                      ResponsiveLayout.departmentForCategory(c.name) ==
                          widget.selectedDepartment,
                )
                .map((c) => c.name),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final desktopHero = ResponsiveLayout.useDesktopNav(width);
              final columns = ResponsiveLayout.productGridColumns(width);

              return RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().getHomeData(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (desktopHero)
                            _buildDesktopEditorialHero(context, state)
                          else if (state.carouselItems.isNotEmpty)
                            _buildCarouselBanner(context, state, height: 190),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: StoreDepartment.values.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final dept = StoreDepartment.values[index];
                                final selected =
                                    widget.selectedDepartment == dept &&
                                    widget.selectedCategory == null;
                                return ChoiceChip(
                                  avatar: Icon(
                                    _departmentIcon(dept),
                                    size: 16,
                                    color:
                                        selected
                                            ? AppColors.white1
                                            : AppColors.accentColor,
                                  ),
                                  label: Text(_departmentLabel(context, dept)),
                                  selected: selected,
                                  showCheckmark: false,
                                  selectedColor: AppColors.accentColor,
                                  backgroundColor: cardBg,
                                  labelStyle: TextStyle(
                                    color:
                                        selected ? AppColors.white1 : textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color:
                                          selected
                                              ? AppColors.accentColor
                                              : borderColor,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    widget.onCategorySelected?.call(null);
                                    widget.onDepartmentSelected?.call(dept);
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categoryChips.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final label = categoryChips[index];
                                final displayLabel =
                                    label == 'All'
                                        ? context.tr('all')
                                        : context.trCategory(label);
                                final isSelected =
                                    (label == 'All' &&
                                        widget.selectedCategory == null) ||
                                    (widget.selectedCategory != null &&
                                        label.toLowerCase() ==
                                            widget.selectedCategory!
                                                .toLowerCase());
                                return ChoiceChip(
                                  label: Text(displayLabel),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  selectedColor:
                                      isDark
                                          ? AppColors.accentColor
                                          : AppColors.primaryColor,
                                  backgroundColor: cardBg,
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? AppColors.white1
                                            : textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color:
                                          isSelected
                                              ? (isDark
                                                  ? AppColors.accentColor
                                                  : AppColors.primaryColor)
                                              : borderColor,
                                    ),
                                  ),
                                  onSelected: (_) {
                                    widget.onCategorySelected?.call(
                                      label == 'All' ? null : label,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.selectedCategory != null
                                            ? context.trCategory(
                                              widget.selectedCategory!,
                                            )
                                            : widget.selectedDepartment !=
                                                StoreDepartment.all
                                            ? _departmentLabel(
                                              context,
                                              widget.selectedDepartment,
                                            )
                                            : context.tr('trending_products'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge!.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        '${displayedProducts.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: subtextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<ProductSort>(
                                        value: _sort,
                                        borderRadius: BorderRadius.circular(12),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        items: [
                                          DropdownMenuItem(
                                            value: ProductSort.featured,
                                            child: Text(
                                              context.isArabic
                                                  ? 'الترتيب الافتراضي'
                                                  : 'Sort: Featured',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: ProductSort.priceLowHigh,
                                            child: Text(
                                              context.isArabic
                                                  ? 'السعر: من الأقل'
                                                  : 'Price: Low to High',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: ProductSort.priceHighLow,
                                            child: Text(
                                              context.isArabic
                                                  ? 'السعر: من الأعلى'
                                                  : 'Price: High to Low',
                                            ),
                                          ),
                                          DropdownMenuItem(
                                            value: ProductSort.topRated,
                                            child: Text(
                                              context.isArabic
                                                  ? 'الأعلى تقييمًا'
                                                  : 'Top Rated',
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _sort = value);
                                          }
                                        },
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: widget.onShowAll,
                                      child: Text(
                                        (widget.selectedCategory != null ||
                                                widget.selectedDepartment !=
                                                    StoreDepartment.all)
                                            ? context.tr('view_all')
                                            : context.tr('refresh'),
                                        style: const TextStyle(
                                          color: AppColors.accentColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    if (displayedProducts.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Text(
                              widget.selectedCategory == null
                                  ? (context.isArabic
                                      ? 'لا توجد منتجات متاحة بعد'
                                      : 'No products available yet')
                                  : (context.isArabic
                                      ? 'لا توجد منتجات في هذه الفئة'
                                      : 'No products found in this category'),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverGrid.builder(
                        itemCount: displayedProducts.length,
                        addAutomaticKeepAlives: false,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          mainAxisExtent: 294,
                        ),
                        itemBuilder: (context, index) {
                          final product = displayedProducts[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(
                                AppRoute.productDetailsRoute,
                                arguments: product.id,
                              );
                            },
                            child: ProductItem(productItem: product),
                          );
                        },
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 28),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (state.hasMore)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: OutlinedButton(
                                    onPressed:
                                        state.loadingMore
                                            ? null
                                            : () => context
                                                .read<HomeCubit>()
                                                .getHomeData(loadMore: true),
                                    child: Text(
                                      state.loadingMore
                                          ? (context.isArabic
                                              ? 'جارٍ التحميل...'
                                              : 'Loading...')
                                          : (context.isArabic
                                              ? 'تحميل المزيد'
                                              : 'Load more'),
                                    ),
                                  ),
                                ),
                              ),
                            _buildStoreFooter(context),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        } else if (state is HomeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.trError(state.message),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<HomeCubit>().getHomeData(),
                    child: Text(context.tr('retry')),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
