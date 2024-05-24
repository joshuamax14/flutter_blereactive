import 'dart:async';
//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:new_project/DataProcessing.dart';
import 'globals.dart' as globals;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 24, 48, 225)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'StepGear Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  List<MapEntry<String,dynamic>> valKnee = [];
  List<MapEntry<String,dynamic>> valFoot = [];
  List<MapEntry<String,dynamic>> valHips = [];


  var _valueKnee = 'Scanning for Knee Assembly...';
  var _valueFoot = 'Scanning for Foot Assembly...';
  var _valueHips = 'Scanning for Hips Assembly...';

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

  void UpdatedevType(String _devtype) {
    globals.devtype = _devtype;
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
    UpdatedevType(deviceType);
    final characteristic = QualifiedCharacteristic(
        characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
        serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
        deviceId: deviceId);
    switch (deviceType) {
      case 'knee':
        _notifySubKnee =
            _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
          setState(() {
            valKnee = callback(bytes,deviceType);
          });
        });
        break;
      case 'foot':
        _notifySubFoot =
            _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
          setState(() {
            valFoot = callback(bytes,deviceType);
            ;
          });
        });
        break;
      case 'hips':
        _notifySubHips =
            _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
          setState(() {
            valHips = callback(bytes,deviceType);
            //hello
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
        ),
      ),
    );
  }
}
