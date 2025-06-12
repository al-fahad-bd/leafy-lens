import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_design_with_plants/core/routes/app_pages.dart';

class HomeController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  Future<void> takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      // Navigate to design screen with the photo
      Get.toNamed(Routes.design, arguments: photo.path);
    }
  }

  Future<void> chooseFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Navigate to design screen with the image
      Get.toNamed(Routes.design, arguments: image.path);
    }
  }
}
