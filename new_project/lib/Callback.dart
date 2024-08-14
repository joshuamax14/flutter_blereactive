import 'dart:typed_data';
//import 'globals.dart' as globals;

Map<String, dynamic> jsonData = {};
Map<String, dynamic> kneejsonData = {};
Map<String, dynamic> hipsjsonData = {};
Map<String, dynamic> footjsonData = {};
Map<String, dynamic> errorData = {'data': 'error'};

var jdataStates = [0, 0, 0, 0];
var footjdatadist = [0.0, 0.0, 0.0, 0.0];
var footjdataprox = [0.0, 0.0, 0.0, 0.0];
var kneejdatadist = [0.0, 0.0, 0.0, 0.0];
var kneejdataprox = [0.0, 0.0, 0.0, 0.0];
var hipsjdatadist = [0.0, 0.0, 0.0, 0.0];
var hipsjdataprox = [0.0, 0.0, 0.0, 0.0];

var indxH = 0;
var indxF = 0;
var indxK = 0;

var Hindx = 0; //outside the unpack loop
var Findx = 0; //outside the unpack loop
var Kindx = 0;

var counterh = 0;
var counterf = 0;
var counterk = 0;

double pgyroA = 0.0;
double paccelA = 0.0;
double dgyroA = 0.0;
double daccelA = 0.0;

double KneepgyroA = 0.0;
double KneepaccelA = 0.0;
double KneedgyroA = 0.0;
double KneedaccelA = 0.0;

double FootpgyroA = 0.0;
double FootpaccelA = 0.0;

double HipspgyroA = 0.0;
double HipspaccelA = 0.0;

//Complimentary Filter na Normal

class ComplimentaryFilter {
  double angle = 0.0;
  double previousGyroAngle = 0.0;
  double dt = 0.0;

  ComplimentaryFilter();

  // Update method to fuse accelerometer and gyroscope data
  double update(double accelAngle, double gyroRate) {
    // The gyroscope integration
    double gyroAngle = previousGyroAngle + gyroRate * dt;

    // Complimentary filter formula
    angle = 0.98 * gyroAngle + 0.02 * accelAngle;

    // Update previous gyro angle
    previousGyroAngle = gyroAngle;

    return angle;
  }
}

// Complimentary Filters by Sir Ron
double ans = 0.0;
double alpha_1 = 0.03;
double alpha_2 = 1 - alpha_1;
double beta_1 = 0.02;
double beta_2 = 1 - beta_1;

double XComFitA(double previousGyroAngle, double gyro, double accel) {
  ans = ((previousGyroAngle + gyro) * alpha_1) + (accel * alpha_2);
  return ans;
}

double XComFitB(double previousGyroAngle, double gyro, double accel) {
  ans = ((previousGyroAngle + gyro) * beta_1) + (accel * beta_2);
  return ans;
}

double ComFitA(double gyro, double accel) {
  ans = ((gyro + accel) * alpha_1) + (accel * alpha_2);
  return ans;
}

double ComFitB(double gyro, double accel) {
  ans = ((accel + gyro) * beta_1) + (accel * beta_2);
  return ans;
}

//struct unpack function
int unpack(List<int> binaryData) {
  //print("binary data: $binaryData");
  dynamic byteList = Uint8List.fromList(binaryData);
  //print("byteList: $byteList");
  ByteData byteData = ByteData.sublistView(byteList);
  //print("byteData: $byteData");
  int shortVal = byteData.getInt16(0, Endian.little);
  //print("devtype:" + globals.devtype + " shortVal: $shortVal");
  return shortVal;
}

void incrementIndex(d) {
  if (d == "hips") {
    indxH++;
    Hindx++;
  }
  if (d == "foot") {
    indxF++;
    Findx++;
  }
  if (d == "knee") {
    indxK++;
    Kindx++;
  }
}

