import 'dart:async';
//import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:new_project/DataProcessing.dart';

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

  StreamSubscription<DiscoveredDevice>? _scanSubKnee;
  StreamSubscription<DiscoveredDevice>? _scanSubFoot;
  StreamSubscription<DiscoveredDevice>? _scanSubHips;
  StreamSubscription<ConnectionStateUpdate>? _connectSubKnee;
  StreamSubscription<ConnectionStateUpdate>? _connectSubFoot;
  StreamSubscription<ConnectionStateUpdate>? _connectSubHips;
  StreamSubscription<List<int>>? _notifySubKnee;
  StreamSubscription<List<int>>? _notifySubFoot;
  StreamSubscription<List<int>>? _notifySubHips;
  final Map<String, QualifiedCharacteristic?> _rxCharacteristics = {'knee': null, 'foot': null, 'hips': null};
  final Map<String, StreamSubscription<List<int>>?> _notifySub = {'knee': null, 'foot': null, 'hips': null};

  var _foundKnee = false;
  var _foundFoot = false;
  var _foundHips = false;

  List<dynamic> valKnee = [];
  List<dynamic> valFoot = [];
  List<dynamic> valHips = [];

  List<FlSpot> anglecalcKnee = [];

  bool _isScanning = false;

  var _valueKnee = 'Scanning for Knee Assembly...';
  var _valueFoot = 'Scanning for Foot Assembly...';
  var _valueHips = 'Scanning for Hips Assembly...';

  /*@override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }
*/
  void _startScan() {
    setState(() {
      _isScanning = true;
    });
    _scanSubKnee = _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == 'KNEESPP_SERVER' && !_foundKnee) {
      _foundKnee = true;
      _scanSubKnee?.cancel();
      _OnConnected(device.id, 'knee');
      }
    });
    _scanSubHips = _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == 'HIPSSPP_SERVER' && !_foundHips) {
      _foundHips = true;
      _scanSubHips?.cancel();
       _OnConnected(device.id, 'hips');
      }
    });
    _scanSubFoot= _ble.scanForDevices(withServices: []).listen((device) {
      if (device.name == 'FOOTSPP_SERVER' && !_foundFoot) {
      _foundFoot = true;
      _scanSubFoot?.cancel();
       _OnConnected(device.id, 'foot');
      }
    });
    
  }

  void _OnConnected(String deviceId, String deviceType) {
     if (deviceType == 'knee') {
      _connectSubKnee = _ble.connectToDevice(id: deviceId).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _rxCharacteristics[deviceId]= QualifiedCharacteristic(
          characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
          serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
          deviceId: deviceId);
          _startListening(deviceType);
          }
        else if (update.connectionState == DeviceConnectionState.disconnected) {
       _notifySub[deviceType]?.cancel();
     }
  });
}
     _connectSubFoot = _ble.connectToDevice(id: deviceId).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
           _rxCharacteristics[deviceId]= QualifiedCharacteristic(
            characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
            serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
            deviceId: deviceId);
            _startListening(deviceType);
        }
        else if (update.connectionState == DeviceConnectionState.disconnected) {
          _notifySub[deviceType]?.cancel();
        }
     });
    _connectSubHips = _ble.connectToDevice(id: deviceId).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
           _rxCharacteristics[deviceId]= QualifiedCharacteristic(
            characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
            serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
            deviceId: deviceId);
            _startListening(deviceType);
        }
        else if (update.connectionState == DeviceConnectionState.disconnected) {
          _notifySub[deviceType]?.cancel();
        }
     });
  }
  void _startListening(String deviceType) {
    if (deviceType == 'knee') {
      _notifySubKnee =
          _ble.subscribeToCharacteristic(_rxCharacteristics[deviceType]!).listen((bytes) {
        setState(() {
          valKnee = callback(bytes, deviceType);
        });
      });
    } else if (deviceType == 'foot') {
      _notifySubFoot =
          _ble.subscribeToCharacteristic(_rxCharacteristics[deviceType]!).listen((bytes) {
        setState(() {
          valFoot = callback(bytes, deviceType);
        });
      });
    } else if (deviceType == 'hips') {
      _notifySubHips =
          _ble.subscribeToCharacteristic(_rxCharacteristics[deviceType]!).listen((bytes) {
        setState(() {
          valHips = callback(bytes, deviceType);
        });
      });
    }

  }

  void _stopScan() {
    _scanSubKnee?.cancel();
    _scanSubHips?.cancel();
    _scanSubFoot?.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _notifySubKnee?.cancel();
    _notifySubFoot?.cancel();
    _notifySubHips?.cancel();
    _connectSubKnee?.cancel();
    _connectSubFoot?.cancel();
    _connectSubHips?.cancel();
    _scanSubKnee?.cancel();
    _scanSubHips?.cancel();
    _scanSubFoot?.cancel();
    super.dispose();
  }

  /*void UpdatedevType(String _devtype) {
    globals.devtype = _devtype;
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      /*
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _valueKnee.isEmpty
                ? const CircularProgressIndicator()
                : Text("Knee:  $valKnee",
                    style: Theme.of(context).textTheme.titleLarge),
            LineChart(LineChartData()),
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
    */
    
    body: Column(
      children: [
        Padding(padding: const EdgeInsets.all(8.0),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: 
              )
            ]
          )
        ))
      ],
    ),

    );
  }
}
