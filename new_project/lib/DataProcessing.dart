import 'dart:typed_data';
import 'globals.dart' as globals;

var notify_uuid = '0000ABF2-0000-1000-8000-00805F9B34FB';
var service_uuid = '0000ABF0-0000-1000-8000-00805F9B34FB';

String devType = 'none';

Map<String, dynamic> jsonData = {};
var jdataStates = [0, 0, 0, 0];
var jdatadist = [0, 0, 0, 0];
var jdataprox = [0.0, 0.0, 0.0, 0.0];

double pgyroA = 0.0;
double paccelA = 0.0;
double dgyroA = 0.0;
double daccelA = 0.0;

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
double alpha_2 = 1 - beta_1;
double beta_1 = 0.02;
double beta_2 = 1 - beta_1;

double XComFitA(double previousGyroAngle, double gyro, double accel) {
  ans = (previousGyroAngle + gyro * alpha_1) + (accel * alpha_2);
  return ans;
}

double XComFitB(double previousGyroAngle, double gyro, double accel) {
  ans = (previousGyroAngle + gyro * beta_1) + (accel * beta_2);
  return ans;
}

double ComFitA(double gyro, double accel) {
  ans = (gyro * alpha_1) + (accel * alpha_2);
  return ans;
}

double ComFitB(double gyro, double accel) {
  ans = (gyro * beta_1) + (accel * beta_2);
  return ans;
}

//struct unpack function
int unpack(List<int> binaryData) {
  //print("before Uint8List");
  dynamic byteList = Uint8List.fromList(binaryData);
  print("byteList: $byteList");
  ByteData byteData = ByteData.sublistView(byteList);
  print("byteData: $byteData");
  int shortVal = byteData.getInt16(0, Endian.little);
  print("shortVal: $shortVal");
  return shortVal;
}

void incrementIndx() {
  globals.indx++;
}

void incrementCounter() {
  globals.counterx++;
}

String callback(List<int> datax) {
  if (datax.length == 10) {
    var data = datax;
    //extend data
        print("data = $datax");
    Uint8List newdata = Uint8List(data.length + 1);
    for (int i=0;i<data.length;i++){newdata[i] = data[i];}
    newdata[data.length] =  0x00;
    print("new data = $newdata");
    if (String.fromCharCode(datax[0]) == 'a') {
          print("after if data[0] = a");
      var val = data.sublist(2, 4);
          print("Val: $val");
      pgyroA = unpack(val) / 10.0;
          print("after pgyro unpack");
      //pgyroA=(struct.unpack("<h",val))[0]/10.0
      val = data.sublist(4, 6);
      paccelA = unpack(val) / 10.0;
          print("after paccelA unpack");
      //paccelA=90+(struct.unpack("<h",val))[0]/10.0
      val = data.sublist(6, 8);
      dgyroA = unpack(val) / 10.0;
          print("after dgryo unpack");
      //dgyroA=(struct.unpack("<h",val))[0]/10.0
      val = data.sublist(8, 10);
      daccelA = unpack(val) / 10.0;
          print("after if daccelunpack");
      //daccelA=90+(struct.unpack("<h",val))[0]/10.0
      //+360 for all positive data
      print("before if paccelA <0");
      if (paccelA < 0) {
        paccelA += 360;
      }
      if (daccelA < 0) {
        daccelA += 360;
      }
      print("before if globals.devtype");

      // Implement data unpacking logic
      if (globals.devtype == 'foot') {
        //filter foot data
        jdataprox[globals.indx] = ComFitB(pgyroA, paccelA);
        jdataStates[globals.indx] = datax[1];
              print("before else if globals.devtype == knee");

      } else if (globals.devtype == 'knee') {
        //filter knee data
        jdataprox[globals.indx] =
            XComFitA(jdataprox[globals.indx], pgyroA, paccelA);
        jdataprox[globals.indx] =
            XComFitA(jdataprox[globals.indx], dgyroA, daccelA);
      } else if (globals.devtype == 'hips') {
        //filter hips data
        jdataprox[globals.indx] = ComFitB(pgyroA, paccelA);
      }
      globals.indx += 1;
      if (globals.indx > 4) {
        jsonData["counter"] = globals.counterx;
        jsonData["state"] = jdataStates;
        jsonData["prox"] = jdataprox;
        jsonData["dist"] = jdatadist;
        globals.counterx += 1;
        print(jsonData);
      }
    } else {
      print('Invalid data');
    }
  }
  return (jsonData.entries.toList()).toString();
}


/*
async def getAdress(type):
    global devtype
    device=None
    if type=="knee":
        devtype="knee"
        device = await BleakScanner.find_device_by_filter(lambda d, ad: d.name and d.name.lower() == "kneespp_server")
    elif type=="foot":
        devtype="foot"
        device = await BleakScanner.find_device_by_filter(lambda d, ad: d.name and d.name.lower() == "footspp_server")
    elif type=="hips":
        devtype="hips"
        device = await BleakScanner.find_device_by_filter(lambda d, ad: d.name and d.name.lower() == "hipsspp_server")    
    if device == None:
        print(f"No {type} devices found.")
    else:
        print(f"Connecting to {device} with level {device.rssi}")
        await asyncio.sleep(2)
        await main(device.address)

async def main(address):
    client = BleakClient(address)
    try:
        await client.connect()
        await client.start_notify(NOTIFY_UUID, callback)
        # wait forever
        await asyncio.Event().wait()
        await client.stop_notify(NOTIFY_UUID)
        print("stopped properly")
        #model_number = await client.read_gatt_char(NOTIFY_UUID)
        #print("Model Number: {0}".format("".join(map(chr, model_number))))
    except Exception as e:
        #await client.stop_notify(NOTIFY_UUID)
        print(e)
    finally:
        await client.disconnect()

if len(sys.argv)>1:
    #ok, what device are we looking for?
    asyncio.run(getAdress(sys.argv[1]))
else:
    print("incomplete arguments...")
#asyncio.run(main(address))

*/
