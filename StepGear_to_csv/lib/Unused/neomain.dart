import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 24, 48, 225)),
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
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  final Map<String, StreamSubscription<ConnectionStateUpdate>?> _connectSubs = {};
  final Map<String, StreamSubscription<List<int>>?> _notifySubs = {};

  final Map<String, String> _deviceStates = {
    'KNEESPP_SERVER': 'Scanning for Knee Assembly...',
    'FOOTSPP_SERVER': 'Scanning for Foot Assembly...',
    'HIPSSPP_SERVER': 'Scanning for Hips Assembly...'
  };

  @override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connectSubs.values.forEach((sub) => sub?.cancel());
    _notifySubs.values.forEach((sub) => sub?.cancel());
    super.dispose();
  }

  void _onScanUpdate(DiscoveredDevice device) {
    if (_deviceStates.containsKey(device.name) && !_connectSubs.containsKey(device.name)) {
      _connectSubs[device.name] = _ble.connectToDevice(id: device.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(device.id, device.name);
        } else if (update.connectionState == DeviceConnectionState.disconnected) {
          setState(() {
            _deviceStates[device.name] = 'Disconnected from ${device.name}';
          });
          _connectSubs.remove(device.name);
        }
      }, onError: (error) {
        setState(() {
          _deviceStates[device.name] = 'Error connecting to ${device.name}: $error';
        });
        _connectSubs.remove(device.name);
      });
    }
  }

  void _onConnected(String deviceId, String deviceType) {
    final characteristic = QualifiedCharacteristic(
      characteristicId: Uuid.parse('0000ABF2-0000-1000-8000-00805F9B34FB'),
      serviceId: Uuid.parse('0000ABF0-0000-1000-8000-00805F9B34FB'),
      deviceId: deviceId,
    );
    _notifySubs[deviceType] = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
      setState(() {
        _deviceStates[deviceType] = const Utf8Decoder().convert(bytes);
      });
    }, onError: (error) {
      setState(() {
        _deviceStates[deviceType] = 'Error receiving data from $deviceType: $error';
      });
      _notifySubs.remove(deviceType);
    });
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
          children: _deviceStates.entries.map((entry) {
            return entry.value.isEmpty
                ? const CircularProgressIndicator()
                : Text(
                    entry.value,
                    style: Theme.of(context).textTheme.titleLarge,
                  );
          }).toList(),
        ),
      ),
    );
  }
}
