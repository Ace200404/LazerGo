import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock sensors_plus method channel to avoid MissingPluginException in headless test runner
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  testWidgets('SensorApp smoke test loads dashboard title', (WidgetTester tester) async {
    await tester.pumpWidget(const SensorApp());

    // Expect the updated title containing "(Filtered)"
    expect(find.text('Live IMU Telemetry (Filtered)'), findsOneWidget);
  });
}