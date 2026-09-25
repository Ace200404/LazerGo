import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'services/ema_filter.dart';
import 'services/reload_fsm.dart';
import 'services/sensor_stream_manager.dart';

void main() {
  runApp(const SensorApp());
}

class SensorApp extends StatelessWidget {
  const SensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IMU Sensor Dashboard',
      theme: ThemeData.dark(useMaterial3: true),
      home: const SensorDashboardScreen(),
    );
  }
}

class SensorDashboardScreen extends StatefulWidget {
  const SensorDashboardScreen({super.key});

  @override
  State<SensorDashboardScreen> createState() => _SensorDashboardScreenState();
}

class _SensorDashboardScreenState extends State<SensorDashboardScreen> {
  final SensorStreamManager _sensorManager = SensorStreamManager();
  late final ReloadGestureFsm _reloadFsm;

  Vector3D? _accelData;
  GyroscopeEvent? _gyroData;
  String _gestureStatus = 'IDLE';

  @override
  void initState() {
    super.initState();

    _reloadFsm = ReloadGestureFsm(
      onStateChanged: (state) {
        setState(() {
          _gestureStatus = state.name.toUpperCase();
        });
      },
      onReloadComplete: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚡ MAG REPLENISHED! Tactical Reload Complete!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      },
    );

    _sensorManager.startListening(
      onAccel: (Vector3D accel) {
        // Calculate approximate pitch angle in degrees from acceleration Y-axis
        final double pitchDegrees = (accel.y / 9.8).clamp(-1.0, 1.0) * 90.0;

        _reloadFsm.processSample(
          accel: accel,
          pitchDegrees: pitchDegrees,
        );

        setState(() {
          _accelData = accel;
        });
      },
      onGyro: (GyroscopeEvent gyro) {
        setState(() {
          _gyroData = gyro;
        });
      },
    );
  }

  @override
  void dispose() {
    _sensorManager.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live IMU Telemetry (Filtered)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenSize.width * 0.04,
            vertical: screenSize.height * 0.02,
          ),
          child: Column(
            children: [
              _buildGestureCard(),
              SizedBox(height: screenSize.height * 0.015),
              Expanded(
                child: isLandscape
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildSensorCard(
                              'Filtered Accelerometer (m/s²)',
                              _accelData?.x,
                              _accelData?.y,
                              _accelData?.z,
                              Colors.cyanAccent,
                            ),
                          ),
                          SizedBox(width: screenSize.width * 0.02),
                          Expanded(
                            child: _buildSensorCard(
                              'Gyroscope (rad/s)',
                              _gyroData?.x,
                              _gyroData?.y,
                              _gyroData?.z,
                              Colors.orangeAccent,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _buildSensorCard(
                              'Filtered Accelerometer (m/s²)',
                              _accelData?.x,
                              _accelData?.y,
                              _accelData?.z,
                              Colors.cyanAccent,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.015),
                          Expanded(
                            child: _buildSensorCard(
                              'Gyroscope (rad/s)',
                              _gyroData?.x,
                              _gyroData?.y,
                              _gyroData?.z,
                              Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureCard() {
    Color statusColor;
    switch (_gestureStatus) {
      case 'MAGEJECTED':
        statusColor = Colors.orangeAccent;
        break;
      case 'SLIDEPULLED':
      case 'RELOADCOMPLETE':
        statusColor = Colors.greenAccent;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tactical Reload FSM State',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                border: Border.all(color: statusColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _gestureStatus,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(
      String title, double? x, double? y, double? z, Color accentColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
            ),
            _buildAxisRow('X Axis', x),
            _buildAxisRow('Y Axis', y),
            _buildAxisRow('Z Axis', z),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisRow(String axis, double? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(axis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(
          value != null ? value.toStringAsFixed(3) : '0.000',
          style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}