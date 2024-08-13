import 'dart:async';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:new_project/Callback.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/data/AngleData.dart';
import 'package:new_project/data/DataNormalization.dart';
import 'package:new_project/data/StartnStop.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'package:moving_average/moving_average.dart';
import 'package:new_project/global_calib.dart' as globals_calib;

class GaitGraph extends StatelessWidget {
  const GaitGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return GaitGraphScreen();
  }
}

class GaitGraphScreen extends StatefulWidget {
  const GaitGraphScreen({super.key});

  @override
  State<GaitGraphScreen> createState() => _GaitGraphScreenState();
}

class _GaitGraphScreenState extends State<GaitGraphScreen> {
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

  List<double> cleanvalKnee = [];
  List<double> cleanvalFoot = [];
  List<double> cleanvalHips = [];

  List<double> AnglesKnee = [];
  List<double> AnglesFoot = [];
  List<double> AnglesHips = [];

  List<double> FilteredAnglesKnee = [];
  List<double> FilteredAnglesFoot = [];
  List<double> FilteredAnglesHips = [];

  List<double> FinalAnglesKnee = [];
  List<double> FinalAnglesFoot = [];
  List<double> FinalAnglesHips = [];

  Map<String, dynamic> kneejson = {};
  Map<String, dynamic> hipsjson = {};
  Map<String, dynamic> footjson = {};

  final kalmanKnee = SimpleKalman(errorMeasure: 10, errorEstimate: 10, q: 0.9);
  final kalmanFoot = SimpleKalman(errorMeasure: 10, errorEstimate: 10, q: 0.9);
  final kalmanHips = SimpleKalman(errorMeasure: 10, errorEstimate: 10, q: 0.9);

// var _valueKnee = 'Scanning for Knee Assembly...';
//  var _valueFoot = 'Scanning for Foot Assembly...';
//  var _valueHips = 'Scanning for Hips Assembly...';

  List<DateTime> kneeTime = [];
  List<DateTime> footTime = [];
  List<DateTime> hipsTime = [];

  List<Map<String, double>> KneeNormalized = [];
  List<Map<String, double>> FootNormalized = [];
  List<Map<String, double>> HipsNormalized = [];

  List<Map<String, double>> FilteredKneeNormalized = [];
  List<Map<String, double>> FilteredFootNormalized = [];
  List<Map<String, double>> FilteredHipsNormalized = [];

  List<DateTime> time_heelstrikes = [];
  List<DateTime> time_hipsheelstrikes = [];

  List<FlSpot> _kneedataPoints = [];
  List<FlSpot> _footdataPoints = [];
  List<FlSpot> _hipsdataPoints = [];

  List<FlSpot> _filteredkneedataPoints = [];
  List<FlSpot> _filteredfootdataPoints = [];
  List<FlSpot> _filteredhipsdataPoints = [];

