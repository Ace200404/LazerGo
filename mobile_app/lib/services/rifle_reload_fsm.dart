import 'ema_filter.dart';

/// States for the Assault Rifle quick horizontal shake gesture.
enum RifleReloadState {
  idle,
  shakeLeft,
  shakeRight,
  reloadComplete,
}

/// Deterministic FSM detecting a rapid horizontal left-to-right shake along the X-axis.
class RifleReloadFsm {
  static const double defaultShakeLeftThreshold = -14.0; // m/s^2 on -X
  static const double defaultShakeRightThreshold = 14.0; // m/s^2 on +X
  static const Duration defaultTimeout = Duration(milliseconds: 500);

  final double shakeLeftThreshold;
  final double shakeRightThreshold;
  final Duration timeoutDuration;

  RifleReloadState _currentState = RifleReloadState.idle;
  DateTime? _shakeLeftTimestamp;

  final void Function()? onReloadComplete;
  final void Function(RifleReloadState state)? onStateChanged;

  RifleReloadFsm({
    this.shakeLeftThreshold = defaultShakeLeftThreshold,
    this.shakeRightThreshold = defaultShakeRightThreshold,
    this.timeoutDuration = defaultTimeout,
    this.onReloadComplete,
    this.onStateChanged,
  });

  RifleReloadState get currentState => _currentState;

  /// Processes incoming acceleration sample to evaluate rifle shake transitions.
  void processSample({
    required Vector3D accel,
    DateTime? timestamp,
  }) {
    final DateTime now = timestamp ?? DateTime.now();

    // Timeout Guard: Check if state timed out during shakeLeft
    if (_currentState == RifleReloadState.shakeLeft && _shakeLeftTimestamp != null) {
      if (now.difference(_shakeLeftTimestamp!) > timeoutDuration) {
        _resetToIdle();
      }
    }

    switch (_currentState) {
      case RifleReloadState.idle:
        // Stage 1: Sharp left shake (-X acceleration <= -14.0 m/s^2)
        if (accel.x <= shakeLeftThreshold) {
          _shakeLeftTimestamp = now;
          _transitionTo(RifleReloadState.shakeLeft);
        }
        break;

      case RifleReloadState.shakeLeft:
        // Stage 2: Sharp right snap-back (+X acceleration >= 14.0 m/s^2)
        if (accel.x >= shakeRightThreshold) {
          _transitionTo(RifleReloadState.shakeRight);
          _transitionTo(RifleReloadState.reloadComplete);
          onReloadComplete?.call();
          _resetToIdle();
        }
        break;

      case RifleReloadState.shakeRight:
      case RifleReloadState.reloadComplete:
        _resetToIdle();
        break;
    }
  }

  void reset() => _resetToIdle();

  void _resetToIdle() {
    _shakeLeftTimestamp = null;
    _transitionTo(RifleReloadState.idle);
  }

  void _transitionTo(RifleReloadState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      onStateChanged?.call(newState);
    }
  }
}