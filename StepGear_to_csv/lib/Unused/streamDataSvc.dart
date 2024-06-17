import 'dart:convert';
import 'dart:io';
import 'dart:math';

List<double> npAsArray(List<dynamic> list) {
  return list.map((e) => e is double ? e : double.parse(e.toString())).toList();
}
Future<Map<String, dynamic>> neoReadKneeAngles() async {
  Map<String, dynamic> kneedecodedArrays = {};
  List<double> prox = [];
  List<double> dist = [];
  int counter = 0;

  try {
    final file = File('./knee');
    final decodedArrays = jsonDecode(await file.readAsString());
    counter = decodedArrays["counter"];
    prox = npAsArray(decodedArrays["prox"]);
    dist = npAsArray(decodedArrays["dist"]);
  } catch (e) {
    print("error occurred while trying to read data: $kneedecodedArrays");
  }

  return {"counter": counter, "prox": prox, "dist": dist};
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

Future<Map<String, dynamic>> readKneeAngles() async {
  Map<String, dynamic> kneedecodedArrays = {};

  try {
    final file = File('./knee');
    final decodedArrays = jsonDecode(await file.readAsString());
    var ddaState = decodedArrays["state"];
    var ddaKneeFlex = npAsArray(decodedArrays["kneeFlex"]);
    var ddaAnkleFlex = npAsArray(decodedArrays["ankleFlex"]);
    kneedecodedArrays["state"] = ddaState;
    kneedecodedArrays["kneeFlex"] = ddaKneeFlex;
    kneedecodedArrays["ankleFlex"] = ddaAnkleFlex;
  } catch (e) {
    kneedecodedArrays["state"] = [8, 8];
    kneedecodedArrays["kneeFlex"] = [-200, -200];
    kneedecodedArrays["ankleFlex"] = [-200, -200];
    print("error occurred while trying to read data: $kneedecodedArrays");
  }

  return kneedecodedArrays;
}

Future<Map<String, dynamic>> readHipsAngles() async {
  Map<String, dynamic> hipsdecodedArrays = {};

  try {
    final file = File('./hips');
    final decodedArrays = jsonDecode(await file.readAsString());
    var ddaState = decodedArrays["state"];
    var ddaHipsFlex = npAsArray(decodedArrays["hipsFlex"]);
    var ddaAnkleFlex = npAsArray(decodedArrays["ankleFlex"]);
    hipsdecodedArrays["state"] = ddaState;
    hipsdecodedArrays["hipsFlex"] = ddaHipsFlex;
    hipsdecodedArrays["ankleFlex"] = ddaAnkleFlex;
  } catch (e) {
    hipsdecodedArrays["state"] = [8, 8];
    hipsdecodedArrays["hipsFlex"] = [-200, -200];
    hipsdecodedArrays["ankleFlex"] = [-200, -200];
    print("error occurred while trying to read data: $hipsdecodedArrays");
  }

  return hipsdecodedArrays;
}

Future<Map<String, dynamic>> readDataKnee() async {
  Map<String, dynamic> kneedecodedArrays = {};
  Map<String, dynamic> footdecodedArrays = {};

  try {
    final file = File('./knee');
    final decodedArrays = jsonDecode(await file.readAsString());
    var ddaState = decodedArrays["state"];
    var ddaPsensor = npAsArray(decodedArrays["psensor"]);
    var ddaDistal = npAsArray(decodedArrays["distal"]);
    var ddaProximal = npAsArray(decodedArrays["proximal"]);
    var ddaFoot = npAsArray(decodedArrays["foot"]);
    var ddaDistalR = sqrt(ddaDistal[0] * ddaDistal[0] + ddaDistal[1] * ddaDistal[1] + ddaDistal[2] * ddaDistal[2]);
    var ddaProximalR = sqrt(ddaProximal[0] * ddaProximal[0] + ddaProximal[1] * ddaProximal[1] + ddaProximal[2] * ddaProximal[2]);
    var ddaFootR = sqrt(ddaFoot[0] * ddaFoot[0] + ddaFoot[1] * ddaFoot[1] + ddaFoot[2] * ddaFoot[2]);
    kneedecodedArrays["state"] = ddaState;
    kneedecodedArrays["psensor"] = ddaPsensor;
    kneedecodedArrays["distal"] = ddaDistal;
    kneedecodedArrays["proximal"] = ddaProximal;
    kneedecodedArrays["distalR"] = ddaDistalR;
    kneedecodedArrays["proximalR"] = ddaProximalR;
    footdecodedArrays["state"] = ddaState;
    footdecodedArrays["psensor"] = ddaPsensor;
    footdecodedArrays["distal"] = ddaDistal;
    footdecodedArrays["proximal"] = ddaFoot;
    footdecodedArrays["distalR"] = ddaDistalR;
    footdecodedArrays["proximalR"] = ddaFootR;
  } catch (e) {
    var ddaState = 0;
    var ddaPsensor = [0.0, 0.0];
    var ddaDistal = [0.0, 0.0, 0.0];
    var ddaDistalR = sqrt(ddaDistal[0] * ddaDistal[0] + ddaDistal[1] * ddaDistal[1] + ddaDistal[2] * ddaDistal[2]);
    var ddaProximal = [0.0, 0.0, 0.0];
    var ddaProximalR = sqrt(ddaProximal[0] * ddaProximal[0] + ddaProximal[1] * ddaProximal[1] + ddaProximal[2] * ddaProximal[2]);
    kneedecodedArrays["state"] = ddaState;
    kneedecodedArrays["psensor"] = ddaPsensor;
    kneedecodedArrays["distal"] = ddaDistal;
    kneedecodedArrays["proximal"] = ddaProximal;
    kneedecodedArrays["distalR"] = ddaDistalR;
    kneedecodedArrays["proximalR"] = ddaProximalR;
    footdecodedArrays["state"] = ddaState;
    footdecodedArrays["psensor"] = ddaPsensor;
    footdecodedArrays["distal"] = ddaDistal;
    footdecodedArrays["proximal"] = ddaProximal;
    footdecodedArrays["distalR"] = ddaDistalR;
    footdecodedArrays["proximalR"] = ddaProximalR;
    print("error occurred while trying to read foot data: $kneedecodedArrays");
  }

  return {"knee": kneedecodedArrays, "foot": footdecodedArrays};
}

Future<Map<String, dynamic>> readDataFoot() async {
  Map<String, dynamic> kneedecodedArrays = {};
  Map<String, dynamic> footdecodedArrays = {};

  try {
    final file = File('./foot');
    final decodedArrays = jsonDecode(await file.readAsString());
    var ddaState = decodedArrays["state"];
    var ddaPsensor = npAsArray(decodedArrays["psensor"]);
    var ddaDistal = npAsArray(decodedArrays["distal"]);
    var ddaProximal = npAsArray(decodedArrays["proximal"]);
    var ddaFoot = npAsArray(decodedArrays["foot"]);
    var ddaDistalR = sqrt(ddaDistal[0] * ddaDistal[0] + ddaDistal[1] * ddaDistal[1] + ddaDistal[2] * ddaDistal[2]);
    var ddaProximalR = sqrt(ddaProximal[0] * ddaProximal[0] + ddaProximal[1] * ddaProximal[1] + ddaProximal[2] * ddaProximal[2]);
    var ddaFootR = sqrt(ddaFoot[0] * ddaFoot[0] + ddaFoot[1] * ddaFoot[1] + ddaFoot[2] * ddaFoot[2]);
    kneedecodedArrays["state"] = ddaState;
    kneedecodedArrays["psensor"] = ddaPsensor;
    kneedecodedArrays["distal"] = ddaDistal;
    kneedecodedArrays["proximal"] = ddaProximal;
    kneedecodedArrays["distalR"] = ddaDistalR;
    kneedecodedArrays["proximalR"] = ddaProximalR;
    footdecodedArrays["state"] = ddaState;
    footdecodedArrays["psensor"] = ddaPsensor;
    footdecodedArrays["distal"] = ddaDistal;
    footdecodedArrays["proximal"] = ddaFoot;
    footdecodedArrays["distalR"] = ddaDistalR;
    footdecodedArrays["proximalR"] = ddaFootR;
  } catch (e) {
    var ddaState = 0;
    var ddaPsensor = [0.0, 0.0];
    var ddaDistal = [0.0, 0.0, 0.0];
    var ddaDistalR = sqrt(ddaDistal[0] * ddaDistal[0] + ddaDistal[1] * ddaDistal[1] + ddaDistal[2] * ddaDistal[2]);
    var ddaProximal = [0.0, 0.0, 0.0];
    var ddaProximalR = sqrt(ddaProximal[0] * ddaProximal[0] + ddaProximal[1] * ddaProximal[1] + ddaProximal[2] * ddaProximal[2]);
    kneedecodedArrays["state"] = ddaState;
    kneedecodedArrays["psensor"] = ddaPsensor;
    kneedecodedArrays["distal"] = ddaDistal;
    kneedecodedArrays["proximal"] = ddaProximal;
    kneedecodedArrays["distalR"] = ddaDistalR;
    kneedecodedArrays["proximalR"] = ddaProximalR;
    footdecodedArrays["state"] = ddaState;
    footdecodedArrays["psensor"] = ddaPsensor;
    footdecodedArrays["distal"] = ddaDistal;
    footdecodedArrays["proximal"] = ddaProximal;
    footdecodedArrays["distalR"] = ddaDistalR;
    footdecodedArrays["proximalR"] = ddaProximalR;
    print("error occurred while trying to read foot data: $kneedecodedArrays");
  }

  return {"knee": kneedecodedArrays, "foot": footdecodedArrays};
}

Future<Map<String, dynamic>> readDataHips() async {
  Map<String, dynamic> hipsdecodedArrays = {};
  Map<String, dynamic> footdecodedArrays = {};

  try {
    final file = File('./hips');
    final decodedArrays = jsonDecode(await file.readAsString());
    var ddaState = decodedArrays["state"];
    var ddaPsensor = npAsArray(decodedArrays["psensor"]);
    var ddaDistal = npAsArray(decodedArrays["distal"]);
    var ddaProximal = npAsArray(decodedArrays["proximal"]);
    var ddaFoot = npAsArray(decodedArrays["foot"]);
    var ddaDistalR = sqrt(ddaDistal[0] * ddaDistal[0] + ddaDistal[1] * ddaDistal[1] + ddaDistal[2] * ddaDistal[2]);
    var ddaProximalR = sqrt(ddaProximal[0] * ddaProximal[0] + ddaProximal[1] * ddaProximal[1] + ddaProximal[2] * ddaProximal[2]);
    var ddaFootR = sqrt(ddaFoot[0] * ddaFoot[0] + ddaFoot[1] * ddaFoot[1] + ddaFoot[2] * ddaFoot[2]);
    hipsdecodedArrays["state"] = ddaState;
    hipsdecodedArrays["psensor"] = ddaPsensor;
    hipsdecodedArrays["distal"] = ddaDistal;
    hipsdecodedArrays["proximal"] = ddaProximal;
    hipsdecodedArrays["distalR"] = ddaDistalR;
    hipsdecodedArrays["proximalR"] = ddaProximalR;
    footdecodedArrays["state"] = ddaState;
    footdecodedArrays["psensor"] = ddaPsensor;
    footdecodedArrays["distal"] = ddaDistal;
    footdecodedArrays["proximal"] = ddaFoot;
    footdecodedArrays["distalR"] = ddaDistalR;
    footdecodedArrays["proximalR"] = ddaFootR;
  } catch (e) {
    var ddaState = 0;
    var ddaPsensor = [0.0, 0.0];
    var ddaDistal = [0.0, 0.0, 0.0];
    var ddaDistalR = sqrt(ddaDistal[0] * ddaDistal[0] + ddaDistal[1] * ddaDistal[1] + ddaDistal[2] * ddaDistal[2]);
    var ddaProximal = [0.0, 0.0, 0.0];
    var ddaProximalR = sqrt(ddaProximal[0] * ddaProximal[0] + ddaProximal[1] * ddaProximal[1] + ddaProximal[2] * ddaProximal[2]);
    hipsdecodedArrays["state"] = ddaState;
    hipsdecodedArrays["psensor"] = ddaPsensor;
    hipsdecodedArrays["distal"] = ddaDistal;
    hipsdecodedArrays["proximal"] = ddaProximal;
    hipsdecodedArrays["distalR"] = ddaDistalR;
    hipsdecodedArrays["proximalR"] = ddaProximalR;
    footdecodedArrays["state"] = ddaState;
    footdecodedArrays["psensor"] = ddaPsensor;
    footdecodedArrays["distal"] = ddaDistal;
    footdecodedArrays["proximal"] = ddaProximal;
    footdecodedArrays["distalR"] = ddaDistalR;
    footdecodedArrays["proximalR"] = ddaProximalR;
    print("error occurred while trying to read foot data: $hipsdecodedArrays");
  }

  return {"hips": hipsdecodedArrays, "foot": footdecodedArrays};
}
