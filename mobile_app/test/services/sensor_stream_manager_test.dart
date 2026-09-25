import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/sensor_stream_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel sensorMethodChannel =
      MethodChannel('dev.fluttercommunity.plus/sensors/method');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sensorMethodChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sensorMethodChannel, null);
  });

  group('SensorStreamManager Tests', () {
    late SensorStreamManager manager;

    setUp(() {
      manager = SensorStreamManager();
    });

    tearDown(() {
      manager.stopListening();
    });

    test('startListening initializes without errors', () {
      expect(
        () => manager.startListening(
          onAccel: (_) {},
          onGyro: (_) {},
        ),
        returnsNormally,
      );
    });

    test('stopListening clears subscriptions safely when called multiple times', () {
      manager.startListening(
        onAccel: (_) {},
        onGyro: (_) {},
      );

      expect(() => manager.stopListening(), returnsNormally);
      expect(() => manager.stopListening(), returnsNormally);
    });
  });
}