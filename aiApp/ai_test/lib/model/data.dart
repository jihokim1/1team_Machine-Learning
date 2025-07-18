class Data {
  final String dong;
  final int year;
  final int floor;
  final double area;
  final int builtYear;
  final double distance;
  final double schoolDistance;
  final int supplyStatus;
  final int contractType;

  Data({
    required this.dong,
    required this.year,
    required this.floor,
    required this.area,
    required this.builtYear,
    required this.distance,
    required this.schoolDistance,
    required this.supplyStatus,
    required this.contractType,
  });

  Map<String, dynamic> toJson() => {
        "동이름": dong,
        "접수년도": year,
        "층": floor,
        "임대면적": area,
        "건축년도": builtYear,
        "거리_m": distance,
        "학교거리_m": schoolDistance,
        "수급동향": supplyStatus,
        "신규계약구분_num": contractType,
      };
}