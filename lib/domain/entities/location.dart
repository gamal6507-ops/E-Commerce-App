class Location {
  final String id;
  final String city;
  final String country;
  final String imgUrl;
  final bool isChosen;
  final String recipient;
  final String phone;
  final String street;
  final String building;
  final String unit;
  final String postalCode;

  const Location({
    required this.id,
    required this.city,
    required this.country,
    this.isChosen = false,
    this.recipient = '',
    this.phone = '',
    this.street = '',
    this.building = '',
    this.unit = '',
    this.postalCode = '',
    this.imgUrl =
        'https://previews.123rf.com/images/emojoez/emojoez1903/emojoez190300018/119684277-illustrations-design-concept-location-maps-with-road-follow-route-for-destination-drive-by-gps.jpg',
  });

  Location copyWith({
    String? id,
    String? city,
    String? country,
    String? imgUrl,
    bool? isChosen,
    String? recipient,
    String? phone,
    String? street,
    String? building,
    String? unit,
    String? postalCode,
  }) {
    return Location(
      id: id ?? this.id,
      city: city ?? this.city,
      country: country ?? this.country,
      imgUrl: imgUrl ?? this.imgUrl,
      isChosen: isChosen ?? this.isChosen,
      recipient: recipient ?? this.recipient,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      building: building ?? this.building,
      unit: unit ?? this.unit,
      postalCode: postalCode ?? this.postalCode,
    );
  }
}
