/// A 3D vector representation for spatial sensor filtering.
class Vector3D {
  final double x;
  final double y;
  final double z;

  const Vector3D(this.x, this.y, this.z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3D &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          z == other.z;

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}

/// An Exponential Moving Average (EMA) Low-Pass Filter for 3D IMU streams.
class EmaFilter {
  final double alpha;
  Vector3D? _previousValue;

  /// Creates an [EmaFilter] with a smoothing factor [alpha] (0.0 < alpha <= 1.0).
  EmaFilter({this.alpha = 0.2}) {
    assert(alpha > 0.0 && alpha <= 1.0,
        'Alpha must be between 0.0 (exclusive) and 1.0 (inclusive)');
  }

  /// Processes a raw [input] vector and returns the smoothed [Vector3D].
  Vector3D filter(Vector3D input) {
    if (_previousValue == null) {
      _previousValue = input;
      return input;
    }

    final double smoothedX = alpha * input.x + (1.0 - alpha) * _previousValue!.x;
    final double smoothedY = alpha * input.y + (1.0 - alpha) * _previousValue!.y;
    final double smoothedZ = alpha * input.z + (1.0 - alpha) * _previousValue!.z;

    final smoothedVector = Vector3D(smoothedX, smoothedY, smoothedZ);
    _previousValue = smoothedVector;
    return smoothedVector;
  }

  /// Resets internal state.
  void reset() {
    _previousValue = null;
  }
}