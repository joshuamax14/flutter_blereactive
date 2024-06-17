import 'dart:async';
import 'dart:typed_data';

//import 'package:fl_chart/fl_chart.dart';
//import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:new_project/Callback.dart';
import 'package:new_project/data/AngleData.dart';
import 'package:screenshot/screenshot.dart';
import 'package:new_project/global_calib.dart' as globals_calib;

class CalibrationPage extends StatelessWidget {
  const CalibrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BluetoothCalibaration();
  }
}

class BluetoothCalibaration extends StatefulWidget {
  const BluetoothCalibaration({super.key});

  @override
  State<BluetoothCalibaration> createState() => _BluetoothCalibrationState();
}

class _BluetoothCalibrationState extends State<BluetoothCalibaration> {
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

  double valKnee = 0.0;
  double valFoot = -0.0;
  double valHips = 0.0;

  List<double> cleanvalKnee = [];
  List<double> cleanvalFoot = [];
  List<double> cleanvalHips = [];

  Map<String, dynamic> DatakneejsonDataData = {};
  Map<String, dynamic> hipsjsonDataData = {};
  Map<String, dynamic> footjsonDataData = {};

  var _valueKnee = '';
  var _valueFoot = '';
  var _valueHips = '';

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

  void _incrementKneeValue() {
    setState(() {
      globals_calib.incrementKneeValue();
    });
  }

  void _decrementKneeValue() {
    setState(() {
      globals_calib.decrementKneeValue();
    });
  }

  void _incrementFootValue() {
    setState(() {
      globals_calib.incrementFootValue();
    });
  }

  void _decrementFootValue() {
    setState(() {
      globals_calib.decrementFootValue();
    });
  }

  void _incrementHipsValue() {
    setState(() {
      globals_calib.incrementHipsValue();
    });
  }

  void _decrementHipsValue() {
    setState(() {
      globals_calib.decrementHipsValue();
    });
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
          //DatakneejsonData returns map
          kneejsonData = callbackUnpack(bytes1, deviceType);
          //print('Knee: $DatakneejsonData');
          if (_isRunning == true) {
            cleanvalKnee =
                kneeangleOffset(kneejsonData['prox'], kneejsonData['dist']);
            //cleanvalKnee = enforceLimits(valKnee, minKnee, maxKnee);
            //print(knee: $DatakneejsonData);

            //print('knee $valKnee');
            /*
            cleanvalKnee.forEach(
              (kneeval) {
                _kneedataPoints
                    .add(FlSpot(_kneedataPoints.length.toDouble(), kneeval));
              },
            );
            */
            valKnee =
                AngleAveKnee(cleanvalKnee) - globals_calib.currentKneeValue;
            _valueKnee = valKnee.toString();
          }
          ;
        });
        //processCombinedData();
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(characteristic).listen((bytes2) {
        setState(() {
          footjsonData = callbackUnpack(bytes2, deviceType);
          //print(footjsonData);

          //print(DatakneejsonData['distal']);
          //print("foot: $footjsonData");
          if (_isRunning == true) {
            cleanvalFoot =
                footangleOffset(footjsonData['prox'], kneejsonData['dist']);

            //print('foot $cleanvalFoot');

            /*
            cleanvalFoot.forEach(
              (footval) {
                _footdataPoints
                    .add(FlSpot(_footdataPoints.length.toDouble(), (footval)));
              },
            );
          */
            valFoot =
                AngleAveFoot(cleanvalFoot) - globals_calib.currentFootValue;
            _valueFoot = valFoot.toString();
          }
          ;

          //print('foot: $footjsonDataData');
          //valFoot = callback(bytes2, deviceType);
          //print(bytes2);qq
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
          hipsjsonData = callbackUnpack(bytes3, deviceType);
          //print('hips: $hipsjsonData');
          //valHips = callback(bytes3, deviceType);
          //if (_isRunning == true) {
          //final timestamphips = DateTime.now();
          //_hipsdataPoints.add(
          //FlSpot(_hipsdataPoints.length.toDouble(), AngleAve(valHips)));
          if (_isRunning == true) {
            cleanvalHips =
                hipangleCalc(hipsjsonData['prox'], kneejsonData['dist']);
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
            valHips =
                AngleAveHips(cleanvalHips) - globals_calib.currentHipsValue;
            _valueHips = valHips.toString();
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
    });
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
          //backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                height: 20,
                width: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _decrementKneeValue,
                    child: Text('-'),
                  ),
                  Text('Offset Value:'),
                  Text(globals_calib.currentKneeValue.toStringAsFixed(2)),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _incrementKneeValue,
                    child: Text('+'),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              _valueKnee.isEmpty
                  ? const CircularProgressIndicator()
                  : Text("Knee:  $_valueKnee",
                      style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _decrementFootValue,
                    child: Text('-'),
                  ),
                  Text('Offset Value:'),
                  Text(globals_calib.currentFootValue.toStringAsFixed(2)),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _incrementFootValue,
                    child: Text('+'),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              _valueFoot.isEmpty
                  ? const CircularProgressIndicator()
                  : Text("Ankle:  $_valueFoot",
                      style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(
                width: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _decrementHipsValue,
                    child: Text('-'),
                  ),
                  Text('Offset Value:'),
                  Text(globals_calib.currentHipsValue.toStringAsFixed(2)),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _incrementHipsValue,
                    child: Text('+'),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
                width: 20,
              ),
              _valueHips.isEmpty
                  ? const CircularProgressIndicator()
                  : Text("Hips: $_valueHips",
                      style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
