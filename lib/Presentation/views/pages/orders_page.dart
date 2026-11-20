import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/data/datasources/store_api.dart';

class OrdersPage extends StatefulWidget {
  final bool admin;
  const OrdersPage({super.key, this.admin = false});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<Map<String, dynamic>> _orders;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _orders = StoreApi.instance.request('orders', admin: widget.admin);
  }

  Future<void> _change(Map<String, dynamic> order, String status) async {
    String tracking = '';
    if (widget.admin && status == 'shipped') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (dialog) => AlertDialog(
              title: Text(
                context.isArabic ? 'تفاصيل الشحنة' : 'Shipment details',
              ),
              content: TextField(
                keyboardType: TextInputType.url,
                onChanged: (value) => tracking = value.trim(),
                decoration: InputDecoration(
                  labelText:
                      context.isArabic
                          ? 'رابط التتبع (اختياري)'
                          : 'Tracking URL (optional)',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog, false),
                  child: Text(context.isArabic ? 'رجوع' : 'Back'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialog, true),
                  child: Text(context.isArabic ? 'حفظ' : 'Save'),
                ),
              ],
            ),
      );
      if (confirmed != true || !mounted) return;
    }
    try {
      await StoreApi.instance.request(
        'transition',
        method: 'POST',
        body: {
          'orderId': order['id'],
          'userId': order['userId'],
          'status': status,
          if (tracking.isNotEmpty) 'trackingUrl': tracking,
        },
      );
      if (mounted) {
        setState(_load);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.isArabic;
    const statusesAr = {
      'demo': 'طلب تجريبي',
      'pending': 'قيد المراجعة',
      'confirmed': 'تم التأكيد',
      'shipped': 'تم الشحن',
      'delivered': 'تم التوصيل',
      'cancelled': 'ملغي',
      'cancellation_requested': 'طلب إلغاء',
      'return_requested': 'طلب إرجاع',
      'return_approved': 'تم قبول الإرجاع',
      'return_rejected': 'تم رفض الإرجاع',
      'returned': 'تم الاستلام من العميل',
      'closed': 'مغلق',
    };
    const statusesEn = {
      'demo': 'Demo order',
      'pending': 'Pending review',
      'confirmed': 'Confirmed',
      'shipped': 'Shipped',
      'delivered': 'Delivered',
      'cancelled': 'Cancelled',
      'cancellation_requested': 'Cancellation requested',
      'return_requested': 'Return requested',
      'return_approved': 'Return approved',
      'return_rejected': 'Return rejected',
      'returned': 'Returned',
      'closed': 'Closed',
    };
    String labelFor(String status) =>
        (ar ? statusesAr[status] : statusesEn[status]) ?? status;
    const ownerActions = {
      'pending': ['cancelled'],
      'confirmed': ['cancellation_requested'],
      'delivered': ['return_requested'],
    };
    const adminActions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['shipped', 'cancelled'],
      'cancellation_requested': ['cancelled', 'confirmed'],
      'shipped': ['delivered'],
      'delivered': ['return_requested'],
      'return_requested': ['return_approved', 'return_rejected'],
      'return_approved': ['returned'],
      'returned': ['closed'],
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'الطلبات' : 'Orders'),
        actions: [
          IconButton(
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.trError(snapshot.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(_load),
                      child: Text(context.tr('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders =
              (snapshot.data!['orders'] as List).cast<Map<String, dynamic>>();
          if (orders.isEmpty) {
            return Center(
              child: Text(ar ? 'لا توجد طلبات بعد' : 'No orders yet'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final status = order['status'] as String;
              final actions =
                  (widget.admin ? adminActions : ownerActions)[status] ??
                  <String>[];
              final subtotal = order['subtotal'];
              final shipping = order['shipping'];
              final trackingUrl = order['trackingUrl']?.toString();
              return Card(
                child: ExpansionTile(
                  title: Text('#${order['id']}'),
                  subtitle: Text(
                    '${labelFor(status)} • EGP ${order['totalAmount']}',
                  ),
                  children: [
                    ListTile(
                      title: Text(order['shippingAddress'] ?? ''),
                      subtitle: Text(
                        [
                          '${order['createdAt'] ?? ''}',
                          if (subtotal != null && shipping != null)
                            ar
                                ? 'المجموع الفرعي: EGP $subtotal • الشحن: EGP $shipping'
                                : 'Subtotal: EGP $subtotal • Shipping: EGP $shipping',
                          order['paymentMethod'] == 'demo'
                              ? (ar
                                  ? 'تجريبي بدون تحصيل أو شحن'
                                  : 'Demo — no payment or delivery')
                              : (ar
                                  ? 'الدفع عند الاستلام'
                                  : 'Cash on delivery'),
                        ].where((s) => s.isNotEmpty).join('\n'),
                      ),
                    ),
                    for (final item in order['items'] as List)
                      ListTile(
                        title: Text('${item['product']['name']}'),
                        subtitle: Text(
                          [
                            '${item['quantity']} × EGP ${item['product']['price']}',
                            if (item['size'] != null && item['size'] != 'none')
                              '${context.tr('size_label')}: ${item['size']}',
                          ].join(' • '),
                        ),
                      ),
                    if (trackingUrl != null && trackingUrl.isNotEmpty)
                      ListTile(
                        title: Text(
                          ar ? 'رابط تتبع الشحنة' : 'Shipment tracking',
                        ),
                        subtitle: SelectableText(trackingUrl),
                        trailing:
                            trackingUrl.startsWith('https://')
                                ? IconButton(
                                  tooltip: ar ? 'فتح الرابط' : 'Open link',
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed:
                                      () => launchUrl(
                                        Uri.parse(trackingUrl),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                )
                                : null,
                      ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final next in actions)
                          TextButton(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (c) => AlertDialog(
                                      title: Text(
                                        ar
                                            ? 'تأكيد تغيير حالة الطلب؟'
                                            : 'Confirm order action?',
                                      ),
                                      content: Text(labelFor(next)),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(c, false),
                                          child: Text(ar ? 'رجوع' : 'Back'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(c, true),
                                          child: Text(ar ? 'تأكيد' : 'Confirm'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed == true) await _change(order, next);
                            },
                            child: Text(labelFor(next)),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
