import 'package:ai_test/model/apt_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final aptListProvider = FutureProvider<List<Apt>>((ref) async {
  final response = await http.get(
    Uri.parse("http://127.0.0.1:8000/inhwan/apts"),
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => Apt.fromJson(json)).toList();
  } else {
    throw Exception("Failed to fetch apartments");
  }
});
