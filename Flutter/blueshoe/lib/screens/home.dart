import 'dart:math';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:blueshoe/controllers/bluetooth_controller.dart';
import 'package:blueshoe/controllers/loading_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../functions.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConnectButton(),
                        DisconnectButton(),
                        RefreshButton(),
                        Obx(() {
                          return (Get.find<BlueController>().isConnected.value)
                              ? statusText(
                                  text: "CONNECTED",
                                  color: kColorConnectGreen,
                                  icon: Icons.bluetooth_connected)
                              : statusText(
                                  text: "DISCONNECTED",
                                  color: kColorDisconnectOrange,
                                  icon: Icons.bluetooth_disabled);
                        }),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: RightHandShoe(),
                  )
                ],
              ),
            ),
            Obx(() {
              if (Get.find<BlueController>().pedometerServiceReady.value) {
                return StreamBuilder<List<int>>(
                    initialData: const [0],
                    stream: Get.find<BlueController>().pedometerChar?.value,
                    builder: (BuildContext context,
                            AsyncSnapshot<List<int>> snapshot) =>
                        CounterText(steps: hexSnapshot2Dec(snapshot.data!)));
              } else {
                return CounterText(steps: 0);
              }
            }),
          ],
        ),
      ),
    );
  }
}

class RefreshButton extends StatelessWidget {
  const RefreshButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Get.find<BlueController>().isConnected.value
        ? SquaredMaterial(
            onPressed: () async {
              Get.find<LoadingController>()
                  .showLoadingScreen(context, title: "Syncing...");

              await Future.delayed(Duration(seconds: 3));

              await Get.find<BlueController>().searchforservices();

              Get.find<LoadingController>().closeLoadingScreen(context);
            },
            title: "REFRESH",
            icon: Icons.refresh,
            color: kColorRefreshBlue,
          )
        : SquaredMaterial(
            onPressed: null,
            title: "REFRESH",
            icon: Icons.refresh,
            color: kColorRefreshBlue,
          ));
  }
}

class DisconnectButton extends StatelessWidget {
  const DisconnectButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Get.find<BlueController>().isConnected.value
        ? SquaredMaterial(
            onPressed: () async {
              Get.find<LoadingController>()
                  .showLoadingScreen(context, title: "Disconnecting...");

              await Future.delayed(Duration(seconds: 3));

              await Get.find<BlueController>().disconnect();

              Get.find<LoadingController>().closeLoadingScreen(context);
            },
            title: "DIS-CONN",
            icon: Icons.bluetooth_disabled,
            color: kColorDisconnectOrange,
          )
        : SquaredMaterial(
            onPressed: null,
            title: "DIS-CONN",
            icon: Icons.bluetooth_disabled,
            color: kColorDisconnectOrange,
          ));
  }
}

class ConnectButton extends StatelessWidget {
  const ConnectButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => !Get.find<BlueController>().isConnected.value
        ? SquaredMaterial(
            onPressed: () async {
              Get.find<LoadingController>()
                  .showLoadingScreen(context, title: "Searching...");
              await Get.find<BlueController>().startScan();
              await Future.delayed(const Duration(seconds: 2), () {});
              List<String> results = Get.find<BlueController>().scanneddevices;

              Get.find<LoadingController>().closeLoadingScreen(context);

              await showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      height: 300.0,
                      padding: EdgeInsets.symmetric(
                          horizontal: 15.0, vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Choose your device : ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24.0),
                          ),
                          Expanded(
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    onTap: () async {
                                      Get.find<LoadingController>()
                                          .showLoadingScreen(context,
                                              title: "Connecting...");

                                      await Get.find<BlueController>()
                                          .connectDevice(results[index]);
                                      await Future.delayed(
                                          Duration(seconds: 3));
                                      bool connected =
                                          Get.find<BlueController>()
                                              .isConnected
                                              .value;
                                      Get.find<LoadingController>()
                                          .closeLoadingScreen(context);

                                      if (connected) {
                                        Get.back();
                                      } else {
                                        Get.snackbar(
                                          'Oops!',
                                          'Couldn\'t find the device',
                                        );
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
              if (Get.find<BlueController>().isConnected.value) {
                Get.find<LoadingController>()
                    .showLoadingScreen(context, title: "Syncing...");

                await Future.delayed(Duration(seconds: 3));

                await Get.find<BlueController>().searchforservices();

                Get.find<LoadingController>().closeLoadingScreen(context);
              } else {
                Get.snackbar(
                  'Oops!',
                  'Couldn\'t connect to the device',
                );
              }
            },
            title: "CONNECT",
            icon: Icons.bluetooth_connected,
            color: kColorConnectGreen,
          )
        : SquaredMaterial(
            onPressed: null,
            title: "CONNECT",
            icon: Icons.bluetooth_connected,
            color: kColorConnectGreen,
          ));
  }
}

