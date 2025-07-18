class Apt {
  final String name;
  final double area;
  final String floorInfo;
  final String direction;
  final String roomBath;
  final double price;
  final String address;
  final double lat;
  final double lng;
  final String dong;

  Apt({
    required this.name,
    required this.area,
    required this.floorInfo,
    required this.direction,
    required this.roomBath,
    required this.price,
    required this.address,
    required this.lat,
    required this.lng,
    required this.dong,
  });

  factory Apt.fromJson(Map<String, dynamic> json) {
    return Apt(
      name: json['아파트이름'],
      area: (json['면적']).toDouble(),
      floorInfo: json['층수_총층'],
      direction: json['방향'],
      roomBath: json['방_욕실'],
      price: (json['전세가']).toDouble(),
      address: json['주소'],
      lat: (json['lat']).toDouble(),
      lng: (json['lng']).toDouble(),
      dong: json['동'],
    );
  }
}
