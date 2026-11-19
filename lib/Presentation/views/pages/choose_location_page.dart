import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/domain/entities/location.dart';
import 'package:e_commerce_app/Presentation/controller/choose_location_cubit/choose_location_cubit.dart';

class ChooseLocationPage extends StatefulWidget {
  const ChooseLocationPage({super.key});
  @override
  State<ChooseLocationPage> createState() => _ChooseLocationPageState();
}

class _ChooseLocationPageState extends State<ChooseLocationPage> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'recipient',
      'phone',
      'street',
      'building',
      'unit',
      'city',
      'country',
      'postalCode',
    ])
      key: TextEditingController(),
  };
  List<Location> _locations = [];
  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChooseLocationCubit>();
    final ar = context.isArabic;
    const labels = {
      'recipient': 'اسم المستلم',
      'phone': 'رقم الهاتف',
      'street': 'الشارع',
      'building': 'رقم العمارة',
      'unit': 'الشقة / الدور (اختياري)',
      'city': 'المدينة',
      'country': 'الدولة',
      'postalCode': 'الرمز البريدي (اختياري)',
    };
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'عنوان التوصيل' : 'Delivery address')),
      body: BlocConsumer<ChooseLocationCubit, ChooseLocationState>(
        listener: (context, state) {
          if (state is FetchedLocations) {
            _locations = state.locations;
          }
          if (state is LocationAdded) {
            for (final c in _fields.values) {
              c.clear();
            }
          }
          if (state is ConfirmAddressLoaded) {
            Navigator.of(context).pop();
          }
          final error =
              state is LocationAddingFailure
                  ? state.errorMessage
                  : state is ConfirmAddressFailure
                  ? state.errorMessage
                  : null;
          if (error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        },
        builder:
            (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        for (final entry in _fields.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: entry.value,
                              maxLength: 150,
                              keyboardType:
                                  entry.key == 'phone'
                                      ? TextInputType.phone
                                      : TextInputType.text,
                              decoration: InputDecoration(
                                labelText: ar ? labels[entry.key] : entry.key,
                              ),
                              validator: (value) {
                                if ([
                                  'unit',
                                  'postalCode',
                                ].contains(entry.key)) {
                                  return null;
                                }
                                if (value == null || value.trim().isEmpty) {
                                  return ar ? 'هذا الحقل مطلوب' : 'Required';
                                }
                                if (entry.key == 'phone' &&
                                    !RegExp(
                                      r'^\+?[0-9 ()-]{7,25}$',
                                    ).hasMatch(value.trim())) {
                                  return ar
                                      ? 'رقم هاتف غير صحيح'
                                      : 'Invalid phone';
                                }
                                return null;
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        state is AddingLocation
                            ? null
                            : () async {
                              if (!_form.currentState!.validate()) return;
                              String value(String key) =>
                                  _fields[key]!.text.trim();
                              await cubit.addLocation(
                                Location(
                                  id:
                                      DateTime.now().microsecondsSinceEpoch
                                          .toString(),
                                  recipient: value('recipient'),
                                  phone: value('phone'),
                                  street: value('street'),
                                  building: value('building'),
                                  unit: value('unit'),
                                  city: value('city'),
                                  country: value('country'),
                                  postalCode: value('postalCode'),
                                ),
                              );
                            },
                    child: Text(ar ? 'حفظ العنوان' : 'Save address'),
                  ),
                  const SizedBox(height: 20),
                  for (final address in _locations)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${address.recipient} — ${address.city}, ${address.country}',
                        ),
                        subtitle: Text(
                          '${address.street} ${address.building} ${address.unit}\n${address.phone}',
                        ),
                        leading: Icon(
                          cubit.selectedLocationId == address.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                        ),
                        onTap: () => cubit.selectLocation(address.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => cubit.deleteLocation(address.id),
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed:
                        state is ConfirmAddressLoading
                            ? null
                            : () => cubit.confirmAddress(),
                    child: Text(ar ? 'تأكيد العنوان' : 'Confirm address'),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
