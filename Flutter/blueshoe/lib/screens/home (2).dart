import 'package:blueshoe/controllers/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:blueshoe/functions.dart';

class Home extends StatelessWidget {
  Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BlueTest'),
        leading: Obx(() => Get.find<BlueController>().isConnected.value
            ? IconButton(onPressed: () {}, icon: Icon(Icons.refresh))
            : IconButton(onPressed: null, icon: Icon(Icons.refresh))),
        actions: [
          Obx(() {
            return Get.find<BlueController>().isConnected.value
                ? IconButton(
                    onPressed: null, icon: Icon(Icons.bluetooth_connected))
                : IconButton(
                    onPressed: () async {
                      await Get.find<BlueController>().startScan();
                      await Future.delayed(const Duration(seconds: 2), () {});
                      List<String> results =
                          Get.find<BlueController>().scanneddevices;
                      await showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              height: 300.0,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15.0, vertical: 24.0),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "Choose your device : ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24.0),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: results.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            onTap: () async {
                                              await Get.find<BlueController>()
                                                  .connectDevice(
                                                      results[index]);
                                              await Future.delayed(
                                                  Duration(seconds: 2));
                                              bool connected =
                                                  Get.find<BlueController>()
                                                      .isConnected
                                                      .value;
                                              if (connected) {
                                                Get.back();
                                              } else {
                                                Get.defaultDialog(
                                                    title:
                                                        'Couldn\'t find the device');
                                              }
                                            },
                                            title: Text(
                                              results[index].toString(),
                                            ),
                                          );
                                        }),
                                  ),
                                ],
                              ),
                            );
                          });
                      await Future.delayed(Duration(seconds: 2));

                      await Get.find<BlueController>().searchforservices();
                    },
                    icon: Icon(Icons.bluetooth_connected));
          }),
          Obx(
            () => Get.find<BlueController>().isConnected.value
                ? IconButton(
                    onPressed: () async {
                      await Get.find<BlueController>().disconnect();
                    },
                    icon: Icon(Icons.bluetooth_disabled))
                : IconButton(
                    onPressed: null, icon: Icon(Icons.bluetooth_disabled)),
          ),
        ],
      ),
      body: Column(children: [
        Obx(() {
          if (Get.find<BlueController>().isConnected.value) {
            return Container(
              child: Column(
                children: [
                  Obx(() {
                    if (Get.find<BlueController>().batteryServiceReady.value) {
                      return StreamBuilder<List<int>>(
                          initialData: const [0],
                          stream: Get.find<BlueController>().batteryChar?.value,
                          builder: (BuildContext context,
                                  AsyncSnapshot<List<int>> snapshot) =>
                              Text("Battery value : ${snapshot.data!.last}"));
                    } else {
                      return Text("No battery value.");
                    }
                  }),
                  Obx(() {
                    if (Get.find<BlueController>()
                        .pedometerServiceReady
                        .value) {
                      return StreamBuilder<List<int>>(
                          initialData: const [0],
                          stream:
                              Get.find<BlueController>().pedometerChar?.value,
                          builder: (BuildContext context,
                                  AsyncSnapshot<List<int>> snapshot) =>
                              Text(
                                  "Pedometer value : ${hexSnapshot2Dec(snapshot.data!)}"));
                    } else {
                      return Text("No pedometer value.");
                    }
                  }),
                  Obx(() {
                    if (Get.find<BlueController>().ledServiceReady.value) {
                      return StreamBuilder<List<int>>(
                          initialData: const [0],
                          stream: Get.find<BlueController>().ledChar?.value,
                          builder: (BuildContext context,
                                  AsyncSnapshot<List<int>> snapshot) =>
                              Text(
                                  "LED value : ${String.fromCharCodes(snapshot.data!)}"));
                    } else {
                      return Text("No LED value.");
                    }
                  }),
                ],
              ),
            );
          } else {
            return Text("Not connected to the device!");
          }
        }),
        MaterialButton(
          onPressed: () async {
            await Get.find<BlueController>().batteryChar?.read();
          },
          child: Text("Refresh battery"),
        ),
        MaterialButton(
          onPressed: () async {
            await Get.find<BlueController>().pedometerChar?.read();
          },
          child: Text("Refresh pedo"),
        ),
        MaterialButton(
          onPressed: () async {
            await Get.find<BlueController>().ledChar?.read();
          },
          child: Text("Refresh LED"),
        ),
        MaterialButton(
          onPressed: () async {
            String cmd = "";
            await Get.defaultDialog(
              title: 'Enter the command : ',
              content: TextField(
                onChanged: (value) {
                  cmd = value;
                },
                decoration: InputDecoration(hintText: "Enter the commmand : "),
              ),
              actions: <Widget>[
                MaterialButton(
                  color: Colors.red,
                  textColor: Colors.white,
                  child: Text('CANCEL'),
                  onPressed: () {
                    cmd = "";
                    Get.back();
                  },
                ),
                MaterialButton(
                  color: Colors.green,
                  textColor: Colors.white,
                  child: Text('OK'),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ],
            );

            if (!cmd.isEmpty) {
              await Get.find<BlueController>().ledChar?.write(cmd.codeUnits);
              print("SENDING COMMAND -> ${cmd}");
              await Get.find<BlueController>().ledChar?.read();
            } else {
              Get.snackbar('Error', 'Empty command!');
            }
          },
          child: Text("Set LED"),
        ),
      ]),
    );
  }
}
