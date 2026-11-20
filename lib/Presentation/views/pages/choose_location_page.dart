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
  String? _editingId;

  bool _isCompleteAddress(Location address) =>
      address.recipient.trim().isNotEmpty &&
      RegExp(r'^\+?[0-9 ()-]{7,25}$').hasMatch(address.phone.trim()) &&
      address.street.trim().isNotEmpty &&
      address.building.trim().isNotEmpty &&
      address.city.trim().isNotEmpty &&
      address.country.trim().isNotEmpty;

  void _startEditing(Location address) {
    setState(() {
      _editingId = address.id;
      _fields['recipient']!.text = address.recipient;
      _fields['phone']!.text = address.phone;
      _fields['street']!.text = address.street;
      _fields['building']!.text = address.building;
      _fields['unit']!.text = address.unit;
      _fields['city']!.text = address.city;
      _fields['country']!.text = address.country;
      _fields['postalCode']!.text = address.postalCode;
    });
  }

  void _clearForm() {
    for (final c in _fields.values) {
      c.clear();
    }
    if (_editingId != null) {
      setState(() => _editingId = null);
    }
  }

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
    const labelsAr = {
      'recipient': 'اسم المستلم',
      'phone': 'رقم الهاتف',
      'street': 'الشارع',
      'building': 'رقم العمارة',
      'unit': 'الشقة / الدور (اختياري)',
      'city': 'المدينة',
      'country': 'الدولة',
      'postalCode': 'الرمز البريدي (اختياري)',
    };
    const labelsEn = {
      'recipient': 'Recipient Name',
      'phone': 'Phone Number',
      'street': 'Street',
      'building': 'Building',
      'unit': 'Unit / Floor (optional)',
      'city': 'City',
      'country': 'Country',
      'postalCode': 'Postal Code (optional)',
    };
    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'عنوان التوصيل' : 'Delivery address')),
      body: BlocConsumer<ChooseLocationCubit, ChooseLocationState>(
        listener: (context, state) {
          if (state is FetchedLocations) {
            _locations = state.locations;
          }
          if (state is LocationAdded) {
            _clearForm();
          }
          if (state is ConfirmAddressLoaded) {
            Navigator.of(context).pop();
          }
          final error =
              state is LocationAddingFailure
                  ? state.errorMessage
                  : state is ConfirmAddressFailure
                  ? state.errorMessage
                  : state is FetchLocationsFailure
                  ? state.errorMessage
                  : null;
          if (error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(context.trError(error))));
          }
        },
        builder: (context, state) {
          if (state is FetchingLocations && _locations.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_editingId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ar ? 'تعديل العنوان المحدد' : 'Editing saved address',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextButton(
                          onPressed: _clearForm,
                          child: Text(ar ? 'إلغاء التعديل' : 'Cancel edit'),
                        ),
                      ],
                    ),
                  ),
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
                              labelText:
                                  ar
                                      ? labelsAr[entry.key]
                                      : labelsEn[entry.key],
                            ),
                            validator: (value) {
                              if (['unit', 'postalCode'].contains(entry.key)) {
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
                                    : 'Invalid phone number';
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
                            final existing = _locations.where(
                              (loc) => loc.id == _editingId,
                            );
                            await cubit.addLocation(
                              Location(
                                id:
                                    _editingId ??
                                    DateTime.now().microsecondsSinceEpoch
                                        .toString(),
                                isChosen:
                                    existing.isNotEmpty
                                        ? existing.first.isChosen
                                        : false,
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
                  child: Text(
                    _editingId != null
                        ? (ar ? 'تحديث العنوان' : 'Update address')
                        : (ar ? 'حفظ العنوان' : 'Save address'),
                  ),
                ),
                const SizedBox(height: 20),
                for (final address in _locations)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${address.recipient.isNotEmpty ? address.recipient : (ar ? 'عنوان قديم غير مكتمل' : 'Incomplete address')} — ${address.city}, ${address.country}',
                      ),
                      subtitle: Text(
                        _isCompleteAddress(address)
                            ? '${address.street} ${address.building} ${address.unit}\n${address.phone}'
                            : (ar
                                ? 'بيانات العنوان غير مكتملة — اضغط تعديل لإكمالها قبل الطلب'
                                : 'Incomplete details — tap edit to complete before checkout'),
                      ),
                      leading: Icon(
                        cubit.selectedLocationId == address.id
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      onTap: () => cubit.selectLocation(address.id),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: ar ? 'تعديل' : 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _startEditing(address),
                          ),
                          IconButton(
                            tooltip: ar ? 'حذف' : 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => cubit.deleteLocation(address.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed:
                      state is ConfirmAddressLoading
                          ? null
                          : () {
                            final selected = cubit.selectedLocation;
                            if (selected != null &&
                                !_isCompleteAddress(selected)) {
                              _startEditing(selected);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ar
                                        ? 'يرجى استكمال بيانات المستلم ورقم الهاتف والشارع والعمارة أولاً'
                                        : 'Please complete recipient, phone, street and building first',
                                  ),
                                ),
                              );
                              return;
                            }
                            cubit.confirmAddress();
                          },
                  child: Text(ar ? 'تأكيد العنوان' : 'Confirm address'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
