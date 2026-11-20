import 'package:e_commerce_app/Presentation/controller/app_preferences_cubit/app_preferences_cubit.dart';
import 'package:e_commerce_app/Presentation/controller/app_preferences_cubit/app_preferences_state.dart';
import 'package:e_commerce_app/Presentation/views/pages/cart_page.dart';
import 'package:e_commerce_app/Presentation/views/pages/favorites_page.dart';
import 'package:e_commerce_app/Presentation/views/pages/home_page.dart';
import 'package:e_commerce_app/Presentation/views/pages/profile_page.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/app_colors.dart';
import 'package:e_commerce_app/core/utils/app_route.dart';
import 'package:e_commerce_app/core/utils/responsive.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class CustomBottomNavbar extends StatefulWidget {
  const CustomBottomNavbar({super.key});

  @override
  State<CustomBottomNavbar> createState() => _CustomBottomNavbarState();
}

class _CustomBottomNavbarState extends State<CustomBottomNavbar> {
  late final PersistentTabController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_controller.index != index) {
      _controller.jumpToTab(index);
    }
    setState(() => _selectedIndex = index);
  }

  List<ItemConfig> _navBarsItems(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.accentColor : AppColors.primaryColor;
    final inactiveColor =
        isDark ? AppColors.textSecondaryDark : AppColors.grey1;

    return [
      ItemConfig(
        icon: const Icon(CupertinoIcons.house_fill),
        inactiveIcon: const Icon(CupertinoIcons.house),
        title: context.tr('nav_discover'),
        activeForegroundColor: activeColor,
        inactiveForegroundColor: inactiveColor,
      ),
      ItemConfig(
        icon: const Icon(CupertinoIcons.bag_fill),
        inactiveIcon: const Icon(CupertinoIcons.bag),
        title: context.tr('nav_cart'),
        activeForegroundColor: activeColor,
        inactiveForegroundColor: inactiveColor,
      ),
      ItemConfig(
        icon: const Icon(CupertinoIcons.heart_fill),
        inactiveIcon: const Icon(CupertinoIcons.heart),
        title: context.tr('nav_saved'),
        activeForegroundColor: AppColors.accentColor,
        inactiveForegroundColor: inactiveColor,
      ),
      ItemConfig(
        icon: const Icon(CupertinoIcons.person_fill),
        inactiveIcon: const Icon(CupertinoIcons.person),
        title: context.tr('nav_account'),
        activeForegroundColor: activeColor,
        inactiveForegroundColor: inactiveColor,
      ),
    ];
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textDark : AppColors.black;
    final subtextColor = isDark ? AppColors.textSecondaryDark : AppColors.grey1;

    final navLabels = [
      (label: context.tr('nav_discover'), icon: Icons.explore_outlined),
      (label: context.tr('nav_cart'), icon: Icons.shopping_bag_outlined),
      (label: context.tr('nav_saved'), icon: Icons.favorite_border_rounded),
      (label: context.tr('nav_account'), icon: Icons.person_outline_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ResponsiveContainer(
        maxWidth: 1280,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _switchTab(0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.accentColor
                                : AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.white1,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VERVE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            color: textColor,
                          ),
                        ),
                        Text(
                          context.isArabic
                              ? 'أزياء وماركت متكامل'
                              : 'FASHION & MARKET',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Wrap(
                spacing: 6,
                children: [
                  for (var i = 0; i < navLabels.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _switchTab(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _selectedIndex == i
                                  ? (isDark
                                      ? AppColors.accentColor.withValues(
                                        alpha: 0.16,
                                      )
                                      : AppColors.primaryColor.withValues(
                                        alpha: 0.08,
                                      ))
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              navLabels[i].icon,
                              size: 18,
                              color:
                                  _selectedIndex == i
                                      ? (isDark
                                          ? AppColors.accentColor
                                          : AppColors.primaryColor)
                                      : subtextColor,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              navLabels[i].label,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                    _selectedIndex == i
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                color:
                                    _selectedIndex == i
                                        ? textColor
                                        : subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
              builder: (context, prefState) {
                final isAr = prefState.locale.languageCode == 'ar';
                final dark = prefState.themeMode == ThemeMode.dark;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:
                          () => context.read<AppPreferencesCubit>().setLocale(
                            Locale(isAr ? 'en' : 'ar'),
                          ),
                      child: Text(
                        isAr ? 'EN' : 'عربي',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: context.tr('settings_theme'),
                      style: IconButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        size: 19,
                        color: textColor,
                      ),
                      onPressed:
                          () =>
                              context.read<AppPreferencesCubit>().setThemeMode(
                                dark ? ThemeMode.light : ThemeMode.dark,
                              ),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user =
                            snapshot.data ?? FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pushNamed(AppRoute.loginRoute),
                                child: Text(context.tr('sign_in')),
                              ),
                              const SizedBox(width: 6),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accentColor,
                                  foregroundColor: AppColors.white1,
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed:
                                    () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pushNamed(AppRoute.registerRoute),
                                child: Text(context.tr('create_account')),
                              ),
                            ],
                          );
                        }
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: context.tr('my_orders'),
                              style: IconButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                Icons.receipt_long_outlined,
                                size: 19,
                                color: textColor,
                              ),
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(AppRoute.ordersRoute),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: context.tr('settings_title'),
                              style: IconButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                Icons.settings_outlined,
                                size: 19,
                                color: textColor,
                              ),
                              onPressed:
                                  () => Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(AppRoute.settingsRoute),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final items = _navBarsItems(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (ResponsiveLayout.useDesktopNav(constraints.maxWidth)) {
          final pages = const [
            HomePage(),
            CartPage(),
            FavoritesPage(),
            ProfilePage(),
          ];
          return Scaffold(
            body: Column(
              children: [
                _buildDesktopHeader(context),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: PersistentTabView(
            controller: _controller,
            onTabChanged: (index) {
              if (_selectedIndex != index) {
                setState(() => _selectedIndex = index);
              }
            },
            tabs: [
              PersistentTabConfig(item: items[0], screen: const HomePage()),
              PersistentTabConfig(item: items[1], screen: const CartPage()),
              PersistentTabConfig(
                item: items[2],
                screen: const FavoritesPage(),
              ),
              PersistentTabConfig(item: items[3], screen: const ProfilePage()),
            ],
            navBarBuilder:
                (navbarConfig) => Style6BottomNavBar(
                  navBarConfig: navbarConfig,
                  navBarDecoration: NavBarDecoration(
                    color: navBg,
                    border: Border(
                      top: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                ),
            backgroundColor: navBg,
            handleAndroidBackButtonPress: true,
            resizeToAvoidBottomInset: true,
            stateManagement: false,
          ),
        );
      },
    );
  }
}
