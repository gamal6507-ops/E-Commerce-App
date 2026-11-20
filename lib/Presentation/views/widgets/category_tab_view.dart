import 'package:e_commerce_app/Presentation/controller/home_cubit/home_cubit.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/app_colors.dart';
import 'package:e_commerce_app/core/utils/responsive.dart';
import 'package:e_commerce_app/domain/entities/category.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryTabView extends StatelessWidget {
  final ValueChanged<String>? onCategoryTap;

  const CategoryTabView({super.key, this.onCategoryTap});

  IconData _iconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('all')) return Icons.grid_view_rounded;
    if (lower.contains('shirt') ||
        lower.contains('dress') ||
        lower.contains('top')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('shoe')) return Icons.directions_run_rounded;
    if (lower.contains('bag')) return Icons.shopping_bag_rounded;
    if (lower.contains('watch')) return Icons.watch_rounded;
    if (lower.contains('jewel')) return Icons.diamond_outlined;
    if (lower.contains('sunglass')) return Icons.wb_sunny_outlined;
    if (lower.contains('grocer')) return Icons.shopping_basket_rounded;
    if (lower.contains('kitchen')) return Icons.soup_kitchen_rounded;
    if (lower.contains('beauty') || lower.contains('skin')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('fragrance')) return Icons.local_florist_rounded;
    if (lower.contains('furniture') || lower.contains('decoration')) {
      return Icons.chair_rounded;
    }
    if (lower.contains('laptop') || lower.contains('tablet')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('phone') || lower.contains('mobile')) {
      return Icons.smartphone_rounded;
    }
    if (lower.contains('sport')) return Icons.sports_soccer_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is HomeError) {
          return Center(child: Text(context.trError(state.message)));
        }
        final categories =
            state is HomeLoaded ? state.categories : const <Category>[];
        if (categories.isEmpty) {
          return Center(
            child: Text(
              context.isArabic ? 'لا توجد فئات متاحة بعد' : 'No categories yet',
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = ResponsiveLayout.categoryGridColumns(
              constraints.maxWidth,
            );
            return GridView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 106,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final cardColor = Color(category.bgColorValue);
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onCategoryTap?.call(category.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [cardColor, cardColor.withValues(alpha: 0.84)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.trCategory(category.name),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge!.copyWith(
                                  color: Color(category.textColorValue),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.isArabic
                                    ? '${category.productsCount} ${context.tr('items_count')}'
                                    : '${category.productsCount} Products',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall!.copyWith(
                                  color: Color(
                                    category.textColorValue,
                                  ).withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: AppColors.white1.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconForCategory(category.name),
                            color: Color(category.textColorValue),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
