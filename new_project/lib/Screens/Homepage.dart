import 'dart:async';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:new_project/Callback.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/data/AngleData.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'package:new_project/global_calib.dart' as globals_calib;

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
  final _controller = ScreenshotController();
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

  double _valueKnee = 0.0;
  double _valueFoot = 0.0;
  double _valueHips = 0.0;

  List<double> valKnee = [];
  List<double> valFoot = [];
  List<double> valHips = [];

  List<double> cleanvalKnee = [];
  List<double> cleanvalFoot = [];
  List<double> cleanvalHips = [];

  Map<String, dynamic> kneejson = {};
  Map<String, dynamic> hipsjson = {};
  Map<String, dynamic> footjson = {};

  final kalmanKnee = SimpleKalman(errorMeasure: 10, errorEstimate: 10, q: 0.9);
  final kalmanFoot = SimpleKalman(errorMeasure: 10, errorEstimate: 10, q: 0.9);
  final kalmanHips = SimpleKalman(errorMeasure: 10, errorEstimate: 10, q: 0.9);

// var _valueKnee = 'Scanning for Knee Assembly...';
//  var _valueFoot = 'Scanning for Foot Assembly...';
//  var _valueHips = 'Scanning for Hips Assembly...';

  List<FlSpot> _kneedataPoints = [];
  List<FlSpot> _footdataPoints = [];
  List<FlSpot> _hipsdataPoints = [];

  List<FlSpot> _filteredkneedataPoints = [];
  List<FlSpot> _filteredfootdataPoints = [];
  List<FlSpot> _filteredhipsdataPoints = [];

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

  void _onScanUpdate(DiscoveredDevice device) async {
    if (device.name == 'KNEESPP_SERVER' && !_foundKnee) {
      _foundKnee = true;
      _connectSubKnee =
          await _ble.connectToDevice(id: device.id).listen((update) async {
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
      _connectSubHips =
          _ble.connectToDevice(id: device.id).listen((update) async {
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
          //callback is the old function
          //valKnee = callback(bytes1, deviceType);
          //kneejson returns map
          kneejson = callbackUnpack(bytes1, deviceType);
          //kneejson = KneeCallbackUnpack(bytes1);
          //print('Knee: $kneejson');
          if (_isRunning == true &&
              footjson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> knee_prox = kneejson['prox'];
            List<double> knee_dist = kneejson['dist'];
            cleanvalKnee = kneeangleOffset(knee_prox, knee_dist);
            //cleanvalKnee = enforceLimits(valKnee, minKnee, maxKnee);
            //print(knee: $kneejson);

            //print('knee $valKnee');

            cleanvalKnee.forEach(
              (kneeval) {
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), kneeval));
                _filteredkneedataPoints.add(FlSpot(
                    _filteredkneedataPoints.length.toDouble(),
                    kalmanKnee.filtered(kneeval)));
              },
            );

            /*
            _valueKnee =
                AngleAveKnee(cleanvalKnee) + globals_calib.currentKneeValue;
            _kneedataPoints
                .add(FlSpot(_kneedataPoints.length.toDouble(), _valueKnee));

            _filteredkneedataPoints.add(FlSpot(
                _filteredkneedataPoints.length.toDouble(),
                kalmanKnee.filtered(_valueKnee)));
                */
          }
          ;
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          //footjson = FootcallbackUnpack(bytes2);
          footjson = callbackUnpack(bytes2, deviceType);

          //print(footjson);

          //print(kneejson['distal']);
          //print("foot: $footjson");
          if (_isRunning == true &&
              kneejson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> foot_prox = footjson['prox'];
            List<double> foot_dist = kneejson['dist'];
            List<int> foot_state = footjson['state'];
            cleanvalFoot = footangleOffset(foot_prox, foot_dist);

            //cleanvalFoot = enforceLimits(valFoot, minFoot, maxFoot);

            //print('foot $cleanvalFoot');

            cleanvalFoot.forEach(
              (footval) {
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), (footval)));
                _filteredfootdataPoints.add(FlSpot(
                    _filteredfootdataPoints.length.toDouble(),
                    kalmanFoot.filtered(footval)));
              },
            );

            /*
            _valueFoot =
                AngleAveFoot(cleanvalFoot) + globals_calib.currentFootValue;
            _footdataPoints
                .add(FlSpot(_footdataPoints.length.toDouble(), _valueFoot));
            _filteredfootdataPoints.add(FlSpot(
                _filteredfootdataPoints.length.toDouble(),
                kalmanFoot.filtered(_valueFoot)));
                */
          }
          ;

          //print('foot: $footjsonData');
          //valFoot = callback(bytes2, deviceType);
          //print(bytes2);qq
          //if (_isRunning == true) {
          //final timestampfoot = DateTime.now();
          //_footdataPoints.add(
          //FlSpot(_footdataPoints.length.toDouble(), AngleAve(valFoot)));
          //};
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes3) {
        setState(() {
          hipsjson = callbackUnpack(bytes3, deviceType);
          //hipsjson = HipscallbackUnpack(bytes3);
          //print('hips: $hipsjson');
          //valHips = callback(bytes3, deviceType);
          //if (_isRunning == true) {
          //final timestamphips = DateTime.now();
          //_hipsdataPoints.add(
          //FlSpot(_hipsdataPoints.length.toDouble(), AngleAve(valHips)));
          if (_isRunning == true &&
              footjson.isNotEmpty &&
              kneejson.isNotEmpty) {
            List<double> hips_prox = hipsjson['prox'];
            List<double> hips_dist = kneejson['prox'];
            cleanvalHips = hipangleCalc(hips_prox, hips_dist);
            //print(valHips);
            //cleanvalHips = enforceLimits(valHips, minHips, maxHips);
            //print('foot $valFoot');

            cleanvalHips.forEach(
              (hipsval) {
                _hipsdataPoints
                    .add(FlSpot(_hipsdataPoints.length.toDouble(), hipsval));
                _filteredhipsdataPoints.add(FlSpot(
                    _filteredhipsdataPoints.length.toDouble(),
                    kalmanHips.filtered(hipsval)));
              },
            );

            /*
            _valueHips =
                AngleAveHips(cleanvalHips) + globals_calib.currentHipsValue;
            _hipsdataPoints
                .add(FlSpot(_hipsdataPoints.length.toDouble(), _valueHips));
            _filteredhipsdataPoints.add(FlSpot(
                _filteredhipsdataPoints.length.toDouble(),
                kalmanHips.filtered(_valueHips)));
                */
          }
          ;

          //}
        });
      });
    }
  }

  void _startGeneratingData() {
    setState(() {
      _isRunning = true;
    });
  }

  void _stopGeneratingData() {
    setState(() {
      _isRunning = false;
      print(_kneedataPoints.length);
      print(_footdataPoints.length);
      print(_hipsdataPoints.length);
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
    final usernameProvider = Provider.of<Usernameprovider>(context);
    return Screenshot(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hello ${usernameProvider.username}! ${DateTime.now()}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.asset('lib/Screens/assets/stepgear.png'),
            )
          ],
          //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
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
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AspectRatio(
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
                        LineChartBarData(
                          color: Colors.red,
                          spots: _filteredkneedataPoints,
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
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _footdataPoints,
                          isCurved: true,
                          dotData: FlDotData(
                            show: false,
                          ),
                        ),
                        LineChartBarData(
                          color: Colors.red,
                          spots: _filteredfootdataPoints,
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
              ),
              const SizedBox(
                height: 20,
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
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: _hipsdataPoints,
                          isCurved: true,
                          dotData: FlDotData(
                            show: false,
                          ),
                        ),
                        LineChartBarData(
                          color: Colors.red,
                          spots: _filteredhipsdataPoints,
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
              ),
              const SizedBox(
                height: 100,
                width: 20,
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _isRunning ? null : _startGeneratingData,
              child: Text('Start'),
            ),
            SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _isRunning ? _stopGeneratingData : null,
              child: Text('Stop'),
            ),
            SizedBox(width: 20),
            FloatingActionButton(
              onPressed: _captureScreen,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
