import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:new_project/DataProcessing.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return BluetoothScreen();
  }
}

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  final _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSubKnee;
  StreamSubscription<ConnectionStateUpdate>? _connectSubFoot;
  StreamSubscription<ConnectionStateUpdate>? _connectSubHips;
  StreamSubscription<List<int>>? _notifySubKnee;
  StreamSubscription<List<int>>? _notifySubFoot;
  StreamSubscription<List<int>>? _notifySubHips;

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

  List<double> valKnee = [];
  List<double> valFoot = [];
  List<double> valHips = [];

  var _valueKnee = 'Scanning for Knee Assembly...';
  var _valueFoot = 'Scanning for Foot Assembly...';
  var _valueHips = 'Scanning for Hips Assembly...';

  List<FlSpot> _dataPoints = [];
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  @override
  void dispose() {
    _notifySubKnee?.cancel();
    _notifySubFoot?.cancel();
    _notifySubHips?.cancel();
    _connectSubKnee?.cancel();
    _connectSubFoot?.cancel();
    _connectSubHips?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  void _onScanUpdate(DiscoveredDevice device) {
    if (device.name == 'KNEESPP_SERVER' && !_foundKnee) {
      _foundKnee = true;
      _connectSubKnee = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'knee');
        }
      });
    } else if (device.name == 'FOOTSPP_SERVER' && !_foundFoot) {
      _foundFoot = true;
      _connectSubFoot = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'foot');
        }
      });
    } else if (device.name == 'HIPSSPP_SERVER' && !_foundHips) {
      _foundHips = true;
      _connectSubHips = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _OnConnected(device.id, 'hips');
        }
      });
    }
  }

  void _OnConnected(String deviceId, String deviceType) {
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
        serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
        deviceId: deviceId);

    if (deviceType == 'knee') {
      _notifySubKnee =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
        setState(() {
          valKnee = callback(bytes, deviceType);
          if (_isRunning == true) {
            _dataPoints.add(
                FlSpot(_dataPoints.length.toDouble(), KneeAngleAve(valKnee)));
          }
          ;
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
        setState(() {
          valFoot = callback(bytes, deviceType);
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
        setState(() {
          valHips = callback(bytes, deviceType);
        });
      });
    }
  }

  double KneeAngleAve(List<double> values) {
    double average = values.average;
    double final_average = double.parse(
      average.toStringAsFixed(2),
    );
    return final_average;
  }

  void _startGeneratingData() {
    setState(() {
      _isRunning = true;
    });
  }

  void _stopGeneratingData() {
    setState(() {
      _isRunning = false;
    });
  }

  void _captureAndSaveImage() {
    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('StepGear Demo App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
            width: 20,
          ),
          AspectRatio(
            aspectRatio: 1.8,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _dataPoints,
                    isCurved: true,
                    dotData: FlDotData(
                      show: true,
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? null : _startGeneratingData,
                child: Text('Start'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _isRunning ? _stopGeneratingData : null,
                child: Text('Stop'),
              ),
            ],
          ),
          SizedBox(
            width: 20,
          ),
          ElevatedButton(
            onPressed: _captureAndSaveImage,
            child: Text('Save Session'),
          ),
        ],
      ),
      /*child: Column(
          mainAxisAlignment: MainAxisAlignment.center, */
      /*children: [
            _valueKnee.isEmpty
                ? const CircularProgressIndicator()
                : Text("Knee:  $valKnee",
                    style: Theme.of(context).textTheme.titleLarge),
            _valueFoot.isEmpty
                ? const CircularProgressIndicator()
                : Text("Ankle:  $valFoot",
                    style: Theme.of(context).textTheme.titleLarge),
            _valueHips.isEmpty
                ? const CircularProgressIndicator()
                : Text("Hips: $valHips",
                    style: Theme.of(context).textTheme.titleLarge),
          ],*/
    );
  }
}
