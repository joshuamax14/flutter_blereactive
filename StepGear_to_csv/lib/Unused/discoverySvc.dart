import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:io';

class discoverySvc {
  static final _ble = FlutterReactiveBle();

  static Future<Map<String, Map<String, String>>> scanDevices() async {
    final devices = await _ble.scanForDevices(withServices: []).toList();
    final kneeDevList = <String, String>{};
    final footDevList = <String, String>{};
    final hipsDevList = <String, String>{};


    for (var d in devices) {
      final devName = d.name;
      final devId = d.id;

      if (devName.contains("STEPGEAR_KNEE")) {
        kneeDevList[devName] = devId;
      } else if (devName.contains("STEPGEAR_FOOT")) {
        footDevList[devName] = devId;
      } else if (devName.contains("STEPGEAR_HIPS")) {
        hipsDevList[devName] = devId;
      }
    }

    final devList = <String, Map<String, String>>{
      "knee": kneeDevList,
      "foot": footDevList,
      "hips": hipsDevList,
    };

    return devList;
  }

  static Future<void> saveDevicesToJson() async {
    final devList = await scanDevices();
    final jsonStr = json.encode(devList);
    // Replace the file path with the appropriate location in your Flutter project
    final jsonFile = File('devList.json');
    await jsonFile.writeAsString(jsonStr);
  }
}

// Example usage:
// DeviceScanner.saveDevicesToJson();