Map<String, dynamic> callbackUnpack(List<int> datax, devtype) {
  if (datax.length == 10) {
    List<int> data = [0, 0, 0, 0];
    data = datax;
    //print("data: $data");
    pgyroA = 0.0;
    paccelA = 0.0;
    dgyroA = 0.0;
    daccelA = 0.0;

    //extend data
    //print("data = $datax");
    Uint8List newdata = Uint8List(data.length + 1);
    for (int i = 0; i < data.length; i++) {
      newdata[i] = data[i];
    }
    newdata[data.length] = 0x00;
    //print("new data = $newdata");
    if (String.fromCharCode(datax[0]) == 'a') {
      //print("after if data[0] = a");
      var val = data.sublist(2, 4);
      //print("Val: $val");
      pgyroA = unpack(val) / 10.0;
      //print("after pgyro unpack");
      val = data.sublist(4, 6);
      paccelA = 90.0 + (unpack(val) / 10.0);
      //print("after paccelA unpack");
      val = data.sublist(6, 8);
      dgyroA = unpack(val) / 10.0;
      //print("after dgryo unpack");
      val = data.sublist(8, 10);
      daccelA = 90.0 + (unpack(val) / 10.0);
      //print("after if daccelunpack");
      //+360 for all positive data
      //print("pgyroA: $pgyroA");
      //print("dgyroA: $dgyroA");
      if (paccelA < 0) {
        paccelA += 360;
      }
      if (daccelA < 0) {
        daccelA += 360;
      }
      //print("before if globals.devtype");

      // Implement data unpacking logic
      if (devtype == 'foot') {
        //filter foot data
        footjdataprox[indxF] = ComFitA(pgyroA, paccelA);
        jdataStates[indxF] = datax[1];
        incrementIndex('foot');
        //print("foot prox: $footjdataprox and foot dist  $footjdatadist");
      } else if (devtype == 'knee') {
        //filter knee data
        kneejdataprox[indxK] = XComFitA(kneejdataprox[indxK], pgyroA, paccelA);
        kneejdatadist[indxK] = XComFitA(kneejdatadist[indxK], dgyroA, daccelA);
        incrementIndex('knee');
        //print("knee prox: $kneejdataprox and knee dist = $kneejdatadist");
      } else if (devtype == 'hips') {
        //filter hips data
        hipsjdataprox[indxH] = ComFitA(pgyroA, paccelA);
        incrementIndex('hips');
      }
      if (indxF >= 4 && devtype == 'foot') {
        footjsonData["counter"] = counterf;
        footjsonData["state"] = jdataStates;
        footjsonData["prox"] = footjdataprox;
        footjsonData["dist"] = footjdatadist;
        indxF = 0;
        counterf++;
        //print("$devtype jsonData: $footjsonData");
      }
      if (indxK >= 4 && devtype == 'knee') {
        kneejsonData["counter"] = counterk;
        kneejsonData["state"] = jdataStates;
        kneejsonData["prox"] = kneejdataprox;
        kneejsonData["dist"] = kneejdatadist;
        indxK = 0;
        counterk++;
        //print("$devtype jsonData: $kneejsonData");
      }
      if (indxH >= 4 && devtype == 'hips') {
        hipsjsonData["counter"] = counterh;
        hipsjsonData["state"] = jdataStates;
        hipsjsonData["prox"] = hipsjdataprox;
        hipsjsonData["dist"] = hipsjdatadist;
        indxH = 0;
        counterh++;
        //print("$devtype jsonData: $hipsjsonData");
      }
    } else {
      print('Invalid data');
    }
  }

  if (Kindx >= 4 && devtype == 'knee') {
    Kindx = 0;
    return kneejsonData;
  } else if (Findx >= 4 && devtype == 'foot') {
    Findx = 0;
    //print('foot: $footjdataprox');
    return footjsonData;
  } else if (Hindx >= 4 && devtype == 'hips') {
    Hindx = 0;
    //print('hips: $hipsjdataprox');
    return hipsjsonData;
  } else {
    return errorData; // Return an empty list if devtype is invalid
  }
}

