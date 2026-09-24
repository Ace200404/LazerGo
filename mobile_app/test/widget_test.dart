import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('SensorApp smoke test loads dashboard title', (WidgetTester tester) async {
    await tester.pumpWidget(const SensorApp());
    expect(find.text('Live IMU Telemetry'), findsOneWidget);
  });
}