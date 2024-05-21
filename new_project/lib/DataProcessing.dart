import 'dart:typed_data';

var notify_uuid = '0000ABF2-0000-1000-8000-00805F9B34FB';
var service_uuid = '0000ABF0-0000-1000-8000-00805F9B34FB';

var devtype = 'none';

int _counter = 0;
int indx = 0;

Map<String, dynamic> jsondat = {};
var jdataStates = [0, 0, 0, 0];
var jdatadist = [0, 0, 0, 0];
var jdataprox = [0.0, 0.0, 0.0, 0.0];

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

void unpack(List<int> BinaryData) {
  Uint8List bytelist = Uint8List.fromList(BinaryData);
  ByteData byteData = ByteData.sublistView(bytelist);

  int shortVal = byteData.getInt16(4, Endian.little);
}

void callback(handle, datax) {
  //globals are bad try to implement with provider if needed else where
  if (datax.length == 10) {
    var data = datax;
    //extend data need data.extend(b"\x00")
    if (data[0] == 'a') {
      //check alternative for struct unpack
      var val = data.substring(2, 4);
      //pgyroA=(struct.unpack("<h",val))[0]/10.0
      val = data.substring(4, 6);
      //paccelA=90+(struct.unpack("<h",val))[0]/10.0
      val = data.substring(6, 8);
      //dgyroA=(struct.unpack("<h",val))[0]/10.0
      val = data.substring(8, 10);
      //daccelA=90+(struct.unpack("<h",val))[0]/10.0
      //if (paccelA<0) {
      //paccelA+=360}
      //if (daccelA<0) {
      //daccelA+=360}
      if (devtype == 'foot') {
        //jdataprox[indx]=ComFitB(pgyroA, paccelA);
        jdataStates[indx] = data[1];
      } else if (devtype == 'knee') {
        //jdataprox[indx]=XComFitA(jdataprox[indx],pgyroA,paccelA);
        //jdataprox[indx]=XComFitA(jdataprox[indx],dgyroA,daccelA);
      } else if (devtype == 'hips') {
        //jdataprox[indx]=ComFitB(pgyroA, paccelA));
      }
      indx += 1;
      if (indx > 4) {
        jsondat["counter"] = _counter;
        jsondat["state"] = jdataStates;
        jsondat["prox"] = jdataprox;
        jsondat["dist"] = jdatadist;
        _counter += 1;
        //print(f"{jsondat}")
      }
    } else {
      print('invalid data');
    }
  }
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