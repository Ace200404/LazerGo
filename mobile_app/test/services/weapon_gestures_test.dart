import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/ema_filter.dart';
import 'package:mobile_app/services/rifle_reload_fsm.dart';
import 'package:mobile_app/services/shotgun_reload_fsm.dart';

void main() {
  group('ShotgunReloadFsm Unit Tests', () {
    late ShotgunReloadFsm shotgunFsm;
    late bool reloadTriggered;

    setUp(() {
      reloadTriggered = false;
      shotgunFsm = ShotgunReloadFsm(
        onReloadComplete: () => reloadTriggered = true,
      );
    });

    test('Valid Shotgun Rack sequence triggers reload', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 200));

      // Stage 1: Pump Forward (+Z accel)
      shotgunFsm.processSample(
        accel: const Vector3D(0.0, 0.0, 13.5),
        timestamp: t0,
      );
      expect(shotgunFsm.currentState, equals(ShotgunReloadState.pumpForward));

      // Stage 2: Pump Back (-Z accel) within 600ms
      shotgunFsm.processSample(
        accel: const Vector3D(0.0, 0.0, -13.5),
        timestamp: t1,
      );

      expect(reloadTriggered, isTrue);
      expect(shotgunFsm.currentState, equals(ShotgunReloadState.idle));
    });

    test('Shotgun Rack times out if second stage exceeds 600ms', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final tExpired = t0.add(const Duration(milliseconds: 650));

      shotgunFsm.processSample(
        accel: const Vector3D(0.0, 0.0, 13.5),
        timestamp: t0,
      );
      expect(shotgunFsm.currentState, equals(ShotgunReloadState.pumpForward));

      // Attempt second stage after timeout
      shotgunFsm.processSample(
        accel: const Vector3D(0.0, 0.0, -13.5),
        timestamp: tExpired,
      );

      expect(reloadTriggered, isFalse);
      expect(shotgunFsm.currentState, equals(ShotgunReloadState.idle));
    });
  });

  group('RifleReloadFsm Unit Tests', () {
    late RifleReloadFsm rifleFsm;
    late bool reloadTriggered;

    setUp(() {
      reloadTriggered = false;
      rifleFsm = RifleReloadFsm(
        onReloadComplete: () => reloadTriggered = true,
      );
    });

    test('Valid Rifle Shake sequence triggers reload', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 200));

      // Stage 1: Shake Left (-X accel)
      rifleFsm.processSample(
        accel: const Vector3D(-15.0, 0.0, 0.0),
        timestamp: t0,
      );
      expect(rifleFsm.currentState, equals(RifleReloadState.shakeLeft));

      // Stage 2: Snap Right (+X accel) within 500ms
      rifleFsm.processSample(
        accel: const Vector3D(15.0, 0.0, 0.0),
        timestamp: t1,
      );

      expect(reloadTriggered, isTrue);
      expect(rifleFsm.currentState, equals(RifleReloadState.idle));
    });

    test('Rifle Shake times out if second stage exceeds 500ms', () {
      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final tExpired = t0.add(const Duration(milliseconds: 550));

      rifleFsm.processSample(
        accel: const Vector3D(-15.0, 0.0, 0.0),
        timestamp: t0,
      );
      expect(rifleFsm.currentState, equals(RifleReloadState.shakeLeft));

      rifleFsm.processSample(
        accel: const Vector3D(15.0, 0.0, 0.0),
        timestamp: tExpired,
      );

      expect(reloadTriggered, isFalse);
      expect(rifleFsm.currentState, equals(RifleReloadState.idle));
    });
  });

  group('Cross-Trigger Isolation Tests', () {
    test('Shotgun motion does not trigger Rifle FSM', () {
      late RifleReloadFsm rifleFsm;
      bool rifleTriggered = false;

      rifleFsm = RifleReloadFsm(onReloadComplete: () => rifleTriggered = true);

      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 200));

      // Feed full shotgun motion (Z-axis) into Rifle FSM (X-axis)
      rifleFsm.processSample(accel: const Vector3D(0.0, 0.0, 15.0), timestamp: t0);
      rifleFsm.processSample(accel: const Vector3D(0.0, 0.0, -15.0), timestamp: t1);

      expect(rifleTriggered, isFalse);
      expect(rifleFsm.currentState, equals(RifleReloadState.idle));
    });

    test('Rifle motion does not trigger Shotgun FSM', () {
      late ShotgunReloadFsm shotgunFsm;
      bool shotgunTriggered = false;

      shotgunFsm = ShotgunReloadFsm(onReloadComplete: () => shotgunTriggered = true);

      final t0 = DateTime(2026, 9, 24, 12, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 200));

      // Feed full rifle motion (X-axis) into Shotgun FSM (Z-axis)
      shotgunFsm.processSample(accel: const Vector3D(-16.0, 0.0, 0.0), timestamp: t0);
      shotgunFsm.processSample(accel: const Vector3D(16.0, 0.0, 0.0), timestamp: t1);

      expect(shotgunTriggered, isFalse);
      expect(shotgunFsm.currentState, equals(ShotgunReloadState.idle));
    });
  });
}