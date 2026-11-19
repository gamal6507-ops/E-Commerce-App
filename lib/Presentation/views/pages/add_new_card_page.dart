import 'package:material_ui/material_ui.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';

class AddNewCardPage extends StatelessWidget {
  const AddNewCardPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.isArabic ? 'وسائل الدفع' : 'Payments')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.isArabic
              ? 'الدفع عند الاستلام متاح. الدفع الإلكتروني سيُتاح بعد تفعيل مزوّد الدفع. لا تدخل بيانات بطاقة.'
              : 'Cash on delivery is available. Electronic payments await merchant setup. Do not enter card details.',
        ),
      ),
    ),
  );
}
