import 'dart:math';
import 'package:vector_math/vector_math_64.dart';

/// Computes spatial orientation unit vectors from 3D Quaternion state.
class OrientationCalculator {
  /// Reference vector pointing along the phone body's longitudinal forward Y-axis.
  static final Vector3 defaultForwardRef = Vector3(0.0, 1.0, 0.0);

  /// Rotates reference vector [referenceForward] by orientation Quaternion [q].
  ///
  /// Implements formula: V_aim = Q * V_ref * Q*
  static Vector3 computeAimVector(
    Quaternion q, {
    Vector3? referenceForward,
  }) {
    final Vector3 ref = referenceForward ?? defaultForwardRef;

    // Normalize Quaternion to ensure unit magnitude (prevents scaling distortion)
    final Quaternion normalizedQ = q.normalized();

    // Rotate reference vector using quaternion multiplication
    return normalizedQ.rotated(ref);
  }

  /// Extracts Pitch (elevation angle) and Yaw (azimuth heading) in radians from an aim vector.
  static ({double pitch, double yaw}) extractAngles(Vector3 aimVector) {
    final Vector3 normalized = aimVector.normalized();

    // Pitch: Elevation above the horizontal X-Y plane [-pi/2, pi/2]
    final double pitch = asin(normalized.z.clamp(-1.0, 1.0));

    // Yaw: Heading direction in the horizontal X-Y plane [-pi, pi]
    final double yaw = atan2(normalized.x, normalized.y);

    return (pitch: pitch, yaw: yaw);
  }
}