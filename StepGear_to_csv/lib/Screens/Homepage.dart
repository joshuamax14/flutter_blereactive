import 'dart:async';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:new_project/Callback.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/data/AngleData.dart';
import 'package:provider/provider.dart';
import 'package:simple_kalman/simple_kalman.dart';
import 'package:to_csv/to_csv.dart' as exportCSV;

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

  List<int>? latestKneeData = [];
  List<int>? latestFootData = [];
  List<int>? latestHipsData = [];

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

  double _valueKnee = 0.0;
  double _valueFoot = 0.0;
  double _valueHips = 0.0;

  double minKnee = -10.0;
  double maxKnee = 150.0;
  double minFoot = -40.0;
  double maxFoot = 40.0;
  double minHips = -30.0;
  double maxHips = 60.0;

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

  List<List<String>> knee_listOfLists = [];
  List<List<String>> foot_listOfLists = [];
  List<List<String>> hips_listOfLists = [];

  List<List<String>> listOfLists = [];

  List<String> data1 = [];
  List<String> data2 = [];
  List<String> data3 = [];
  List<String> data4 = [];

  List<String> header = [
    'knee time',
    'state',
    'prox',
    'dist',
    'computed angle',
    'foot time',
    'state',
    'prox',
    'dist',
    'computed angle',
    'hips time',
    'state',
    'prox',
    'dist',
    'computed angle'
  ];

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
          //callback is the old function
          //valKnee = callback(bytes1, deviceType);
          //kneejson returns map
          kneejson = callbackUnpack(bytes1, deviceType);
          //print('Knee: $kneejson');
          if (_isRunning == true &&
              footjson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            final timestamp_knee = DateTime.now();
            List<double> knee_prox = kneejson['prox'];
            List<double> knee_dist = kneejson['dist'];
            cleanvalKnee = kneeangleOffset(knee_prox, knee_dist);
            for (var k = 0; k < 4; k++) {
              data3 = [
                timestamp_knee.toString(),
                '0',
                knee_prox[k].toStringAsFixed(2),
                knee_dist[k].toStringAsFixed(2),
                cleanvalKnee[k].toStringAsFixed(2)
              ];
              knee_listOfLists.add(data3);
            }
            ;
            //cleanvalKnee = enforceLimits(valKnee, minKnee, maxKnee);
            //print(knee: $kneejson);

            //print('knee $valKnee');
            /*
            cleanvalKnee.forEach(
              (kneeval) {
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), kneeval));
              },
            );
            */
            _valueKnee = AngleAveKnee(cleanvalKnee);
            _kneedataPoints
                .add(FlSpot(_kneedataPoints.length.toDouble(), _valueKnee));

            _filteredkneedataPoints.add(FlSpot(
                _filteredkneedataPoints.length.toDouble(),
                kalmanKnee.filtered(_valueKnee)));
          }
          ;
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          footjson = callbackUnpack(bytes2, deviceType);
          //print(footjson);

          //print(kneejson['distal']);
          //print("foot: $footjson");
          if (_isRunning == true &&
              kneejson.isNotEmpty &&
              hipsjson.isNotEmpty) {
            final timestamp_foot = DateTime.now();
            List<double> foot_prox = footjson['prox'];
            List<double> foot_dist = kneejson['dist'];
            List<int> foot_state = footjson['state'];
            cleanvalFoot = footangleOffset(foot_prox, foot_dist);
            for (var i1 = 0; i1 < 4; i1++) {
              data2 = [
                timestamp_foot.toString(),
                foot_state[i1].toString(),
                foot_prox[i1].toStringAsFixed(2),
                foot_dist[i1].toStringAsFixed(2),
                cleanvalFoot[i1].toStringAsFixed(2)
              ];
              foot_listOfLists.add(data2);
            }
            ;

            //cleanvalFoot = enforceLimits(valFoot, minFoot, maxFoot);

            print('foot $cleanvalFoot');

            /*
            cleanvalFoot.forEach(
              (footval) {
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), (footval)));
              },
            );
          */
            _valueFoot = AngleAveFoot(cleanvalFoot);
            _footdataPoints
                .add(FlSpot(_footdataPoints.length.toDouble(), _valueFoot));
            _filteredfootdataPoints.add(FlSpot(
                _filteredfootdataPoints.length.toDouble(),
                kalmanFoot.filtered(_valueFoot)));
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
          //print('hips: $hipsjson');
          //valHips = callback(bytes3, deviceType);
          //if (_isRunning == true) {
          //final timestamphips = DateTime.now();
          //_hipsdataPoints.add(
          //FlSpot(_hipsdataPoints.length.toDouble(), AngleAve(valHips)));
          if (_isRunning == true &&
              footjson.isNotEmpty &&
              kneejson.isNotEmpty) {
            final timestamphips = DateTime.now();
            List<double> hips_prox = hipsjson['prox'];
            List<double> hips_dist = kneejson['prox'];
            cleanvalHips = hipangleCalc(hips_prox, hips_dist);
            for (var i = 0; i < 4; i++) {
              data1 = [
                timestamphips.toString(),
                '0',
                hips_prox[i].toStringAsFixed(2),
                hips_dist[i].toStringAsFixed(2),
                cleanvalHips[i].toStringAsFixed(2)
              ];
              hips_listOfLists.add(data1);
            }
            ;
            //print(valHips);
            //cleanvalHips = enforceLimits(valHips, minHips, maxHips);
            //print('foot $valFoot');
            /*
            cleanvalHips.forEach(
              (hipsval) {
                _hipsdataPoints.add(
                    FlSpot(_hipsdataPoints.length.toDouble(), hipsval + 10));
              },
            );
            */
            _valueHips = AngleAveHips(cleanvalHips);
            _hipsdataPoints
                .add(FlSpot(_hipsdataPoints.length.toDouble(), _valueHips));
            _filteredhipsdataPoints.add(FlSpot(
                _filteredhipsdataPoints.length.toDouble(),
                kalmanHips.filtered(_valueHips)));
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
      for (var j = 0; j < knee_listOfLists.length - 1; j++) {
        data4 = knee_listOfLists[j] + foot_listOfLists[j] + hips_listOfLists[j];
        listOfLists.add(data4);
      }
      ;
      print(listOfLists);
      exportCSV.myCSV(header, listOfLists);
      //kneejsonData = {};
      //hipsjsonData = {};
      //footjsonData = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final usernameProvider = Provider.of<Usernameprovider>(context);
    return Scaffold(
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
            /*
              const SizedBox(
                width: 20,
                height: 20,
              ),
              ElevatedButton(
                onPressed: _captureScreen,
                child: Text('Save Session'),
              ),
              */
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
        ],
      ),
    );
  }
}
