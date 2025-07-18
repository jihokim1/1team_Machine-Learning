import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationState {
  final bool canRun;
  final Position? position;

  LocationState({this.canRun = false, this.position});
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    _checkPermissionAndFetch();
  }

  Future<void> _checkPermissionAndFetch() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final pos = await Geolocator.getCurrentPosition();
      state = LocationState(canRun: true, position: pos);
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);

final tappedMarkerProvider = StateProvider<LatLng?>((ref) => null);

// 예측 결과 상태
class PredictionResult {
  final double? deposit;
  final String? nearestStation;
  final String? error;

  PredictionResult({this.deposit, this.nearestStation, this.error});
}

final predictionResultProvider = StateProvider<PredictionResult?>(
  (ref) => null,
);