Map<String, dynamic> KneeCallbackUnpack(List<int> dataxK) {
  if (dataxK.length == 10) {
    List<int> dataK = [0, 0, 0, 0];
    dataK = dataxK;
    //print("data: $data");
    KneepgyroA = 0.0;
    KneepaccelA = 0.0;
    KneedgyroA = 0.0;
    KneedaccelA = 0.0;

    //extend data
    //print("data = $datax");
    Uint8List newdataK = Uint8List(dataK.length + 1);
    for (int i = 0; i < dataK.length; i++) {
      newdataK[i] = dataK[i];
    }
    newdataK[dataK.length] = 0x00;
    //print("new data = $newdata");
    if (String.fromCharCode(dataxK[0]) == 'a') {
      //print("after if data[0] = a");
      var valK = dataK.sublist(2, 4);
      //print("Val: $val");
      KneepgyroA = unpack(valK) / 10.0;
      //print("after pgyro unpack");
      valK = dataK.sublist(4, 6);
      KneepaccelA = 90.0 + (unpack(valK) / 10.0);
      //print("after paccelA unpack");
      valK = dataK.sublist(6, 8);
      KneedgyroA = unpack(valK) / 10.0;
      //print("after dgryo unpack");
      valK = dataK.sublist(8, 10);
      KneedaccelA = 90.0 + (unpack(valK) / 10.0);
      //print("after if daccelunpack");
      //+360 for all positive data
      //print("pgyroA: $pgyroA");
      //print("dgyroA: $dgyroA");
      if (KneepaccelA < 0) {
        KneepaccelA += 360;
      }
      if (KneedaccelA < 0) {
        KneedaccelA += 360;
      }
      //print("before if globals.devtype");

      // Implement data unpacking logic
      //filter knee data
      kneejdataprox[indxK] =
          XComFitA(kneejdataprox[indxK], KneepgyroA, KneepaccelA);
      kneejdatadist[indxK] =
          XComFitA(kneejdatadist[indxK], KneedgyroA, KneedaccelA);
      //print("knee prox: $kneejdataprox and knee dist = $kneejdatadist");

      incrementIndex('knee');
      if (indxK >= 4) {
        kneejsonData["counter"] = counterk;
        kneejsonData["state"] = jdataStates;
        kneejsonData["prox"] = kneejdataprox;
        kneejsonData["dist"] = kneejdatadist;
        indxK = 0;
        counterk++;

        //print("$devtype jsonData: $kneejsonData");
      }
    } else {
      print('Invalid data');
    }
  }
  if (Kindx >= 4) {
    Kindx = 0;
    return kneejsonData;
  } else {
    return errorData;
  }
}

