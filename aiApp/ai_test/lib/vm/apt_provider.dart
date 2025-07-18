import 'dart:convert';
import 'package:ai_test/model/apt_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final aptInfoProvider = FutureProvider<List<AptInfo>>((ref) async {
  return await ApiService.fetchGangseoInfos();
});

class ApiService {
  static const baseUrl = 'http://127.0.0.1:8000/hakhyun'; // 실제 IP 주소 또는 도메인
  static const endpoint = '/gangseo_select';

  static Future<List<AptInfo>> fetchGangseoInfos() async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List infos = data['results'];
      return infos.map((e) => AptInfo.fromJson(e)).toList();
    } else {
      throw Exception('데이터 불러오기 실패');
    }
  }
}
