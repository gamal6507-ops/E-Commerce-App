import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_app/Presentation/controller/favorite_cubit/favorite_cubit.dart';
import 'package:e_commerce_app/Presentation/controller/home_cubit/home_cubit.dart';
import 'package:e_commerce_app/Presentation/views/widgets/home_tab_view.dart';
import 'package:e_commerce_app/Presentation/views/widgets/product_item.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/responsive.dart';
import 'package:e_commerce_app/domain/repositories/home_repository.dart';
import 'package:e_commerce_app/domain/repositories/favorite_repository.dart';
import 'package:e_commerce_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:e_commerce_app/domain/entities/carousel_item.dart';
import 'package:e_commerce_app/domain/entities/category.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  String? get currentUserId => 'test';
}

class _Favorites extends Fake implements FavoriteRepository {
  @override
  Future<List<Product>> getFavorites(String id) async => [];
}

class _Catalog extends Fake implements HomeRepository {
  final calls = <bool>[];
  final List<Product> items;
  _Catalog([this.items = const []]);
  @override
  bool get hasMore => calls.length == 1;
  @override
  Future<List<Product>> fetchProducts({bool loadMore = false}) async {
    calls.add(loadMore);
    return items;
  }

  @override
  Future<List<Category>> fetchCategories() async => [
    for (final p in items)
      Category(
        id: p.category,
        name: p.category,
        productsCount: 1,
        bgColorValue: 0xFF141824,
        textColorValue: 0xFFFFFFFF,
      ),
  ];

  @override
  Future<List<CarouselItem>> fetchCarouselItems() async => [
    for (final p in items.take(2)) CarouselItem(id: p.id, imgUrl: p.imgUrl),
  ];
}

void main() {
  test(
    'home requests the next page without restarting catalog pagination',
    () async {
      final catalog = _Catalog();
      final cubit = HomeCubit(
        homeRepository: catalog,
        favoriteRepository: _Favorites(),
        authRepository: _Auth(),
      );
      await cubit.getHomeData();
      expect((cubit.state as HomeLoaded).hasMore, isTrue);
      await cubit.getHomeData(loadMore: true);
      expect(catalog.calls, [false, true]);
      expect((cubit.state as HomeLoaded).hasMore, isFalse);
      await cubit.close();
    },
  );
  testWidgets('empty live catalog renders without a carousel exception', (
    tester,
  ) async {
    final cubit = HomeCubit(
      homeRepository: _Catalog(),
      favoriteRepository: _Favorites(),
      authRepository: _Auth(),
    );
    await cubit.getHomeData();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: HomeTabView()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
  testWidgets(
    'home storefront renders cleanly across mobile, tablet and desktop viewports',
    (tester) async {
      final items = const [
        Product(
          id: '1',
          name: 'Cotton Shirt',
          imgUrl: '',
          price: 29.99,
          category: 'Mens Shirts',
          requiresSize: true,
          stock: 10,
        ),
        Product(
          id: '2',
          name: 'Fresh Organic Apples',
          imgUrl: '',
          price: 4.99,
          category: 'Groceries',
          requiresSize: false,
          stock: 20,
        ),
      ];
      final homeCubit = HomeCubit(
        homeRepository: _Catalog(items),
        favoriteRepository: _Favorites(),
        authRepository: _Auth(),
      );
      final favCubit = FavoriteCubit(
        favoriteRepository: _Favorites(),
        authRepository: _Auth(),
      );
      await homeCubit.getHomeData();

      for (final size in const [
        Size(390, 844),
        Size(768, 1024),
        Size(1280, 800),
      ]) {
        final errors = <FlutterErrorDetails>[];
        final prevOnError = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = prevOnError);
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: homeCubit),
                BlocProvider.value(value: favCubit),
              ],
              child: const Scaffold(
                body: HomeTabView(selectedDepartment: StoreDepartment.fashion),
              ),
            ),
          ),
        );
        await tester.pump();
        FlutterError.onError = prevOnError;
        expect(
          errors.map((e) => e.toString()).toList(),
          isEmpty,
          reason: 'Unexpected exception at viewport $size',
        );
        expect(
          find.descendant(
            of: find.byType(ProductItem),
            matching: find.text('Cotton Shirt'),
          ),
          findsOneWidget,
        );
        expect(find.text('Fresh Organic Apples'), findsNothing);
      }
      await tester.binding.setSurfaceSize(null);
      await tester.pumpWidget(const SizedBox());
      await homeCubit.close();
      await favCubit.close();
    },
  );
}
