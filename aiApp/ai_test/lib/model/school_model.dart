class SchoolModel {
  final String name;
  final double lat;
  final double lng;

  SchoolModel({required this.name, required this.lat, required this.lng});

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      name: json['학교명'],
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
    );
  }
}
