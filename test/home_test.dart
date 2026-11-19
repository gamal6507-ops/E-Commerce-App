import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_app/Presentation/controller/home_cubit/home_cubit.dart';
import 'package:e_commerce_app/Presentation/views/widgets/home_tab_view.dart';
import 'package:e_commerce_app/domain/repositories/home_repository.dart';
import 'package:e_commerce_app/domain/repositories/favorite_repository.dart';
import 'package:e_commerce_app/domain/repositories/auth_repository.dart';
import 'package:e_commerce_app/domain/entities/product.dart';
import 'package:e_commerce_app/domain/entities/carousel_item.dart';
import 'package:e_commerce_app/domain/entities/category.dart';
class _Auth extends Fake implements AuthRepository { @override String? get currentUserId=>'test'; }
class _Favorites extends Fake implements FavoriteRepository { @override Future<List<Product>> getFavorites(String id) async=>[]; }
class _Catalog extends Fake implements HomeRepository {
 final calls=<bool>[];
 @override bool get hasMore=>calls.length==1;
 @override Future<List<Product>> fetchProducts({bool loadMore=false}) async {calls.add(loadMore);return [];}
 @override Future<List<Category>> fetchCategories() async=>[];
 @override Future<List<CarouselItem>> fetchCarouselItems() async=>[];
}
void main(){
 test('home requests the next page without restarting catalog pagination',() async {
  final catalog=_Catalog();final cubit=HomeCubit(homeRepository:catalog,favoriteRepository:_Favorites(),authRepository:_Auth());
  await cubit.getHomeData();expect((cubit.state as HomeLoaded).hasMore,isTrue);
  await cubit.getHomeData(loadMore:true);expect(catalog.calls,[false,true]);expect((cubit.state as HomeLoaded).hasMore,isFalse);
  await cubit.close();
 });
 testWidgets('empty live catalog renders without a carousel exception',(tester) async {
  final cubit=HomeCubit(homeRepository:_Catalog(),favoriteRepository:_Favorites(),authRepository:_Auth());
  await cubit.getHomeData();
  await tester.pumpWidget(MaterialApp(home:BlocProvider.value(value:cubit,child:const Scaffold(body:HomeTabView()))));
  await tester.pump();expect(tester.takeException(),isNull);
  await tester.pumpWidget(const SizedBox());await cubit.close();
 });
}
