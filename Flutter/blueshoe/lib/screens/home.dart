import 'dart:math';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:blueshoe/screens/loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';

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
                        SquaredMaterial(
                          onPressed: () {
                            Get.to(LoadingDialogShoeAnimation());
                          },
                          title: "CONNECT",
                          icon: Icons.bluetooth_connected,
                          color: kColorConnectGreen,
                        ),
                        SquaredMaterial(
                          onPressed: () {},
                          title: "DIS-CONN",
                          icon: Icons.bluetooth_disabled,
                          color: kColorDisconnectOrange,
                        ),
                        SquaredMaterial(
                          onPressed: () {},
                          title: "REFRESH",
                          icon: Icons.refresh,
                          color: kColorRefreshBlue,
                        ),
                        SquaredMaterial(
                          onPressed: () {},
                          title: "LOGS",
                          icon: Icons.book,
                          color: kColorLogsPurple,
                        ),
                        statusText(
                            text: Text(
                              "5/23/2021",
                              style: TextStyle(
                                  fontSize: 12.0, color: kColorStatusTextGrey),
                            ),
                            icon: Icons.timelapse),
                        statusText(
                            text: Text(
                              "100% Battery.",
                              style: TextStyle(
                                  fontSize: 12.0, color: kColorStatusTextGrey),
                            ),
                            icon: Icons.battery_charging_full)
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
            Container(
              height: 120,
              margin: EdgeInsets.only(left: 15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.ideographic,
                children: [
                  AnimatedFlipCounter(
                    value: 3,
                    textStyle: TextStyle(
                      fontSize: 93,
                      color: Colors.black,
                      fontFamily: 'racesport',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AnimatedFlipCounter(
                    value: 752,
                    decimalSeparator: ",",
                    prefix: ",",
                    textStyle: TextStyle(
                      fontSize: 60,
                      color: Colors.black,
                      fontFamily: 'racesport',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "  STEPS",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontFamily: 'racesport',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
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
  statusText({Key? key, required this.text, required this.icon})
      : super(key: key);

  final Text text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 15.0, top: 15.0),
      child: Row(children: [
        Icon(
          icon,
          color: kColorStatusTextGrey,
        ),
        SizedBox(
          width: 6,
        ),
        text
      ]),
    );
  }
}

class SquaredMaterial extends StatelessWidget {
  SquaredMaterial(
      {Key? key,
      required this.onPressed,
      required this.title,
      required this.icon,
      required this.color})
      : super(key: key);

  final VoidCallback onPressed;
  final String title;
  final IconData icon;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 90,
      margin: EdgeInsets.symmetric(vertical: 15.0),
      decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          // gradient: LinearGradient(
          //   colors: [
          //     Color.fromRGBO(255, 143, 158, 1),
          //     Color.fromRGBO(255, 188, 143, 1),
          //   ],
          //   begin: Alignment.centerLeft,
          //   end: Alignment.centerRight,
          // ),
          borderRadius: BorderRadius.all(
            Radius.circular(25.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000),
              spreadRadius: 0,
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ]),
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
