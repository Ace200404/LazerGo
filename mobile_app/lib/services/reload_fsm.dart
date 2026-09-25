import 'ema_filter.dart';

/// States representing the stages of the tactical pistol reload gesture.
enum ReloadState {
  idle,
  magEjected,
  slidePulled,
  reloadComplete,
}

/// Deterministic Finite State Machine (FSM) detecting two-stage reload gestures.
class ReloadGestureFsm {
  static const double defaultMagEjectAccelThreshold = 15.0; // m/s^2
  static const double defaultSlidePullPitchThreshold = 80.0; // degrees
  static const Duration defaultTimeout = Duration(milliseconds: 1500);

  final double magEjectAccelThreshold;
  final double slidePullPitchThreshold;
  final Duration timeoutDuration;

  ReloadState _currentState = ReloadState.idle;
  DateTime? _magEjectedTimestamp;

  final void Function()? onReloadComplete;
  final void Function(ReloadState state)? onStateChanged;

  /// Creates a [ReloadGestureFsm] with configurable thresholds and event callbacks.
  ReloadGestureFsm({
    this.magEjectAccelThreshold = defaultMagEjectAccelThreshold,
    this.slidePullPitchThreshold = defaultSlidePullPitchThreshold,
    this.timeoutDuration = defaultTimeout,
    this.onReloadComplete,
    this.onStateChanged,
  });

  /// Current state of the reload state machine.
  ReloadState get currentState => _currentState;

  /// Processes incoming sensor telemetry sample to evaluate state transitions.
  void processSample({
    required Vector3D accel,
    required double pitchDegrees,
    DateTime? timestamp,
  }) {
    final DateTime now = timestamp ?? DateTime.now();

    // Timeout Guard: Check if state timed out in magEjected
    if (_currentState == ReloadState.magEjected && _magEjectedTimestamp != null) {
      if (now.difference(_magEjectedTimestamp!) > timeoutDuration) {
        _resetToIdle();
      }
    }

    switch (_currentState) {
      case ReloadState.idle:
        // Stage 1: Downward wrist flick (Z acceleration spike >= 15 m/s^2)
        if (accel.z.abs() >= magEjectAccelThreshold) {
          _magEjectedTimestamp = now;
          _transitionTo(ReloadState.magEjected);
        }
        break;

      case ReloadState.magEjected:
        // Stage 2: Upward tilt / slide pull (Pitch angle >= 80 degrees)
        if (pitchDegrees.abs() >= slidePullPitchThreshold) {
          _transitionTo(ReloadState.slidePulled);
          _transitionTo(ReloadState.reloadComplete);
          onReloadComplete?.call();
          _resetToIdle();
        }
        break;

      case ReloadState.slidePulled:
      case ReloadState.reloadComplete:
        _resetToIdle();
        break;
    }
  }

  /// Resets state back to [ReloadState.idle].
  void reset() {
    _resetToIdle();
  }

  void _resetToIdle() {
    _magEjectedTimestamp = null;
    _transitionTo(ReloadState.idle);
  }

  void _transitionTo(ReloadState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      onStateChanged?.call(newState);
    }
  }
}