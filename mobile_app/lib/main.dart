import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'services/sensor_stream_manager.dart';



void main() {
  runApp(const SensorApp());
}



class SensorApp extends StatelessWidget {
  const SensorApp({super.key});

  // This widget is the root of your application.
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
  UserAccelerometerEvent? _accelEvent;
  GyroscopeEvent? _gyroEvent;

  @override
  void initState() {
    super.initState();
    _sensorManager.startListening(
      onAccel: (event) {
        setState(() {
          _accelEvent = event;
        });
      },
      onGyro: (event) {
        setState(() {
          _gyroEvent = event;
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
    // 1. Get real-time device screen dimensions
    final screenSize = MediaQuery.sizeOf(context);
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live IMU Telemetry'),
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
                    Expanded(child: _buildSensorCard('Accelerometer (m/s²)', _accelEvent?.x, _accelEvent?.y, _accelEvent?.z, Colors.cyanAccent)),
                    SizedBox(width: screenSize.width * 0.02),
                    Expanded(child: _buildSensorCard('Gyroscope (rad/s)', _gyroEvent?.x, _gyroEvent?.y, _gyroEvent?.z, Colors.orangeAccent)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: _buildSensorCard('Accelerometer (m/s²)', _accelEvent?.x, _accelEvent?.y, _accelEvent?.z, Colors.cyanAccent)),
                    SizedBox(height: screenSize.height * 0.02),
                    Expanded(child: _buildSensorCard('Gyroscope (rad/s)', _gyroEvent?.x, _gyroEvent?.y, _gyroEvent?.z, Colors.orangeAccent)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, double? x, double? y, double? z, Color accentColor) {
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
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
        Text(axis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(
          value != null ? value.toStringAsFixed(3) : '0.000',
          style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}