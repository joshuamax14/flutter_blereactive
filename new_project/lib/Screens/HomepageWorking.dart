import 'dart:async';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:new_project/dataUnpacking.dart';
import 'package:screenshot/screenshot.dart';

class HomepageWorking extends StatelessWidget {
  const HomepageWorking({super.key});

  @override
  Widget build(BuildContext context) {
    return BluetoothScreenWorking();
  }
}

class BluetoothScreenWorking extends StatefulWidget {
  const BluetoothScreenWorking({super.key});

  @override
  State<BluetoothScreenWorking> createState() => _BluetoothScreenStateWorking();
}

class _BluetoothScreenStateWorking extends State<BluetoothScreenWorking> {
  final _controller = ScreenshotController();
  final _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSubKnee;
  StreamSubscription<ConnectionStateUpdate>? _connectSubFoot;
  StreamSubscription<ConnectionStateUpdate>? _connectSubHips;
  StreamSubscription<List<int>>? _notifySubKnee;
  StreamSubscription<List<int>>? _notifySubFoot;
  StreamSubscription<List<int>>? _notifySubHips;

  List<int>? latestKneeData = [];
  List<int>? latestFootData = [];
  List<int>? latestHipsData = [];

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

  List<double> valKnee = [];
  List<double> valFoot = [];
  List<double> valHips = [];

  Map<String, dynamic> kneejsonData = {};
  Map<String, dynamic> hipsjsonData = {};
  Map<String, dynamic> footjsonData = {};

  var _valueKnee = 'Scanning for Knee Assembly...';
  var _valueFoot = 'Scanning for Foot Assembly...';
  var _valueHips = 'Scanning for Hips Assembly...';

  List<FlSpot> _kneedataPoints = [];
  List<FlSpot> _footdataPoints = [];
  List<FlSpot> _hipsdataPoints = [];

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
          _ble.subscribeToCharacteristic(characteristic).listen((bytes1) {
        setState(() {
          valKnee = callback(bytes1, deviceType);
          if (_isRunning == true) {
            final timestamp = DateTime.now();
            _kneedataPoints.add(
                FlSpot(_kneedataPoints.length.toDouble(), AngleAve(valKnee)));
          }
          ;
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          valFoot = callback(bytes2, deviceType);
          //print(bytes2);
          if (_isRunning == true) {
            final timestamp = DateTime.now();
            _footdataPoints.add(
                FlSpot(_footdataPoints.length.toDouble(), AngleAve(valFoot)));
          }
          ;
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes3) {
        setState(() {
          valHips = callback(bytes3, deviceType);
          if (_isRunning == true) {
            final timestamp = DateTime.now();
            _hipsdataPoints.add(
                FlSpot(_hipsdataPoints.length.toDouble(), AngleAve(valHips)));
          }
        });
      });
    }
  }

  double AngleAve(List<double> values) {
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

  _captureScreen() {
    _controller.capture().then(
      (Uint8List? image) {
        saveScreenshot(image!);
      },
    );
  }

  saveScreenshot(Uint8List bytes) async {
    final time = DateTime.now();
    final name = 'Screenshot$time';
    await ImageGallerySaver.saveImage(bytes, name: name);
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text('StepGear Demo App'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
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
              const SizedBox(
                width: 20,
                height: 20,
              ),
              ElevatedButton(
                onPressed: _captureScreen,
                child: Text('Save Session'),
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              const Text(
                'Knee Flexion and Extension',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              AspectRatio(
                aspectRatio: 1.8,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _kneedataPoints,
                        isCurved: true,
                        dotData: FlDotData(
                          show: false,
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
              const SizedBox(
                height: 20,
                width: 20,
              ),
              const Text(
                'Ankle Flexion and Extension',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              AspectRatio(
                  aspectRatio: 1.8,
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _footdataPoints,
                        isCurved: true,
                        dotData: FlDotData(
                          show: false,
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
                  ))),
              const SizedBox(
                width: 20,
              ),
              const Text(
                'Hip Flexion and Extension',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              AspectRatio(
                  aspectRatio: 1.8,
                  child: LineChart(LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _hipsdataPoints,
                        isCurved: true,
                        dotData: FlDotData(
                          show: false,
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
                  ))),

              /*_valueFoot.isEmpty
                  ? const CircularProgressIndicator()
                  : Text("Ankle:  $valFoot",
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge),*/ /*
              _valueKnee.isEmpty
                  ? const CircularProgressIndicator()
                  : Text("Knee:  $valKnee",
                      style: Theme.of(context).textTheme.titleLarge),*/
            ],
          ),
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
      ),
    );
  }
}
