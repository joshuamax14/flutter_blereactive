import 'dart:async';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:new_project/Screens/Intropage.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/data/kneeAngleData.dart';
import 'package:new_project/dataUnpacking.dart';
import 'package:screenshot/screenshot.dart';

class Homepage2 extends StatelessWidget {
  const Homepage2({super.key});

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
  var username = Usernameprovider().username ;

  List<double> valKnee = [];
  List<double> valFoot = [];
  List<double> valHips = [];

  Map<String, dynamic> kneejsonData = {};
  Map<String, dynamic> hipsjsonData = {};
  Map<String, dynamic> footjsonData = {};

// var _valueKnee = 'Scanning for Knee Assembly...';
//  var _valueFoot = 'Scanning for Foot Assembly...';
//  var _valueHips = 'Scanning for Hips Assembly...';

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

/*
  void processCombinedData() {
    if (kneejsonData.isNotEmpty &&
        footjsonData.isNotEmpty &&
        hipsjsonData.isNotEmpty) {
      if (_isRunning == true) {
        valKnee = kneeangleOffset(kneejsonData['prox'], kneejsonData['dist']);
        valFoot = footangleOffset(footjsonData['prox']);
        valHips = hipangleCalc(hipsjsonData['prox'], kneejsonData['prox']);
        //print('valKnee: $valKnee');
        //print('valFoot: $valFoot');
        //print('valHips: $valHips');
        _kneedataPoints
            .add(FlSpot(_kneedataPoints.length.toDouble(), AngleAve(valKnee)));
        _footdataPoints
            .add(FlSpot(_footdataPoints.length.toDouble(), AngleAve(valFoot)));
        _hipsdataPoints
            .add(FlSpot(_hipsdataPoints.length.toDouble(), AngleAve(valHips)));
      }
    }
  }
*/
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
          //kneejsonData = callbackUnpack(bytes1, deviceType);
          //print('KNEE: $kneejsonData');
          if (_isRunning == true) {
            //final timestampknee = DateTime.now();
            _kneedataPoints.add(
                FlSpot(_kneedataPoints.length.toDouble(), AngleAve(valKnee)));
          }
          ;
        });
        //processCombinedData();
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          //footjsonData = callbackUnpack(bytes2, deviceType);
          //print('foot: $footjsonData');
          valFoot = callback(bytes2, deviceType);
          print(bytes2);
          if (_isRunning == true) {
            //final timestampfoot = DateTime.now();
            _footdataPoints.add(
                FlSpot(_footdataPoints.length.toDouble(), AngleAve(valFoot)));
          }
          ;
        });
        //processCombinedData();
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes3) {
        setState(() {
          //hipsjsonData = callbackUnpack(bytes3, deviceType);
          //print('hips: $hipsjsonData');
          valHips = callback(bytes3, deviceType);
          if (_isRunning == true) {
            //final timestamphips = DateTime.now();
            _hipsdataPoints.add(
                FlSpot(_hipsdataPoints.length.toDouble(), AngleAve(valHips)));
          }
        });
        //processCombinedData();
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
      //kneejsonData = {};
      //hipsjsonData = {};
      //footjsonData = {};
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
          title: Text('Hello $username!'),
          actions: [
            Padding(padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('lib/Screens/assets/stepgear.png'),
            )
          ],
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
