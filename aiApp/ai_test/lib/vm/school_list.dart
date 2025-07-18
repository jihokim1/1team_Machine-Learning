import 'package:ai_test/model/school_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final schoolListProvider = FutureProvider<List<SchoolModel>>((ref) async {
  final response = await http.get(
    Uri.parse("http://127.0.0.1:8000/inhwan/schools"),
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = json.decode(response.body);
    return jsonList.map((json) => SchoolModel.fromJson(json)).toList();
  } else {
    throw Exception("Failed to fetch schools");
  }
});
