class AptInfo {
  final String id; // mongo id
  final String aptname; // 아파트명
  final String area; // 면적
  final String floor; // 층
  final String way; // 방향
  final String room; // 방 / 욕실 개수
  final String price; // 전세가
  final String address; // 주소
  final double lat; // 위도
  final double lng; // 경도
  final String dong; // 동

  AptInfo(
    {
      required this.id,
      required this.aptname,
      required this.area,
      required this.floor,
      required this.way,
      required this.room,
      required this.price,
      required this.address,
      required this.lat,
      required this.lng,
      required this.dong,
    }
  );


// 서버에서 받은 json -> student로 변환 FatsAPI는 json으로 넘어온다
  factory AptInfo.fromJson(Map<String, dynamic>json){
    return AptInfo(
      id: json["_id"]?? "", 
      aptname: json["아파트이름"]?? "", 
      area: json["면적(m²)"]?? "", 
      floor: json["층수/총 층"]?? "", 
      way: json["방향"]?? "",
      room: json["방/욕실"]?? "",
      price: json["전세가(만원)"]?? "",
      address: json["주소"]?? "",
      lat: json["lat"]?? "",
      lng: json["lng"]?? "",
      dong: json["동"]?? "",
    );
  }





}