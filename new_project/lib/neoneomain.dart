import 'dart:async';
import 'dart:convert';
import 'dart:io';
//import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'bleSvc.dart' as svc;

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
  List<dynamic> rawKnee = [0,0,0,0];
  List<dynamic> rawFoot = [0,0,0,0];
  List<dynamic> rawHips = [0,0,0,0];


  var kneejsonData_str = "Knee Assembly Json Data"; 
  var footjsonData_str = "Foot Assembly Json Data"; 
  var hipsjsonData_str = "Foot Assembly Json Data";
  List<int> jdataStates = [0, 0, 0, 0];
  List<int> jdatadist = [0, 0, 0, 0];
  List<double> jdataprox = [0.0, 0.0, 0.0, 0.0];
  
  int _counter = 0;
  int indx = 0;


  double alpha1 = 0.03;
  double alpha2 = 1 - 0.03; //1-alpha1
  double beta1 = 0.02;
  double beta2 = 1 - 0.02; //1-beta1

  double pgyroA = 0.0;
  double paccelA = 0.0;
  double dgyroA = 0.0;
  double daccelA = 0.0;


  Map<String, dynamic>? _kneeData;
  Map<String, dynamic>? _footData;
  Map<String, dynamic>? _hipsData;

  Map<String, dynamic> jsonData = {};
  Map<String, dynamic> kneejsonData = {};
  Map<String, dynamic> footjsonData = {};
  Map<String, dynamic> hipsjsonData = {};

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

    switch (deviceType) {
      case 'knee':
        _notifySubKnee = _ble.subscribeToCharacteristic(characteristic).listen((datax) {
          setState(() {
            _valueKnee = const Utf8Decoder().convert(datax);
            rawKnee = datax;
            _loadData();

            });
        });
        break;
      case 'foot':
        _notifySubFoot = _ble.subscribeToCharacteristic(characteristic).listen((datax) {
          setState(() {
            _valueFoot = const Utf8Decoder().convert(datax);
            rawFoot = datax;
            _loadData();

          });
        });
        break;
      case 'hips':
        _notifySubHips = _ble.subscribeToCharacteristic(characteristic).listen((datax) {
          setState(() {
            _valueHips = const Utf8Decoder().convert(datax);
            rawHips = datax;
            _loadData();

          });
        });
        break;
    }
    //return {kneejsonData, footjsonData, hipsjsonData};
  }

  void _loadData() async {
    /*var kneeData = await unpack(rawKnee, 'knee');
    var footData = await unpack(rawFoot, 'foot');
    var hipsData = await unpack(rawHips, 'hips');

    setState(() {
      _kneeData = kneeData;
      _footData = footData;
      _hipsData = hipsData;
    });*/
    unpack(rawKnee, 'knee');
    unpack(rawFoot, 'foot');
    unpack(rawHips, 'hips');
  }

  List<double> npAsArray(List<dynamic> list) {
    return list.map((e) => e is double ? e : double.parse(e.toString())).toList();
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

void unpack(datax, deviceType){
 if (datax.length == 10) {
      var datar = datax;
      var data = (datar << 12) | 0x00;
      final svc_up = svc.BLEManager();
      if (String.fromCharCode(datax[0]) == 'a') {
        var val = data.sublist(2, 4);
        pgyroA = svc_up.unpack(val) / 10.0;
        //pgyroA=(struct.svc_up.unpack("<h",val))[0]/10.0
        val = data.sublist(4, 6);
        paccelA = svc_up.unpack(val) / 10.0;
        //paccelA=90+(struct.svc_up.unpack("<h",val))[0]/10.0
        val = data.sublist(6, 8);
        dgyroA = svc_up.unpack(val) / 10.0;
        //dgyroA=(struct.svc_up.unpack("<h",val))[0]/10.0
        val = data.sublist(8, 10);
        daccelA = svc_up.unpack(val) / 10.0;
        //daccelA=90+(struct.svc_up.unpack("<h",val))[0]/10.0
        //code already converted value undefined so commented out
        if (paccelA < 0) {
          paccelA += 360;
        }
        if (daccelA < 0) {
          daccelA += 360;
        }
        // Implement data unpacking logic
        if (deviceType == 'foot') {
          //filter foot data
          jdataprox[indx] = svc_up.comFitB(pgyroA, paccelA);
          jdataStates[indx] = datax[1];
        } else if (deviceType == 'knee') {
          //filter knee data
          jdataprox[indx] = svc_up.XComFitA(jdataprox[indx], pgyroA, paccelA);
          jdataprox[indx] = svc_up.XComFitA(jdataprox[indx], dgyroA, daccelA);
        } else if (deviceType == 'hips') {
          //filter hips data
          jdataprox[indx] = svc_up.comFitB(pgyroA, paccelA);
        }
        indx += 1;
        //bool indxbool = false;
        if (indx > 4 && deviceType=='knee') {
          //filterMap.update('Open'),(value) => value = true);
          kneejsonData["counter"] = _counter;
          kneejsonData["state"] = jdataStates;
          kneejsonData["prox"] = jdataprox;
          kneejsonData["dist"] = jdatadist;
          _counter += 1;
          //indxbool = true;
          //return{jsonData};
          print(jsonData);
        }
        if (indx > 4 && deviceType=='foot') {
          //filterMap.update('Open'),(value) => value = true);
          footjsonData["counter"] = _counter;
          footjsonData["state"] = jdataStates;
          footjsonData["prox"] = jdataprox;
          footjsonData["dist"] = jdatadist;
          _counter += 1;
          //indxbool = true;
          //return{jsonData};
          print(jsonData);
        }
        if (indx > 4 && deviceType=='hips') {
          //filterMap.update('Open'),(value) => value = true);
          hipsjsonData["counter"] = _counter;
          hipsjsonData["state"] = jdataStates;
          hipsjsonData["prox"] = jdataprox;
          hipsjsonData["dist"] = jdatadist;
          _counter += 1;
          //indxbool = true;
          //return{jsonData};
          print(jsonData);
        }
        
        //else{indxbool = false;}
      
      } else {
        print('Invalid data');
      }
    }
  //if (deviceType=="knee"){return {"counter": _counter, "state": jdataStates, "prox": jdataprox, "dist": jdatadist};}
  //else {return {"counter": _counter, "state": jdataStates, "prox": jdataprox};}
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
              : Text("Knee Data: ${kneejsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
              //: Text("Knee Data: ${kneejsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
          _footData == null
              ? const CircularProgressIndicator()
              : Text("Foot Data: ${footjsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
              //: Text("Foot Data: ${footjsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
          _hipsData == null
              ? const CircularProgressIndicator()
              : Text("Hips Data: ${hipsjsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
              //: Text("Hips Data: ${hipsjsonData.toString()}", style: Theme.of(context).textTheme.bodyLarge),
        ],
      )),
    );
  }
}
