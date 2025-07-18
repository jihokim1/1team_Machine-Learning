import 'dart:convert';
import 'package:ai_test/vm/apt_list.dart';
import 'package:ai_test/vm/map.dart';
import 'package:ai_test/vm/riverpod.dart';
import 'package:ai_test/vm/school_list.dart';
import 'package:ai_test/vm/station_list.dart';
import 'package:ai_test/vm/vmhandler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class Home extends ConsumerWidget {
  Home({super.key});

  final floorController = TextEditingController();
  final areaController = TextEditingController();
  final yearController = TextEditingController();
  final receiptYearController = TextEditingController();
  final popupController = PopupController();

  //  동 선택 Dropdown
  final dongList = ['상계동', '월계동', '중계동', '하계동', "공릉동"];
  final ValueNotifier<String> selectedDong = ValueNotifier<String>('상계동');

  Future<void> fetchPrediction(LatLng point, WidgetRef ref) async {
    final url = Uri.parse('http://127.0.0.1:8000/inhwan/predict');
    final body = {
      '층': int.tryParse(floorController.text) ?? 0,
      '임대면적': double.tryParse(areaController.text) ?? 0.0,
      '건축년도': int.tryParse(yearController.text) ?? 0,
      '접수년도': int.tryParse(receiptYearController.text) ?? 0,
      '위도': point.latitude,
      '경도': point.longitude,
    };

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        ref.read(predictionResultProvider.notifier).state = PredictionResult(
          deposit: (data['predicted_보증금'] as num).toDouble(),
          nearestStation: data['nearest_station'],
        );
      } else {
        ref.read(predictionResultProvider.notifier).state = PredictionResult(
          error: '서버 오류: ${res.statusCode}',
        );
      }
    } catch (e) {
      ref.read(predictionResultProvider.notifier).state = PredictionResult(
        error: e.toString(),
      );
    }
  }

  Future<void> fetchPrediction1(LatLng point, WidgetRef ref) async {
    final url = Uri.parse('http://127.0.0.1:8000/hakhyun/sang_predict');
    final body = {
      '층': int.tryParse(floorController.text) ?? 0,
      '임대면적': double.tryParse(areaController.text) ?? 0.0,
      '건축년도': int.tryParse(yearController.text) ?? 0,
      '접수년도': int.tryParse(receiptYearController.text) ?? 0,
      '위도': point.latitude,
      '경도': point.longitude,
    };

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        ref.read(predictionResultProvider.notifier).state = PredictionResult(
          deposit: (data['predicted_보증금'] as num).toDouble(),
          nearestStation: data['nearest_station'],
        );
      } else {
        ref.read(predictionResultProvider.notifier).state = PredictionResult(
          error: '서버 오류: ${res.statusCode}',
        );
      }
    } catch (e) {
      ref.read(predictionResultProvider.notifier).state = PredictionResult(
        error: e.toString(),
      );
    }
  }

  Future<void> fetchPrediction2(LatLng point, WidgetRef ref) async {
    final url = Uri.parse('http://127.0.0.1:8000/jiho/predict');
    final body = {
      '동이름': selectedDong.value,
      '층': int.tryParse(floorController.text) ?? 0,
      '임대면적': double.tryParse(areaController.text) ?? 0.0,
      '건축년도': int.tryParse(yearController.text) ?? 0,
      '접수년도': int.tryParse(receiptYearController.text) ?? 0,
      '위도': point.latitude,
      '경도': point.longitude,
    };

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        ref.read(predictionResultProvider.notifier).state = PredictionResult(
          deposit: (data['predicted_보증금'] as num).toDouble(),
          nearestStation: data['nearest_station'],
        );
      } else {
        ref.read(predictionResultProvider.notifier).state = PredictionResult(
          error: '서버 오류: ${res.statusCode}',
        );
      }
    } catch (e) {
      ref.read(predictionResultProvider.notifier).state = PredictionResult(
        error: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = ref.watch(mapControllerProvider);
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final districtData = ref.watch(districtDataProvider);
    final tappedPoint = ref.watch(tappedMarkerProvider);
    final asyncAptList = ref.watch(aptListProvider);
    final asyncSchoolList = ref.watch(schoolListProvider);
    final asyncStationList = ref.watch(stationListProvider);
    final centerPoint = districtData[selectedDistrict]?['center'] as LatLng?;
    final boundaryPoints =
        districtData[selectedDistrict]?['boundary'] as List<LatLng>?;

    // 선택 구 변경 감지 후 지도 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (centerPoint != null) {
        mapController.move(centerPoint, 13);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('AI 보증금 예측')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            SizedBox(height: 30),
            Text(
              '입력 폼',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: floorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '층'),
            ),
            TextField(
              controller: areaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '임대면적'),
            ),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '건축년도'),
            ),
            TextField(
              controller: receiptYearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '접수년도'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final point = ref.read(tappedMarkerProvider);
                if (point == null) return;
                Navigator.of(context).pop();
                if (selectedDistrict == '강서구') {
                  await fetchPrediction(point, ref);
                } else if (selectedDistrict == '마포구') {
                  await fetchPrediction1(point, ref);
                } else if (selectedDistrict == '노원구') {
                  await fetchPrediction2(point, ref);
                }
                final result = ref.read(predictionResultProvider);
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return Padding(
                      padding: EdgeInsets.all(20),
                      child:
                          result == null
                              ? Text('결과 없음')
                              : result.error != null
                              ? Text('에러: ${result.error}')
                              : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '예측 보증금: ${result.deposit?.toStringAsFixed(0)}만원',
                                  ),
                                  Text('가장 가까운 역: ${result.nearestStation}'),
                                ],
                              ),
                    );
                  },
                );
              },
              child: Text('확인'),
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          return Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: DropdownButton<String>(
                      value: selectedDistrict,
                      items:
                          districtData.keys.map((districtName) {
                            return DropdownMenuItem(
                              value: districtName,
                              child: Text(districtName),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(selectedDistrictProvider.notifier).state =
                              value;
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: selectedDong,
                      builder: (context, value, _) {
                        return DropdownButtonFormField<String>(
                          value: dongList.contains(value) ? value : null,
                          items:
                              dongList
                                  .map(
                                    (dong) => DropdownMenuItem(
                                      value: dong,
                                      child: Text(dong),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null) selectedDong.value = val;
                          },
                          decoration: const InputDecoration(
                            labelText: "동 선택",
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Expanded(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: centerPoint ?? LatLng(37.55, 126.98),
                    initialZoom: 13,
                    onTap: (tapPosition, latlng) {
                      popupController.hideAllPopups();
                      ref.read(tappedMarkerProvider.notifier).state = latlng;
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.myapp',
                    ),
                    if (boundaryPoints != null)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: boundaryPoints,
                            borderStrokeWidth: 5,
                            borderColor: Colors.black,
                          ),
                        ],
                      ),
                    PopupMarkerLayer(
                      options: PopupMarkerLayerOptions(
                        popupController: popupController,
                        markers: [
                          if (tappedPoint != null)
                            Marker(
                              width: 80,
                              height: 80,
                              point: tappedPoint,
                              child: Icon(
                                Icons.location_on,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          ...asyncAptList.when(
                            data:
                                (aptList) =>
                                    aptList.map((apt) {
                                      final point = LatLng(apt.lat, apt.lng);
                                      return Marker(
                                        width: 60,
                                        height: 60,
                                        point: point,
                                        child: GestureDetector(
                                          onTap: () {
                                            ref
                                                .read(
                                                  tappedMarkerProvider.notifier,
                                                )
                                                .state = point;
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (_) {
                                                return Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        apt.name,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text("면적: ${apt.area}㎡"),
                                                      Text(
                                                        "층수: ${apt.floorInfo}",
                                                      ),
                                                      Text(
                                                        "방/욕실: ${apt.roomBath}",
                                                      ),
                                                      Text(
                                                        "방향: ${apt.direction}",
                                                      ),
                                                      Text(
                                                        "전세가: ${apt.price.toStringAsFixed(0)}만원",
                                                      ),
                                                      Text(
                                                        "주소: ${apt.address}",
                                                      ),
                                                      SizedBox(height: 12),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          Scaffold.of(
                                                            context,
                                                          ).openDrawer();
                                                        },
                                                        child: Text(
                                                          "이 위치로 예측하기",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          child: Icon(
                                            Icons.home,
                                            color: Colors.blue,
                                            size: 45,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                          ...asyncSchoolList.when(
                            data:
                                (schoolList) =>
                                    schoolList.map((school) {
                                      late Marker marker;
                                      final point = LatLng(
                                        school.lat,
                                        school.lng,
                                      );
                                      marker = Marker(
                                        key: ValueKey(
                                          'school-${school.name}-${school.lat}-${school.lng}',
                                        ),
                                        point: point,
                                        width: 60,
                                        height: 60,
                                        child: GestureDetector(
                                          onTap: () {
                                            popupController.togglePopup(marker);
                                          },
                                          child: Icon(
                                            Icons.school,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                        ),
                                      );
                                      return marker;
                                    }).toList(),
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                          ...asyncStationList.when(
                            data:
                                (stations) =>
                                    stations.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final station = entry.value;
                                      final point = LatLng(
                                        station.lat,
                                        station.lng,
                                      );
                                      late Marker marker;
                                      marker = Marker(
                                        key: ValueKey(
                                          'station-${station.name}|${station.line}|$index',
                                        ),
                                        point: point,
                                        width: 60,
                                        height: 60,
                                        child: GestureDetector(
                                          onTap: () {
                                            popupController.togglePopup(marker);
                                          },
                                          child: Icon(
                                            Icons.subway,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                      );
                                      return marker;
                                    }).toList(),
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                        ],
                        popupDisplayOptions: PopupDisplayOptions(
                          builder: (context, marker) {
                            final key = marker.key as ValueKey<String>?;
                            final keyValue = key?.value ?? '';
                            String label = '정보 없음';
                            if (keyValue.startsWith('school-')) {
                              label =
                                  keyValue
                                      .replaceFirst('school-', '')
                                      .split('-')
                                      .first;
                            } else if (keyValue.startsWith('station-')) {
                              final parts = keyValue
                                  .replaceFirst('station-', '')
                                  .split('|');
                              if (parts.length >= 2) {
                                final name = parts[0];
                                final line = parts[1];
                                label = '역: $name\n호선: $line';
                              }
                            }
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  label,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