  List<int> foot_state = [];
  List<int> foot_state_total = [];

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
          await _ble.requestConnectionPriority(
              deviceId: device.id,
              priority: ConnectionPriority.highPerformance);
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
          final timestamp_knee = DateTime.now();
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
                kneeTime.add(timestamp_knee);
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), kneeval));
                _filteredkneedataPoints.add(FlSpot(
                    _filteredkneedataPoints.length.toDouble(),
                    kalmanKnee.filtered(kneeval)));
                AnglesKnee.add(kneeval);
                FilteredAnglesKnee.add(kalmanKnee.filtered(kneeval));
              },
            );

            /*
            _valueKnee =
                AngleAveKnee(cleanvalKnee) + globals_calib.currentKneeValue;
            _kneedataPoints
                .add(FlSpot(_kneedataPoints.length.toDouble(), _valueKnee));

            _filteredkneedataPoints.qadd(FlSpot(
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
          footjson = callbackUnpack(bytes2, deviceType);
          final timestamp_foot = DateTime.now();
          //print(footjson);

          //print(kneejson['distal']);
          //print("foot: $footjson");
          if (_isRunning == true &&
              kneejson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            List<double> foot_prox = footjson['prox'];
            List<double> foot_dist = kneejson['dist'];
            foot_state = footjson['state'];
            cleanvalFoot = footangleOffset(foot_prox, foot_dist);

            //cleanvalFoot = enforceLimits(valFoot, minFoot, maxFoot);

            //print('foot $cleanvalFoot');
            foot_state.forEach(
              (footstate) {
                foot_state_total.add(footstate);
              },
            );

            cleanvalFoot.forEach(
              (footval) {
                footTime.add(timestamp_foot);
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), (footval)));
                _filteredfootdataPoints.add(FlSpot(
                    _filteredfootdataPoints.length.toDouble(),
                    kalmanFoot.filtered(footval)));
                AnglesFoot.add(footval);
                FilteredAnglesFoot.add(kalmanFoot.filtered(footval));
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
          final timestamp_hips = DateTime.now();
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
                hipsTime.add(timestamp_hips);
                _hipsdataPoints
                    .add(FlSpot(_hipsdataPoints.length.toDouble(), hipsval));
                _filteredhipsdataPoints.add(FlSpot(
                    _filteredhipsdataPoints.length.toDouble(),
                    kalmanHips.filtered(hipsval)));
                AnglesHips.add(hipsval);
                FilteredAnglesHips.add(kalmanHips.filtered(hipsval));
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
      print(AnglesKnee.length);
      print(AnglesFoot.length);
      print(AnglesHips.length);
      //print(foot_state_total);
      //FinalAnglesKnee = AnglesKnee.sublist(0, AnglesHips.length - 1);
      //FinalAnglesFoot = AnglesFoot.sublist(0, AnglesHips.length - 1);

      //insert moving average
      final simpleMovingAverage = MovingAverage<double>(
        averageType: AverageType.simple,
        windowSize: 3,
        partialStart: true,
        getValue: (num n) => n,
        add: (List<num> data, num value) => value.toDouble(),
      );

      final movingAverageKnee = simpleMovingAverage(AnglesKnee);
      final movingAverageFoot = simpleMovingAverage(AnglesFoot);
      final movingAverageHips = simpleMovingAverage(AnglesHips);

      time_heelstrikes = Heelstrike(foot_state_total, footTime);
      //time_hipsheelstrikes = Heelstrike(foot_state_total, hipsTime);

      KneeNormalized =
          normalizeGaitCycle(AnglesKnee, kneeTime, time_heelstrikes);
      FootNormalized =
          normalizeGaitCycle(AnglesFoot, footTime, time_heelstrikes);
      HipsNormalized =
          normalizeGaitCycle(AnglesHips, hipsTime, time_heelstrikes);

      FilteredKneeNormalized =
          normalizeGaitCycle(movingAverageKnee, kneeTime, time_heelstrikes);
      FilteredFootNormalized =
          normalizeGaitCycle(movingAverageFoot, footTime, time_heelstrikes);
      FilteredHipsNormalized =
          normalizeGaitCycle(movingAverageHips, hipsTime, time_heelstrikes);

      //print(KneeNormalized);
      //print(FootNormalized);
      //print(HipsNormalized);

      _kneedataPoints.clear();
      _footdataPoints.clear();
      _hipsdataPoints.clear();

      _filteredkneedataPoints.clear();
      _filteredfootdataPoints.clear();
      _filteredhipsdataPoints.clear();

      _kneedataPoints = KneeNormalized.map(
          (data1) => FlSpot(data1['percentage']!, data1['angle']!)).toList();
      _footdataPoints = FootNormalized.map(
          (data2) => FlSpot(data2['percentage']!, data2['angle']!)).toList();
      _hipsdataPoints = HipsNormalized.map(
          (data3) => FlSpot(data3['percentage']!, data3['angle']!)).toList();

      _filteredkneedataPoints = FilteredKneeNormalized.map(
          (data1) => FlSpot(data1['percentage']!, data1['angle']!)).toList();
      _filteredfootdataPoints = FilteredFootNormalized.map(
          (data2) => FlSpot(data2['percentage']!, data2['angle']!)).toList();
      _filteredhipsdataPoints = FilteredHipsNormalized.map(
          (data3) => FlSpot(data3['percentage']!, data3['angle']!)).toList();
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
