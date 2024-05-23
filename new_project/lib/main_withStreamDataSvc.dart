import 'dart:async';
import 'dart:convert';
import 'dart:io';
//import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
//import 'bleSvc.dart' as svc;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

  var _valueKnee = 'Scanning for Knee Assembly...';
  var _valueFoot = 'Scanning for Foot Assembly...';
  var _valueHips = 'Scanning for Hips Assembly...';
  var kneejsonData_str = "Knee Assembly Json Data"; 
  var footjsonData_str = "Foot Assembly Json Data"; 
  var hipsjsonData_str = "Foot Assembly Json Data";



  Map<String, dynamic>? _kneeData;
  Map<String, dynamic>? _footData;
  Map<String, dynamic>? _hipsData;

  late Set<Map<String, dynamic>> kneejsonData;
  late Set<Map<String, dynamic>> footjsonData;
  late Set<Map<String, dynamic>> hipsjsonData;

  @override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
    _loadData();
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
    switch (deviceType) {
      case 'knee':
        _notifySubKnee =
            _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
          setState(() {
            _valueKnee = const Utf8Decoder().convert(bytes);
            //kneejsonData = svc.BLEManager().callback(bytes, deviceType);
          });
        });
        break;
      case 'foot':
        _notifySubFoot =
            _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
          setState(() {
            _valueFoot = const Utf8Decoder().convert(bytes);
            //footjsonData = svc.BLEManager().callback(bytes, deviceType);
          });
        });
        break;
      case 'hips':
        _notifySubHips =
            _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
          setState(() {
            _valueHips = const Utf8Decoder().convert(bytes);
            //hipsjsonData = svc.BLEManager().callback(bytes, deviceType);
          });
        });
        break;
    }
    //return {kneejsonData, footjsonData, hipsjsonData};
  }

  Future<void> _loadData() async {
    var kneeData = await neoReadKneeAngles();
    var footData = await neoReadFootAngles();
    var hipsData = await neoReadHipsAngles();
    setState(() {
      _kneeData = kneeData;
      _footData = footData;
      _hipsData = hipsData;
    });
  }

  List<double> npAsArray(List<dynamic> list) {
    return list
        .map((e) => e is double ? e : double.parse(e.toString()))
        .toList();
  }

  Future<Map<String, dynamic>> neoReadKneeAngles() async {
    Map<String, dynamic> kneedecodedArrays = {};
    List<double> prox = [];
    List<double> dist = [];
    List<double> state = [];
    int counter = 0;

    try {
      final file = File('./knee');
      final decodedArrays = jsonDecode(await file.readAsString());
      counter = decodedArrays["counter"];
      state = npAsArray(decodedArrays["state"]);
      prox = npAsArray(decodedArrays["prox"]);
      dist = npAsArray(decodedArrays["dist"]);
    } catch (e) {
      print("error occurred while trying to read data: $kneedecodedArrays");
    }

    return {"counter": counter, "prox": prox, "dist": dist, "state": state};
  }

  Future<Map<String, dynamic>> neoReadFootAngles() async {
    Map<String, dynamic> footdecodedArrays = {};
    List<double> prox = [];
    List<double> state = [];
    int counter = 0;

    try {
      final file = File('./foot');
      final decodedArrays = jsonDecode(await file.readAsString());
      counter = decodedArrays["counter"];
      state = npAsArray(decodedArrays["state"]);
      prox = npAsArray(decodedArrays["prox"]);
    } catch (e) {
      print("error occurred while trying to read data: $footdecodedArrays");
    }

    return {"counter": counter, "prox": prox, "state": state};
  }

  Future<Map<String, dynamic>> neoReadHipsAngles() async {
    Map<String, dynamic> hipsdecodedArrays = {};
    List<double> prox = [];
    List<double> state = [];
    int counter = 0;

    try {
      final file = File('./hips');
      final decodedArrays = jsonDecode(await file.readAsString());
      counter = decodedArrays["counter"];
      state = npAsArray(decodedArrays["state"]);
      prox = npAsArray(decodedArrays["prox"]);
    } catch (e) {
      print("error occurred while trying to read data: $hipsdecodedArrays");
    }

    return {"counter": counter, "prox": prox, "state": state};
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
              : Text("Knee: " + _valueKnee,
                  style: Theme.of(context).textTheme.titleLarge),
          _valueFoot.isEmpty
              ? const CircularProgressIndicator()
              : Text("Ankle: " + _valueFoot,
                  style: Theme.of(context).textTheme.titleLarge),
          _valueHips.isEmpty
              ? const CircularProgressIndicator()
              : Text("Hips: " + _valueHips,
                  style: Theme.of(context).textTheme.titleLarge),
          _kneeData == null
              ? const CircularProgressIndicator()
              //: Text("Knee Data: ${_kneeData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
              : Text("Knee Data: ${kneejsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
          _footData == null
              ? const CircularProgressIndicator()
              //: Text("Foot Data: ${_footData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
              : Text("Foot Data: ${footjsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
          _hipsData == null
              ? const CircularProgressIndicator()
              //: Text("Hips Data: ${_hipsData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
              : Text("Hips Data: ${hipsjsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
        ],
      )),
    );
  }
}
