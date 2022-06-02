import 'package:get/get.dart';
import 'package:blueshoe/controllers/bluetooth_controller.dart';
import 'package:blueshoe/controllers/loading_controller.dart';

class MyBindings extends Bindings {
  @override
  void dependencies() {
    // TODO: implement dependencies
    Get.put(BlueController());
    Get.put(LoadingController());
  }
}
