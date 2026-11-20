import 'package:material_ui/material_ui.dart';

enum StoreDepartment { all, fashion, market, living, tech, sports }

class ResponsiveLayout {
  static bool isMobile(double width) => width < 650;
  static bool isTablet(double width) => width >= 650 && width < 1024;
  static bool isDesktop(double width) => width >= 1024;
  static bool useDesktopNav(double width) => width >= 900;

  static int productGridColumns(double width) {
    if (width >= 1320) return 5;
    if (width >= 1024) return 4;
    if (width >= 640) return 3;
    return 2;
  }

  static int categoryGridColumns(double width) {
    if (width >= 1024) return 3;
    if (width >= 640) return 2;
    return 1;
  }

  static const Set<String> _fashionCategories = {
    'mens shirts',
    'mens shoes',
    'mens watches',
    'tops',
    'womens dresses',
    'womens shoes',
    'womens bags',
    'womens jewellery',
    'womens watches',
    'sunglasses',
  };

  static const Set<String> _marketCategories = {
    'groceries',
    'kitchen accessories',
    'beauty',
    'skin care',
    'fragrances',
  };

  static const Set<String> _livingCategories = {'home decoration', 'furniture'};

  static const Set<String> _techCategories = {
    'smartphones',
    'laptops',
    'tablets',
    'mobile accessories',
  };

  static StoreDepartment departmentForCategory(String category) {
    final normalized = category.trim().toLowerCase().replaceAll('-', ' ');
    if (_fashionCategories.contains(normalized)) return StoreDepartment.fashion;
    if (_marketCategories.contains(normalized)) return StoreDepartment.market;
    if (_livingCategories.contains(normalized)) return StoreDepartment.living;
    if (_techCategories.contains(normalized)) return StoreDepartment.tech;
    return StoreDepartment.sports;
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1280,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Align(alignment: Alignment.topCenter, child: content);
  }
}
