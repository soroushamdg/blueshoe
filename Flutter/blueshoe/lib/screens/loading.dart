import 'dart:io';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:blueshoe/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_sequence_animator/image_sequence_animator.dart';

class LoadingDialogShoeAnimation extends StatelessWidget {
  ImageSequenceAnimatorState? offlineImageSequenceAnimator;

  void onReadyToPlay(ImageSequenceAnimatorState _imageSequenceAnimator) async {
    await Future.delayed(Duration(milliseconds: 300));

    offlineImageSequenceAnimator = _imageSequenceAnimator;

    offlineImageSequenceAnimator?.play();
  }

  Future<void> playrewind() async {
    offlineImageSequenceAnimator!.rewind();

    await Future.delayed(Duration(
        milliseconds: offlineImageSequenceAnimator!.totalTime.toInt()));
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: kColorBackgroundGreen,
        width: Get.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 300.0,
              width: 300.0,
              child: Hero(
                tag: 'shoe',
                child: ImageSequenceAnimator(
                  "assets/animation",
                  "frame_",
                  1,
                  0,
                  "png",
                  24,
                  // waitUntilCacheIsComplete: true,
                  isAutoPlay: false,
                  onReadyToPlay: onReadyToPlay,
                ),
              ),
            ),
            Text(
              "SYNCING...",
              style: TextStyle(
                  color: Colors.white, fontFamily: 'racesport', fontSize: 36.0),
            ),
            SizedBox(
              height: 30.0,
            ),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
