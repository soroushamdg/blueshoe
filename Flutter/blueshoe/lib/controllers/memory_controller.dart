import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class MemoryController extends GetxController {
  RxInt steps = 0.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    var box = GetStorage();
    if (box.read('steps') != null) {
      var _steps = box.read('steps');
      steps.value = int.parse(_steps);
    }

    ever(steps, (value) {
      try {
        box.write('steps', steps);
        print('wrote new steps');
        print(box.read('steps').toString());
      } catch (e) {
        print('error' + e.toString());
      }
    });
  }
}
