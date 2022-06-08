import 'package:get/get.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:blueshoe/constants/uuidbank.dart';

class BlueController extends GetxController {
  FlutterBlue flutterBlue = FlutterBlue.instance;

  BluetoothDevice? device;
  RxBool isConnected = false.obs;

  RxList<BluetoothService> services = <BluetoothService>[].obs;

  List<String> scanneddevices = [];

  BluetoothService? batteryService;
  BluetoothCharacteristic? batteryChar;
  RxBool batteryServiceReady = false.obs;
  void checkBatteryService() async {
    if (batteryService != null && batteryChar != null) {
      await Future.delayed(Duration(seconds: 1));
      if (!await batteryChar!.value.isEmpty) {
        batteryServiceReady.value = true;
      } else {
        batteryServiceReady.value = false;
      }
    } else {
      batteryServiceReady.value = false;
    }
  }

  void resetBatteryService() {
    batteryService = null;
    batteryChar = null;
    checkBatteryService();
  }

  BluetoothService? pedometerService;
  BluetoothCharacteristic? pedometerChar;
  RxBool pedometerServiceReady = false.obs;
  void checkPedometerService() async {
    if (pedometerService != null && pedometerChar != null) {
      await Future.delayed(Duration(seconds: 1));

      if (!await pedometerChar!.value.isEmpty) {
        pedometerServiceReady.value = true;
      } else {
        pedometerServiceReady.value = false;
      }
    } else {
      pedometerServiceReady.value = false;
    }
  }

  void resetPedometerService() {
    pedometerService = null;
    pedometerChar = null;
    checkPedometerService();
  }

  BluetoothService? ledService;
  BluetoothCharacteristic? ledChar;
  RxBool ledServiceReady = false.obs;
  void checkLEDService() async {
    if (ledService != null && ledChar != null) {
      await Future.delayed(Duration(seconds: 1));
      if (!await ledChar!.value.isEmpty) {
        ledServiceReady.value = true;
      } else {
        ledServiceReady.value = false;
      }
    } else {
      ledServiceReady.value = false;
    }
  }

  void resetLEDService() {
    ledService = null;
    ledChar = null;
    checkLEDService();
  }

  Future<void> startScan() async {
    // Start scanning
    await flutterBlue.startScan(timeout: Duration(seconds: 4));
    _listResultScan();
  }

  void _listResultScan() {
    scanneddevices.clear();
// Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
      // do something with scan results

      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
        if (r.device.name.isNotEmpty) scanneddevices.add(r.device.name);
      }
    });

    flutterBlue.stopScan();
    return;
  }

  bool connectDevice(String devicename) {
    try {
      var subscription = flutterBlue.scanResults.listen((results) async {
        // do something with scan results
        for (ScanResult r in results) {
          if (r.device.name == devicename) {
            try {
              print("Disconnected first");
              r.device.disconnect();
              await Future.delayed(Duration(seconds: 2));
            } catch (e) {}
            await r.device.connect(autoConnect: false).whenComplete(() {
              device = r.device;
              isConnected.value = true;
            }).catchError((e) {
              print(e);
              throw 'Error in connecting to device';
            }).timeout(Duration(seconds: 5), onTimeout: () {
              throw 'Connecting to ${r.device.name} timeout.';
            });
          }
        }
        if (device == null) {
          throw 'Couldn\'t find the device';
        }
      });
      return true;
    } on Exception catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> searchforservices() async {
    print("searching for services");
    try {
      print(device);
      if (device == null) throw 'not connected to the device';

      print(device!.id);
      services.value = await device!.discoverServices();
      services.forEach((service) {
        // do something with service
        print("s : --${service.uuid}");
        if (service.uuid == UUIDBANK.BATTERYLEVEL_SERVICE_UUID) {
          batteryService = service;
          print("SET BATTERY SERVICE");
        }
        if (service.uuid == UUIDBANK.PHYSICALACTIVITYMONITOR_SERVICE_UUID) {
          pedometerService = service;
        }
        if (service.uuid == UUIDBANK.LEDCONTROLLER_SERVICE_UUID) {
          ledService = service;
        }
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid == UUIDBANK.BATTERYLEVEL_CAR_UUID) {
            batteryChar = characteristic;
            print("SET BATTERY CHARS");
          }
          if (characteristic.uuid == UUIDBANK.STEPCOUNTER_CAR_UUID) {
            pedometerChar = characteristic;
            pedometerChar!.setNotifyValue(true);
          }
          if (characteristic.uuid == UUIDBANK.LEDCONTROLLER_CAR_UUID) {
            ledChar = characteristic;
          }
          for (BluetoothDescriptor descriptor in characteristic.descriptors) {
            print("d : ---- ${descriptor.value}");
          }
          print(
              "c ------ ${characteristic.uuid} : ${characteristic.value.listen((event) {
            print(event);
          })}");
        }
      });
      checkBatteryService();
      checkPedometerService();
      checkLEDService();

      return Future<bool>.value(true);
    } on Exception catch (e) {
      print(e);
      return Future<bool>.value(false);
    }
  }

  Future<void> disconnect() async {
    await device!.disconnect();
    device = null;
    isConnected.value = false;
    resetBatteryService();
    resetLEDService();
    resetPedometerService();

    return;
  }

  // Future<void> selectedServiceCharacteristics() async {
  //   if (selectedService == null) return Future<void>.value(null);
  //
  //   // Reads all characteristics
  //   var characteristics = selectedService!.characteristics;
  //   for (BluetoothCharacteristic c in characteristics) {
  //     List<int> value = await c.read();
  //     print(value);
  //   }
  //
  //   return Future<void>.value(null);
  // }
}
