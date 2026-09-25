import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/ema_filter.dart';
import 'package:mobile_app/services/reload_fsm.dart';

void main() {
  group('ReloadGestureFsm Unit Tests', () {
    late ReloadGestureFsm fsm;
    late bool reloadTriggered;
    late List<ReloadState> stateHistory;

    setUp(() {
      reloadTriggered = false;
      stateHistory = [];
      fsm = ReloadGestureFsm(
        onReloadComplete: () => reloadTriggered = true,
        onStateChanged: (state) => stateHistory.add(state),
      );
    });

    test('Initial state is IDLE', () {
      expect(fsm.currentState, equals(ReloadState.idle));
    });

    test('Stage 1 transition: Downward wrist flick transitions IDLE -> MAG_EJECTED', () {
      final startTime = DateTime(2026, 9, 24, 12, 0, 0);

      fsm.processSample(
        accel: const Vector3D(0.0, 0.0, 16.5), // > 15.0 m/s^2 spike
        pitchDegrees: 10.0,
        timestamp: startTime,
      );

      expect(fsm.currentState, equals(ReloadState.magEjected));
      expect(stateHistory, equals([ReloadState.magEjected]));
    });

    test('Full Reload Sequence: Complete two-stage gesture triggers reload event', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 500)); // 0.5s later

      // Stage 1: Wrist flick
      fsm.processSample(
        accel: const Vector3D(0.0, 0.0, 18.0),
        pitchDegrees: 5.0,
        timestamp: t0,
      );
      expect(fsm.currentState, equals(ReloadState.magEjected));

      // Stage 2: Upward tilt (> 80 degrees pitch)
      fsm.processSample(
        accel: const Vector3D(0.0, 9.8, 0.0),
        pitchDegrees: 85.0,
        timestamp: t1,
      );

      expect(reloadTriggered, isTrue);
      expect(fsm.currentState, equals(ReloadState.idle)); // Auto-reset after completion
    });

    test('Timeout Guard: Exceeding 1.5 seconds resets MAG_EJECTED back to IDLE', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final tExpired = t0.add(const Duration(milliseconds: 1600)); // > 1.5s later

      // Stage 1: Wrist flick
      fsm.processSample(
        accel: const Vector3D(0.0, 0.0, 16.0),
        pitchDegrees: 0.0,
        timestamp: t0,
      );
      expect(fsm.currentState, equals(ReloadState.magEjected));

      // Attempt Stage 2 after timeout window has expired
      fsm.processSample(
        accel: const Vector3D(0.0, 9.8, 0.0),
        pitchDegrees: 85.0,
        timestamp: tExpired,
      );

      expect(reloadTriggered, isFalse);
      expect(fsm.currentState, equals(ReloadState.idle));
    });

    test('Erratic movement without initial wrist flick does not trigger reload', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);

      // High pitch angle alone without prior wrist flick
      fsm.processSample(
        accel: const Vector3D(2.0, 3.0, 5.0),
        pitchDegrees: 88.0,
        timestamp: t0,
      );

      expect(reloadTriggered, isFalse);
      expect(fsm.currentState, equals(ReloadState.idle));
    });
  });
}