import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:blueshoe/screens/loading.dart';

class LoadingController extends GetxController {
  bool _loading = false;

  @override
  void onInit() {
    super.onInit();
    print("Loading Controller created!");
  }

  void showLoadingScreen(BuildContext context, {String title = "Syncing..."}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context) {
              return Scaffold(
                body: LoadingDialogShoeAnimation(
                  title: title,
                ),
              );
            }));
  }

  void closeLoadingScreen(BuildContext context) {
    Navigator.pop(context);
  }
}
