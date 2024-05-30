import 'dart:typed_data';
import 'globals.dart' as globals;

var notify_uuid = '0000ABF2-0000-1000-8000-00805F9B34FB';
var service_uuid = '0000ABF0-0000-1000-8000-00805F9B34FB';

Map<String, dynamic> jsonData = {};
Map<String, dynamic> kneejsonData = {};
Map<String, dynamic> hipsjsonData = {};
Map<String, dynamic> footjsonData = {};

var jdataStates = [0, 0, 0, 0];
var footjdatadist = [0.0, 0.0, 0.0, 0.0];
var footjdataprox = [0.0, 0.0, 0.0, 0.0];
var kneejdatadist = [0.0, 0.0, 0.0, 0.0];
var kneejdataprox = [0.0, 0.0, 0.0, 0.0];
var hipsjdatadist = [0.0, 0.0, 0.0, 0.0];
var hipsjdataprox = [0.0, 0.0, 0.0, 0.0];

double pgyroA = 0.0;
double paccelA = 0.0;
double dgyroA = 0.0;
double daccelA = 0.0;

  BLEManager();

  Future<void> getAddress(String type) async {
    devType = type;
    Completer<DiscoveredDevice> completer = Completer();

    void deviceFilter(DiscoveredDevice d) {
      if ((type == "knee" && d.name.toLowerCase() == "kneespp_server") ||
          (type == "foot" && d.name.toLowerCase() == "footspp_server") ||
          (type == "hips" && d.name.toLowerCase() == "hipsspp_server")) {
        completer.complete(d);
      }
    }

    final subscription = _flutterReactiveBle.scanForDevices(
      withServices: [], // Add specific services if needed
      scanMode: ScanMode.lowLatency,
    ).listen(deviceFilter);

    try {
      DiscoveredDevice device =
          await completer.future.timeout(Duration(seconds: 10));
      print('Connecting to ${device.name} with level ${device.rssi}');
      await Future.delayed(Duration(seconds: 2));
      await connectToDevice(device.id);
    } catch (e) {
      print('No $type devices found.');
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> connectToDevice(String address) async {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(notifyUuid),
      deviceId: address,
    );

    _flutterReactiveBle
        .subscribeToCharacteristic(characteristic)
        .listen((data) {
      callback(data, devType);
      print('Data received: $data');
    });

    try {
      await _flutterReactiveBle
          .connectToDevice(
            id: address,
            connectionTimeout: Duration(seconds: 5),
          )
          .first;
      print('Connected to $address');
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

//akala ko string si datax so i converted to sublist na lang check blesvc of sir ron to check
//unpack has not been checked try running on its own with sample values
  Set<Map<String, dynamic>> callback(List<int> datax, devType) {
     if (devType == null) {
      throw ArgumentError('Input cannot be null');
    }

    if (datax.length == 10) {
      var data = datax;
      if (String.fromCharCode(datax[0]) == 'a') {
        var val = data.sublist(2, 4);
        pgyroA = unpack(val) / 10.0;
        //pgyroA=(struct.unpack("<h",val))[0]/10.0
        val = data.sublist(4, 6);
        paccelA = unpack(val) / 10.0;
        //paccelA=90+(struct.unpack("<h",val))[0]/10.0
        val = data.sublist(6, 8);
        dgyroA = unpack(val) / 10.0;
        //dgyroA=(struct.unpack("<h",val))[0]/10.0
        val = data.sublist(8, 10);
        daccelA = unpack(val) / 10.0;
        //daccelA=90+(struct.unpack("<h",val))[0]/10.0
        //code already converted value undefined so commented out
        if (paccelA < 0) {
          paccelA += 360;
        }
        if (daccelA < 0) {
          daccelA += 360;
        }
        // Implement data unpacking logic
        if (devType == 'foot') {
          //filter foot data
          jdataprox[indx] = comFitB(pgyroA, paccelA);
          jdataStates[indx] = datax[1];
        } else if (devType == 'knee') {
          //filter knee data
          jdataprox[indx] = XComFitA(jdataprox[indx], pgyroA, paccelA);
          jdataprox[indx] = XComFitA(jdataprox[indx], dgyroA, daccelA);
        } else if (devType == 'hips') {
          //filter hips data
          jdataprox[indx] = comFitB(pgyroA, paccelA);
        }
        indx += 1;
        //bool indxbool = false;
        if (indx > 4) {
          jsonData["counter"] = _counter;
          jsonData["state"] = jdataStates;
          jsonData["prox"] = jdataprox;
          jsonData["dist"] = jdatadist;
          _counter += 1;
          //indxbool = true;
          //return{jsonData};
          //print(f"{jsondat}")
        }
        //else{indxbool = false;}
      
      } else {
        print('Invalid data');
      }
    }
            return{jsonData};
  }

  double comFitA(double gyro, double accel) {
    return (gyro * alpha1) + (accel * alpha2);
  }

  double comFitB(double gyro, double accel) {
    return (gyro * beta1) + (accel * beta2);
  }

  double XComFitA(double previousGyroAngle, double gyro, double accel) {
    return (previousGyroAngle + gyro * alpha1) + (accel * alpha2);
  }

  double XComFitB(double previousGyroAngle, double gyro, double accel) {
    return (previousGyroAngle + gyro * beta1) + (accel * beta2);
  }

  int unpack(List<int> binaryData) {
    Uint8List byteList = Uint8List.fromList(binaryData);
    ByteData byteData = ByteData.sublistView(byteList);
    int shortVal = byteData.getInt16(4, Endian.little);

    return shortVal;
  }
}
/*
void main() async {
  final bleManager = BLEManager();

  // Specify the type of device you want to scan and connect to
  await bleManager.getAddress('knee');
  await bleManager.getAddress('foot');
  await bleManager.getAddress('hips');
}
*/
/*
Modular Functions: The functions getAddress, connectToDevice, callback, comFitA, comFitB, and unpack are all encapsulated within the BLEManager class.
State Management: The state variables are part of the class, making it easier to manage state across different methods.
Instance Creation and Usage: In the main function, an instance of BLEManager is created and used to scan and connect to different types of devices. */
