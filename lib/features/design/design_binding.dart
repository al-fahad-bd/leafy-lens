import 'package:ai_design_with_plants/core/services/ai_service.dart';
import 'package:ai_design_with_plants/features/design/design_controller.dart';
import 'package:get/get.dart';

class DesignBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AIService>(() => AIService());
    Get.lazyPut<DesignController>(() => DesignController());
  }
}
