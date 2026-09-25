import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/orientation_calculator.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('OrientationCalculator Unit Tests', () {
    test('Identity Quaternion yields untouched reference aim vector [0, 1, 0]', () {
      final identityQ = Quaternion.identity();

      final aimVector = OrientationCalculator.computeAimVector(identityQ);

      expect(aimVector.x, closeTo(0.0, 1e-5));
      expect(aimVector.y, closeTo(1.0, 1e-5));
      expect(aimVector.z, closeTo(0.0, 1e-5));
    });

    test('Pitch 90 degrees around X-axis rotates aim vector downward [0, 0, -1]', () {
      // 90 degrees rotation around X-axis
      final pitch90Q = Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), pi / 2);

      final aimVector = OrientationCalculator.computeAimVector(pitch90Q);

      expect(aimVector.x, closeTo(0.0, 1e-5));
      expect(aimVector.y, closeTo(0.0, 1e-5));
      expect(aimVector.z, closeTo(-1.0, 1e-5));
    });

    test('Yaw 90 degrees around Z-axis rotates aim vector toward X-axis [1, 0, 0]', () {
      // 90 degrees rotation around vertical Z-axis
      final yaw90Q = Quaternion.axisAngle(Vector3(0.0, 0.0, 1.0), pi / 2);

      final aimVector = OrientationCalculator.computeAimVector(yaw90Q);

      expect(aimVector.x, closeTo(1.0, 1e-5));
      expect(aimVector.y, closeTo(0.0, 1e-5));
      expect(aimVector.z, closeTo(0.0, 1e-5));
    });

    test('Roll around Y-axis preserves forward aim vector direction', () {
      // 90 degrees roll around longitudinal Y-axis
      final roll90Q = Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), pi / 2);

      final aimVector = OrientationCalculator.computeAimVector(roll90Q);

      expect(aimVector.x, closeTo(0.0, 1e-5));
      expect(aimVector.y, closeTo(1.0, 1e-5));
      expect(aimVector.z, closeTo(0.0, 1e-5));
    });

    test('extractAngles computes pitch and yaw correctly from aim vector', () {
      final aimVector = Vector3(0.0, 1.0, 0.0); // Facing straight ahead horizontally

      final angles = OrientationCalculator.extractAngles(aimVector);

      expect(angles.pitch, closeTo(0.0, 1e-5));
      expect(angles.yaw, closeTo(0.0, 1e-5));
    });
  });
}