import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorStreamManager{
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  static const Duration _samplingInterval = Duration (milliseconds: 50);

  void startListening({
    required void Function(UserAccelerometerEvent event) onAccel,
    required void Function(GyroscopeEvent event) onGyro
    }) {
      stopListening();

      _accelerometerSubscription = userAccelerometerEventStream(
        samplingPeriod: _samplingInterval,
      ).listen(onAccel);

      _gyroscopeSubscription = gyroscopeEventStream(
        samplingPeriod: _samplingInterval,
      ).listen(onGyro);

    }

    void stopListening(){
      _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _gyroscopeSubscription?.cancel();
      _gyroscopeSubscription = null;
    }

}

