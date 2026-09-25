import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/ema_filter.dart';

void main() {
  group('EmaFilter Unit Tests', () {
    test('Vector3D equality and hashCode work correctly', () {
      const v1 = Vector3D(1.0, 2.0, 3.0);
      const v2 = Vector3D(1.0, 2.0, 3.0);
      const v3 = Vector3D(4.0, 5.0, 6.0);

      expect(v1, equals(v2));
      expect(v1 == v3, isFalse);
      expect(v1.hashCode, equals(v2.hashCode));
    });

    test('EmaFilter throws assertion error on invalid alpha', () {
      expect(() => EmaFilter(alpha: 0.0), throwsAssertionError);
      expect(() => EmaFilter(alpha: 1.5), throwsAssertionError);
      expect(() => EmaFilter(alpha: -0.1), throwsAssertionError);
    });

    test('Initial sample seeds the filter without smoothing artifacts', () {
      final filter = EmaFilter(alpha: 0.2);
      const initialSample = Vector3D(9.8, 0.1, -0.2);

      final result = filter.filter(initialSample);
      expect(result, equals(initialSample));
    });

    test('reset clears internal state', () {
      final filter = EmaFilter(alpha: 0.2);
      filter.filter(const Vector3D(10.0, 10.0, 10.0));

      filter.reset();

      // Next value after reset should act as new seed
      const newSeed = Vector3D(1.0, 1.0, 1.0);
      expect(filter.filter(newSeed), equals(newSeed));
    });

    test('Significantly reduces variance on a noisy signal', () {
      final filter = EmaFilter(alpha: 0.15);
      final random = Random(42); // Fixed seed for reproducible test run

      final rawSamples = <Vector3D>[];
      final filteredSamples = <Vector3D>[];

      // Generate 100 noisy samples around baseline 9.8 m/s^2
      for (int i = 0; i < 100; i++) {
        final noiseX = (random.nextDouble() - 0.5) * 2.0; // [-1.0, 1.0]
        final raw = Vector3D(9.8 + noiseX, 0.0, 0.0);

        rawSamples.add(raw);
        filteredSamples.add(filter.filter(raw));
      }

      // Calculate variance on X axis: Sum((x - mean)^2) / N
      final rawMeanX = rawSamples.map((v) => v.x).reduce((a, b) => a + b) / rawSamples.length;
      final rawVarianceX = rawSamples
              .map((v) => pow(v.x - rawMeanX, 2))
              .reduce((a, b) => a + b) /
          rawSamples.length;

      final filteredMeanX = filteredSamples.map((v) => v.x).reduce((a, b) => a + b) / filteredSamples.length;
      final filteredVarianceX = filteredSamples
              .map((v) => pow(v.x - filteredMeanX, 2))
              .reduce((a, b) => a + b) /
          filteredSamples.length;

      // Filtered output variance must be significantly smaller than raw noise variance
      expect(filteredVarianceX, lessThan(rawVarianceX));
      expect(filteredVarianceX / rawVarianceX, lessThan(0.4)); // >60% noise attenuation
    });
  });
}