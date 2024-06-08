import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
//import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:new_project/Callback.dart';
import 'package:new_project/Providers/UsernameProvider.dart';
import 'package:new_project/data/AngleData.dart';
import 'package:provider/provider.dart';
//import 'package:new_project/dataUnpacking.dart';
import 'package:screenshot/screenshot.dart';

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

  List<int>? latestKneeData = [];
  List<int>? latestFootData = [];
  List<int>? latestHipsData = [];

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

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

  List<double> footvalueOffset(
    List<double> proxValuesFoot, List<double> distValuesFoot) {
  //double proxValue = 0.0;
  //double distValue = 0.0;
  //double kneeAngle = 0.0;
  List<double> subtractedProxFoot = [];
  List<double> subtractedDistFoot = [];

  // if (proxValues.isNotEmpty && distValues.isNotEmpty) {
  //proxValue = proxValues.average;
  //distValue = distValues.average;
  //kneeAngle = (proxValue - 180) - (distValue - 180);
  proxValuesFoot.forEach((foot_element1) {
    if (foot_element1 > 180.0) {
      foot_element1 = foot_element1 - 360;
    }
    ;
    subtractedProxFoot.add(foot_element1+10);
  });
  distValuesFoot.forEach((foot_element) {
    if (foot_element > 180.0) {
      foot_element = foot_element - 360;
    }
    ;
    //foot_element = foot_element-270;
    subtractedDistFoot.add(foot_element);
  });

  List<double> diffFoot = IterableZip([subtractedProxFoot, subtractedDistFoot])
      .map((foot_pair) => foot_pair[1] - foot_pair[0])
      .toList();

  print(diffFoot);

  return diffFoot;
}

List<double> enforceLimits2(List<double> values, double min, double max) {
  return values.map((value) {
    value = value+75;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }).toList();
}

// sync data

/*
  void processCombinedData() {
    if (kneejson.isNotEmpty && footjson.isNotEmpty && hipsjson.isNotEmpty) {
      if (_isRunning == true) {
        valKnee = kneeangleOffset(kneejson['prox'], kneejson['dist']);
        valFoot = footangleOffset(footjson['prox'], kneejson['dist']);
        valHips = hipangleCalc(hipsjson['prox'], kneejson['prox']);
        //print('valKnee: $valKnee');
        //print('valFoot: $valFoot');
        //print('valHips: $valHips');

        valKnee.forEach(
          (kneeval) {
            _kneedataPoints
                .add(FlSpot(_kneedataPoints.length.toDouble(), kneeval));
          },
        );
        valFoot.forEach(
          (footval) {
            _footdataPoints
                .add(FlSpot(_footdataPoints.length.toDouble(), footval));
          },
        );
        valHips.forEach(
          (hipsval) {
            _hipsdataPoints
                .add(FlSpot(_hipsdataPoints.length.toDouble(), hipsval));
          },
        );
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
          //callback is the old function
          //valKnee = callback(bytes1, deviceType);
          //kneejson returns map
          kneejson = callbackUnpack(bytes1, deviceType);
          //print('Knee: $kneejson');
          if (_isRunning == true) {
            valKnee = kneeangleOffset(kneejson['prox'], kneejson['dist']);
            cleanvalKnee = enforceLimits(valKnee, minKnee, maxKnee);
            //print(knee: $kneejson);

            //print('knee $valKnee');
            cleanvalKnee.forEach(
              (kneeval) {
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), kneeval));
              },
            );
          }
          ;
        });
        //processCombinedData();
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          footjson = callbackUnpack(bytes2, deviceType);
          //print(footjson);

          ///print(kneejson['distal']);
          //print("foot: $footjson");
          if (_isRunning == true) {
            valFoot = footvalueOffset(footjson['prox'], kneejson['dist']);
            cleanvalFoot = enforceLimits2(valFoot, minFoot, maxFoot);

            print('foot $cleanvalFoot');
            cleanvalFoot.forEach(
              (footval) {
                print('footval: $footval');
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), -(footval)));
              },
            );
          }
          ;

          //print('foot: $footjsonData');
          //valFoot = callback(bytes2, deviceType);
          //print(bytes2);q
          //if (_isRunning == true) {
          //final timestampfoot = DateTime.now();
          //_footdataPoints.add(
          //FlSpot(_footdataPoints.length.toDouble(), AngleAve(valFoot)));
          //};
        });
        //processCombinedData();
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
          if (_isRunning == true) {
            valHips = hipangleCalc(hipsjson['prox'], kneejson['dist']);
            //print(valHips);
            cleanvalHips = enforceLimits(valHips, minHips, maxHips);
            //print('foot $valFoot');
            cleanvalHips.forEach(
              (hipsval) {
                _hipsdataPoints
                    .add(FlSpot(_hipsdataPoints.length.toDouble(), hipsval+10));
              },
            );
          }
          ;

          //}
        });
        //processCombinedData();
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
              /*Row(
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
              */
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
