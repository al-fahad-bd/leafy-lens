import 'package:ai_design_with_plants/features/home/get_started_controller.dart';
import 'package:get/get.dart';

class GetStartedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GetStartedController>(() => GetStartedController());
  }
}
