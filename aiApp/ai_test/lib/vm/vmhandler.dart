import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../model/data.dart'; // Data 클래스 경로에 맞게 수정

final vmProvider = StateNotifierProvider<Vmhandler, AsyncValue<int>>(
    (ref) => Vmhandler(),
    );

    class Vmhandler extends StateNotifier<AsyncValue<int>> {
    Vmhandler() : super(const AsyncValue.data(0));

    Future<void> predict(Data data) async {
        state = const AsyncValue.loading();

        try {
        final res = await http.post(
            Uri.parse("http://127.0.0.1:8000/jiho/predict"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data.toJson()),
        );

        final result = jsonDecode(res.body);

        if (res.statusCode == 200 && result["예측값"] != null) {
            state = AsyncValue.data(result["예측값"]);
        } else {
            state = AsyncValue.error(result["error"] ?? "알 수 없는 오류", StackTrace.current);
        }
        } catch (e, st) {
        state = AsyncValue.error("요청 실패: $e", st);
        }
    }
}