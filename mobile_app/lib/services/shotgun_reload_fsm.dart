import 'ema_filter.dart';

/// States for the Pump-Action Shotgun racking gesture.
enum ShotgunReloadState {
  idle,
  pumpForward,
  pumpBack,
  reloadComplete,
}

/// Deterministic FSM detecting a two-stage forward-and-back rack along the Z-axis.
class ShotgunReloadFsm {
  static const double defaultForwardThreshold = 12.0; // m/s^2 on +Z
  static const double defaultBackThreshold = -12.0; // m/s^2 on -Z
  static const Duration defaultTimeout = Duration(milliseconds: 600);

  final double forwardThreshold;
  final double backThreshold;
  final Duration timeoutDuration;

  ShotgunReloadState _currentState = ShotgunReloadState.idle;
  DateTime? _forwardTimestamp;

  final void Function()? onReloadComplete;
  final void Function(ShotgunReloadState state)? onStateChanged;

  ShotgunReloadFsm({
    this.forwardThreshold = defaultForwardThreshold,
    this.backThreshold = defaultBackThreshold,
    this.timeoutDuration = defaultTimeout,
    this.onReloadComplete,
    this.onStateChanged,
  });

  ShotgunReloadState get currentState => _currentState;

  /// Processes incoming acceleration sample to evaluate shotgun rack transitions.
  void processSample({
    required Vector3D accel,
    DateTime? timestamp,
  }) {
    final DateTime now = timestamp ?? DateTime.now();

    // Timeout Guard: Check if state timed out during pumpForward
    if (_currentState == ShotgunReloadState.pumpForward && _forwardTimestamp != null) {
      if (now.difference(_forwardTimestamp!) > timeoutDuration) {
        _resetToIdle();
      }
    }

    switch (_currentState) {
      case ShotgunReloadState.idle:
        // Stage 1: Forward pump (+Z acceleration spike >= 12.0 m/s^2)
        if (accel.z >= forwardThreshold) {
          _forwardTimestamp = now;
          _transitionTo(ShotgunReloadState.pumpForward);
        }
        break;

      case ShotgunReloadState.pumpForward:
        // Stage 2: Backward rack (-Z acceleration spike <= -12.0 m/s^2)
        if (accel.z <= backThreshold) {
          _transitionTo(ShotgunReloadState.pumpBack);
          _transitionTo(ShotgunReloadState.reloadComplete);
          onReloadComplete?.call();
          _resetToIdle();
        }
        break;

      case ShotgunReloadState.pumpBack:
      case ShotgunReloadState.reloadComplete:
        _resetToIdle();
        break;
    }
  }

  void reset() => _resetToIdle();

  void _resetToIdle() {
    _forwardTimestamp = null;
    _transitionTo(ShotgunReloadState.idle);
  }

  void _transitionTo(ShotgunReloadState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      onStateChanged?.call(newState);
    }
  }
}