Map<String, dynamic> FootcallbackUnpack(List<int> dataxF) {
  if (dataxF.length == 10) {
    List<int> dataF = [0, 0, 0, 0];
    dataF = dataxF;
    //print("data: $data");
    FootpgyroA = 0.0;
    FootpaccelA = 0.0;
    //extend data
    //print("data = $datax");
    Uint8List newdataF = Uint8List(dataF.length + 1);
    for (int i = 0; i < dataF.length; i++) {
      newdataF[i] = dataF[i];
    }
    newdataF[dataF.length] = 0x00;
    //print("new data = $newdata");
    if (String.fromCharCode(dataxF[0]) == 'a') {
      //print("after if data[0] = a");
      var valF = dataF.sublist(2, 4);
      //print("Val: $val");
      FootpgyroA = unpack(valF) / 10.0;
      //print("after pgyro unpack");
      valF = dataF.sublist(4, 6);
      FootpaccelA = 90.0 + (unpack(valF) / 10.0);
      //print("after paccelA unpack");
      //valF = dataF.sublist(6, 8);
      //FootdgyroA = unpack(valF) / 10.0;
      //print("after dgryo unpack");
      //valF = dataF.sublist(8, 10);
      //FootdaccelA = 90.0 + (unpack(valF) / 10.0);
      //print("after if daccelunpack");
      //+360 for all positive data
      //print("pgyroA: $pgyroA");
      //print("dgyroA: $dgyroA");
      if (FootpaccelA < 0) {
        FootpaccelA += 360;
      }
      //if (FootdaccelA < 0) {
      //FootdaccelA += 360;
      // }
      //print("before if globals.devtype");

      // Implement data unpacking logic
      //filter foot data
      footjdataprox[indxF] = ComFitA(FootpgyroA, FootpaccelA);
      jdataStates[indxF] = dataxF[1];
      //print("foot prox: $footjdataprox and foot dist  $footjdatadist");

      incrementIndex('foot');
      if (indxF >= 4) {
        footjsonData["counter"] = counterf;
        footjsonData["state"] = jdataStates;
        footjsonData["prox"] = footjdataprox;
        footjsonData["dist"] = footjdatadist;
        indxF = 0;
        counterf++;
        //print("$devtype jsonData: $footjsonData");
      }
    } else {
      print('Invalid data');
    }
  }
  if (Findx >= 4) {
    //print('foot: $footjdataprox');
    Findx = 0;
    return footjsonData;
  } else {
    return errorData; // Return an empty list if devtype is invalid
  }
}

Map<String, dynamic> HipscallbackUnpack(List<int> dataxH) {
  if (dataxH.length == 10) {
    List<int> dataH = [0, 0, 0, 0];
    dataH = dataxH;
    //print("data: $data");
    HipspgyroA = 0.0;
    HipspaccelA = 0.0;

    //extend data
    //print("data = $datax");
    Uint8List newdataH = Uint8List(dataH.length + 1);
    for (int i = 0; i < dataH.length; i++) {
      newdataH[i] = dataH[i];
    }
    newdataH[dataH.length] = 0x00;
    //print("new data = $newdata");
    if (String.fromCharCode(dataxH[0]) == 'a') {
      //print("after if data[0] = a");
      var valH = dataH.sublist(2, 4);
      //print("Val: $val");
      HipspgyroA = unpack(valH) / 10.0;
      //print("after pgyro unpack");
      valH = dataH.sublist(4, 6);
      HipspaccelA = 90.0 + (unpack(valH) / 10.0);
      //print("after paccelA unpack");
      //valH = dataH.sublist(6, 8);
      //HipsdgyroA = unpack(valH) / 10.0;
      //print("after dgryo unpack");
      //valH = dataH.sublist(8, 10);
      //HipsdaccelA = 90.0 + (unpack(valH) / 10.0);
      //print("after if daccelunpack");
      //+360 for all positive data
      //print("pgyroA: $pgyroA");
      //print("dgyroA: $dgyroA");
      if (HipspaccelA < 0) {
        HipspaccelA += 360;
      }
      // if (HipsdaccelA < 0) {
      // HipsdaccelA += 360;
      //}
      //print("before if globals.devtype");

      // Implement data unpacking logic

      hipsjdataprox[indxH] = ComFitA(HipspgyroA, HipspaccelA);

      incrementIndex('hips');

      if (indxH >= 4) {
        hipsjsonData["counter"] = counterh;
        hipsjsonData["state"] = jdataStates;
        hipsjsonData["prox"] = hipsjdataprox;
        hipsjsonData["dist"] = hipsjdatadist;
        indxH = 0;
        counterh++;
        //print("$devtype jsonData: $hipsjsonData");
      }
    } else {
      print('Invalid data');
    }
  }
  if (Hindx >= 4) {
    //print('hips: $hipsjsonData');
    Hindx = 0;
    return hipsjsonData;
  } else {
    return errorData; // Return an empty list if devtype is invalid
  }
}
