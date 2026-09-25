import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'ema_filter.dart';

class SensorStreamManager {
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  final EmaFilter _accelFilter;

  /// Initializes manager with an optional custom [EmaFilter].
  SensorStreamManager({EmaFilter? accelFilter})
      : _accelFilter = accelFilter ?? EmaFilter(alpha: 0.2);

  /// Starts listening to sensor streams.
  /// Converts accelerometer events to filtered [Vector3D] samples.
  void startListening({
    required void Function(Vector3D filteredAccel) onAccel,
    required void Function(GyroscopeEvent gyro) onGyro,
  }) {
    stopListening();
    _accelFilter.reset();

    _accelSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      final rawVector = Vector3D(event.x, event.y, event.z);
      final filteredVector = _accelFilter.filter(rawVector);
      onAccel(filteredVector);
    });

    _gyroSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      onGyro(event);
    });
  }

  /// Cancels active stream subscriptions safely.
  void stopListening() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
  }
}