import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/data/datasources/store_api.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/responsive.dart';
import 'orders_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late final Future<bool> _access;
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _access =
        user == null
            ? Future.value(false)
            : user
                .getIdTokenResult(true)
                .then((token) => token.claims?['admin'] == true);
  }

  bool _importing = false;

  Future<void> _syncStoreCatalog() async {
    setState(() => _importing = true);
    try {
      final result = await StoreApi.instance.request(
        'importCatalog',
        method: 'POST',
      );
      if (mounted) {
        final count = result['created'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.isArabic
                  ? 'تمت إضافة $count منتج جديد إلى الكتالوج'
                  : 'Added $count new catalog products',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? product]) async {
    final fields = {
      for (final key in [
        'name',
        'description',
        'category',
        'imgUrl',
        'price',
        'stock',
      ])
        key: TextEditingController(text: '${product?[key] ?? ''}'),
    };
    bool active = product?['active'] == true;
    bool sizes = product?['requiresSize'] == true;
    bool saving = false;
    String? error;
    if (!mounted) return;
    const fieldLabelsAr = {
      'name': 'اسم المنتج',
      'description': 'الوصف',
      'category': 'الفئة',
      'imgUrl': 'رابط الصورة (HTTPS)',
      'price': 'السعر (EGP)',
      'stock': 'المخزون',
    };
    const fieldLabelsEn = {
      'name': 'Product name',
      'description': 'Description',
      'category': 'Category',
      'imgUrl': 'Image URL (HTTPS)',
      'price': 'Price (EGP)',
      'stock': 'Stock',
    };
    final ar = context.isArabic;
    await showDialog<void>(
      context: context,
      builder:
          (dialog) => StatefulBuilder(
            builder:
                (dialog, setDialog) => AlertDialog(
                  title: Text(ar ? 'المنتج والمخزون' : 'Product and inventory'),
                  content: SizedBox(
                    width: 450,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final entry in fields.entries)
                            TextField(
                              controller: entry.value,
                              keyboardType:
                                  ['price', 'stock'].contains(entry.key)
                                      ? TextInputType.number
                                      : TextInputType.text,
                              decoration: InputDecoration(
                                labelText:
                                    ar
                                        ? fieldLabelsAr[entry.key]
                                        : fieldLabelsEn[entry.key],
                              ),
                            ),
                          SwitchListTile(
                            title: Text(
                              ar ? 'متاح للبيع' : 'Available for sale',
                            ),
                            value: active,
                            onChanged: (v) => setDialog(() => active = v),
                          ),
                          SwitchListTile(
                            title: Text(
                              ar
                                  ? 'يتطلب مقاس ملابس'
                                  : 'Requires clothing size',
                            ),
                            value: sizes,
                            onChanged: (v) => setDialog(() => sizes = v),
                          ),
                          if (error != null)
                            Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(dialog),
                      child: Text(context.tr('cancel')),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                setDialog(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  await StoreApi.instance.request(
                                    'product',
                                    method: 'POST',
                                    body: {
                                      if (product != null) 'id': product['id'],
                                      for (final entry in fields.entries)
                                        if (![
                                          'price',
                                          'stock',
                                        ].contains(entry.key))
                                          entry.key: entry.value.text.trim(),
                                      'price': double.tryParse(
                                        fields['price']!.text.trim(),
                                      ),
                                      'stock': int.tryParse(
                                        fields['stock']!.text.trim(),
                                      ),
                                      'active': active,
                                      'requiresSize': sizes,
                                    },
                                  );
                                  if (dialog.mounted) Navigator.pop(dialog);
                                } catch (e) {
                                  if (dialog.mounted) {
                                    setDialog(() {
                                      error = '$e';
                                      saving = false;
                                    });
                                  }
                                }
                              },
                      child: Text(context.tr('save')),
                    ),
                  ],
                ),
          ),
    );
    for (final field in fields.values) {
      field.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.isArabic ? 'إدارة المتجر' : 'Store administration'),
    ),
    body: FutureBuilder<bool>(
      future: _access,
      builder: (context, access) {
        if (!access.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (access.data != true) {
          return Center(
            child: Text(
              context.isArabic
                  ? 'هذه الصفحة متاحة لمدير المتجر فقط'
                  : 'Administrator access required',
            ),
          );
        }
        return ResponsiveContainer(
          maxWidth: 1080,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _importing ? null : _syncStoreCatalog,
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(
                        context.isArabic
                            ? 'مزامنة كتالوج الملابس والماركت'
                            : 'Sync Store Catalog',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add),
                      label: Text(
                        context.isArabic ? 'إضافة منتج' : 'Add product',
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrdersPage(admin: true),
                            ),
                          ),
                      icon: const Icon(Icons.receipt_long),
                      label: Text(
                        context.isArabic ? 'إدارة الطلبات' : 'Manage orders',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('products')
                          .orderBy('name')
                          .limit(300)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        for (final doc in snapshot.data!.docs)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(doc.data()['name'] ?? doc.id),
                              subtitle: Text(
                                context.isArabic
                                    ? 'EGP ${doc.data()['price']} • المخزون: ${doc.data()['stock']} • ${doc.data()['active'] == true ? 'متاح' : 'مخفي'}'
                                    : 'EGP ${doc.data()['price']} • Stock: ${doc.data()['stock']} • ${doc.data()['active'] == true ? 'Active' : 'Hidden'}',
                              ),
                              trailing: const Icon(Icons.edit),
                              onTap: () => _edit({...doc.data(), 'id': doc.id}),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
