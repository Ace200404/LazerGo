import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'services/ema_filter.dart';
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
  Vector3D? _accelData;
  GyroscopeEvent? _gyroData;

  @override
  void initState() {
    super.initState();
    _sensorManager.startListening(
      onAccel: (Vector3D accel) {
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
                    SizedBox(height: screenSize.height * 0.02),
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