class CounterText extends StatelessWidget {
  CounterText({
    required this.steps,
  });

  final int steps;

  int firstStageDigits() {
    if (steps.toString().length <= 3) {
      return 0;
    } else {
      return int.parse(
          steps.toString().substring(0, steps.toString().length - 3));
    }
  }

  int secondStageDigits() {
    if (steps.toString().length > 3) {
      return int.parse(steps
          .toString()
          .substring(steps.toString().length - 3, steps.toString().length));
    } else {
      return steps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: EdgeInsets.only(left: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.ideographic,
        children: [
          AnimatedFlipCounter(
            value: firstStageDigits(),
            textStyle: TextStyle(
              fontSize: 84,
              color: Colors.black,
              fontFamily: 'racesport',
              fontWeight: FontWeight.bold,
            ),
          ),
          AnimatedFlipCounter(
            value: secondStageDigits(),
            decimalSeparator: ",",
            prefix: ",",
            wholeDigits: 3,
            textStyle: TextStyle(
              fontSize: 51,
              color: Colors.black,
              fontFamily: 'racesport',
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "  STEPS",
            style: TextStyle(
              fontSize: 21,
              color: Colors.black,
              fontFamily: 'racesport',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RightHandShoe extends StatelessWidget {
  const RightHandShoe({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
            left: 60,
            right: -300,
            top: 0,
            bottom: 36,
            child: Transform.rotate(
              angle: -pi / 18,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "GOOD,\nMORNING",
                    style: TextStyle(
                      fontFamily: 'racesport',
                      fontSize: 50,
                      color: kColorGoodMorningWhite,
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                    color: kColorBackgroundGreen,
                    borderRadius: BorderRadius.all(
                      Radius.circular(30.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        spreadRadius: 0,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      )
                    ]),
              ),
            )),
        Positioned(
          right: -180,
          bottom: 60,
          child: Hero(
              tag: 'shoe', child: Image.asset('assets/animation/frame_1.png')),
          height: Get.width * 1.2,
        ),
      ],
    );
  }
}

class statusText extends StatelessWidget {
  statusText(
      {Key? key, required this.text, required this.color, required this.icon})
      : super(key: key);

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 15.0, top: 15.0),
      child: Row(children: [
        Icon(
          icon,
          color: color,
        ),
        SizedBox(
          width: 6,
        ),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 11.0),
        ),
      ]),
    );
  }
}

class SquaredMaterial extends StatelessWidget {
  SquaredMaterial({
    Key? key,
    this.onPressed,
    required this.title,
    required this.icon,
    required this.color,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 90,
      margin: EdgeInsets.symmetric(vertical: 15.0),
      decoration: BoxDecoration(
          color: (onPressed != null) ? Color(0xFFF5F5F5) : Color(0x86D2D2D2),
          borderRadius: BorderRadius.all(
            Radius.circular(25.0),
          ),
          boxShadow: (onPressed != null)
              ? [
                  BoxShadow(
                    color: Color(0x26000000),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ]
              : null),
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 42.0,
              ),
              Text(
                title,
                style: TextStyle(color: color),
              )
            ],
          ),
        ),
      ),
    );
  }
}
