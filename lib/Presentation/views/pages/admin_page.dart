import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/data/datasources/store_api.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
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
    _access = FirebaseAuth.instance.currentUser!
        .getIdTokenResult(true)
        .then((token) => token.claims?['admin'] == true);
  }

  bool _importing = false;

  Future<void> _importDemoCatalog() async {
    setState(() => _importing = true);
    try {
      final result = await StoreApi.instance.request(
        'importDemoCatalog',
        method: 'POST',
      );
      if (mounted) {
        final count = result['created'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.isArabic
                  ? 'منتجات تجريبية جديدة: $count'
                  : 'New demo products: $count',
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
    await showDialog<void>(
      context: context,
      builder:
          (dialog) => StatefulBuilder(
            builder:
                (dialog, setDialog) => AlertDialog(
                  title: Text(
                    context.isArabic
                        ? 'المنتج والمخزون'
                        : 'Product and inventory',
                  ),
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
                              decoration: InputDecoration(labelText: entry.key),
                            ),
                          SwitchListTile(
                            title: Text(
                              context.isArabic
                                  ? 'متاح للبيع'
                                  : 'Available for sale',
                            ),
                            value: active,
                            onChanged: (v) => setDialog(() => active = v),
                          ),
                          SwitchListTile(
                            title: Text(
                              context.isArabic
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
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          saving
                              ? null
                              : () async {
                                setDialog(() => saving = true);
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
                                        fields['price']!.text,
                                      ),
                                      'stock': int.tryParse(
                                        fields['stock']!.text,
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
                      child: const Text('Save'),
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
          return const Center(child: Text('Administrator access required'));
        }
        return Column(
          children: [
            Wrap(
              children: [
                TextButton.icon(
                  onPressed: _importing ? null : _importDemoCatalog,
                  icon: const Icon(Icons.download),
                  label: Text(
                    context.isArabic
                        ? 'استيراد منتجات تجريبية'
                        : 'Import demo products',
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _edit(),
                  icon: const Icon(Icons.add),
                  label: Text(context.isArabic ? 'إضافة منتج' : 'Add product'),
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
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('name')
                        .limit(200)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    children: [
                      for (final doc in snapshot.data!.docs)
                        ListTile(
                          title: Text(doc.data()['name'] ?? doc.id),
                          subtitle: Text(
                            'EGP ${doc.data()['price']} • Stock: ${doc.data()['stock']} • ${doc.data()['active'] == true ? 'Active' : 'Hidden'}',
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _edit({...doc.data(), 'id': doc.id}),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}
