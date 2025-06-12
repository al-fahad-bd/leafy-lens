import 'package:flutter/material.dart';
import 'dart:io';

import 'package:ai_design_with_plants/core/services/ai_service.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class Plant {
  final String name;
  final String imageUrl; // Changed from 'image' to 'imageUrl' for network images

  Plant({required this.name, required this.imageUrl});
}

class DesignController extends GetxController {
  // --- State Variables ---
  final RxList<Plant> availablePlants = <Plant>[].obs;
  final Rx<Plant?> selectedPlant = Rx<Plant?>(null);
  final Rx<String?> selectedImagePath = Rx<String?>(null);
  final Rx<String?> generatedDesignPath = Rx<String?>(null);
  final RxBool isGenerating = false.obs;

  late final AIService _aiService;
  final RxBool isLoading = false.obs;
  final Rxn<File> originalImageFile = Rxn<File>();
  final RxString transformedImageUrl = ''.obs;
  final RxDouble plantDensity = 0.5.obs; // Initial plant density

  @override
  void onInit() {
    super.onInit();
    debugPrint('DesignController: Initializing...');
    try {
      _aiService = Get.find<AIService>();
      debugPrint('DesignController: AIService found successfully');
      loadPlants();
      debugPrint('DesignController: Plants loaded successfully');
    } catch (e) {
      debugPrint('DesignController: Error during initialization - $e');
    }
  }

  void loadPlants() {
    availablePlants.value = [
      Plant(
        name: 'Fiddle Leaf Fig',
        imageUrl:
            'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcSAVvM8rvGbPioyUTiP8O-Kc672exAzcBF5qWiFnh3MUr0QNNgviILyX3KvxVQ1YIlNbLUFfpXCNeb3VrmPV6OmlQ',
      ),
      Plant(
        name: 'Snake Plant',
        imageUrl:
            'https://images.pexels.com/photos/2123482/pexels-photo-2123482.jpeg',
      ),
      Plant(
        name: 'Monstera Deliciosa',
        imageUrl:
            'https://images.pexels.com/photos/5858235/pexels-photo-5858235.jpeg',
      ),
      Plant(
        name: 'Peace Lily',
        imageUrl:
            'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcSH65Aii9kzktN7DLDbNjdgYmde7RlgCPSxxXRis_oFQD2SySF3C9cvEeqkLwSHgJMY_a6JyWFkeTftV89k9WsmnQ',
      ),
      Plant(
        name: 'ZZ Plant',
        imageUrl:
            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/Zamioculcas_zamiifolia_Chameleon_1.jpg/800px-Zamioculcas_zamiifolia_Chameleon_1.jpg',
      ),
      Plant(
        name: 'Pothos',
        imageUrl:
            'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcR68AE3DztD0TYDWUExmTVch2x8NxYpNgvnB4SMuHgyGHkFQ9i4Ge72uIG2hQYAc3jfKF9t2tye9jbjYugyBxXQNA',
      ),
      Plant(
        name: 'Bird of Paradise',
        imageUrl:
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS8V1lLbVt-E3fcmfuhljX7OuFDrILi3iLPGBRlzOcIGKPgzbJVAHtDFGBS0nmqsPS2gYVBfUHQ_7Z68lpwEDkQPA',
      ),
      Plant(
        name: 'Chinese Evergreen',
        imageUrl:
            'https://www.gardendesign.com/pictures/images/900x705Max/site_3/igneous-timeless-tides-chinese-evergreen-aglaonema-commutatum-proven-winners_19182.jpg',
      ),
    ];
  }

  void selectPlant(Plant plant) {
    selectedPlant.value = plant;
  }

  Future<void> selectImage() async {
    debugPrint('DesignController: Starting image selection from gallery');
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        debugPrint(
          'DesignController: Image selected successfully from gallery - ${image.path}',
        );
        selectedImagePath.value = image.path;
        generatedDesignPath.value = null;
      } else {
        debugPrint('DesignController: No image selected from gallery');
      }
    } catch (e) {
      debugPrint('DesignController: Error selecting image from gallery - $e');
      Get.snackbar(
        'Error',
        'Failed to select image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> captureImage() async {
    debugPrint('DesignController: Starting image capture from camera');
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        debugPrint(
          'DesignController: Image captured successfully - ${image.path}',
        );
        selectedImagePath.value = image.path;
        generatedDesignPath.value = null;
      } else {
        debugPrint('DesignController: No image captured from camera');
      }
    } catch (e) {
      debugPrint('DesignController: Error capturing image - $e');
      Get.snackbar(
        'Error',
        'Failed to capture image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> generateDesign() async {
    try {
      debugPrint('DesignController: Starting design generation');
      if (selectedPlant.value == null) {
        debugPrint('DesignController: No plant selected');
        _showSnackbar('Error', 'Please select a plant first');
        return;
      }

      if (selectedImagePath.value == null) {
        debugPrint('DesignController: No image selected');
        _showSnackbar('Error', 'Please select or capture an image first');
        return;
      }

      debugPrint(
          'DesignController: Starting AI design generation with plant: ${selectedPlant.value!.name}');
      debugPrint(
          'DesignController: Using image path: ${selectedImagePath.value}');

      final generatedPath = await _aiService.generatePlantDesign(
        selectedImagePath.value!,
        selectedPlant.value!.name,
      );

      debugPrint('DesignController: Generated path: $generatedPath');

      if (generatedPath != null) {
        debugPrint('DesignController: Design generated successfully');
        generatedDesignPath.value = generatedPath;
        _showSnackbar('Success', 'Design generated successfully!');
      } else {
        debugPrint('DesignController: Design generation returned null path');
        _showSnackbar('Error', 'Failed to generate design. Please try again.');
      }
    } catch (e, stackTrace) {
      debugPrint('DesignController: Error in generateDesign: $e');
      debugPrint('DesignController: Stack trace: $stackTrace');
      _showSnackbar('Error', 'Failed to generate design: $e');
    } finally {
      debugPrint('DesignController: Design generation process completed');
    }
  }

  Future<void> saveDesign() async {
    debugPrint('DesignController: Starting design save process');

    if (generatedDesignPath.value == null) {
      debugPrint('DesignController: No design to save');
      Get.snackbar(
        'Error',
        'No design to save',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      debugPrint('DesignController: Requesting storage permission');
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        debugPrint('DesignController: Storage permission denied');
        Get.snackbar(
          'Error',
          'Storage permission is required to save the design',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      debugPrint('DesignController: Getting external storage directory');
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        debugPrint('DesignController: Could not access storage directory');
        Get.snackbar(
          'Error',
          'Could not access storage directory',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'plant_design_$timestamp.png';
      final savedPath = '${directory.path}/$fileName';

      debugPrint('DesignController: Saving design to - $savedPath');
      await File(generatedDesignPath.value!).copy(savedPath);
      debugPrint('DesignController: Design saved successfully');

      Get.snackbar(
        'Success',
        'Design saved to gallery',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('DesignController: Error saving design - $e');
      Get.snackbar(
        'Error',
        'Failed to save design: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void addPlant() {
    // TODO: Logic to add selected plant to the design
    debugPrint('Adding ${selectedPlant.value?.name}');
  }

  void undo() {
    // TODO: Logic to undo the last action
    debugPrint('Undo');
  }

  void setPlantDensity(double value) {
    plantDensity.value = value;
  }

  Future<void> transformImageWithAI() async {
    if (originalImageFile.value == null) {
      Get.snackbar('Error', 'No image selected for transformation.');
      return;
    }

    isLoading.value = true;
    String prompt = 'add indoor plants to this room with density ${plantDensity.value}';

    if (selectedPlant.value != null) {
      prompt += ' focusing on ${selectedPlant.value!.name} style plants';
    }

    final String? imageUrl = await _aiService.transformImage(
      imageFile: originalImageFile.value!,
      prompt: prompt,
    );

    if (imageUrl != null) {
      transformedImageUrl.value = imageUrl;
    }
    isLoading.value = false;
  }

  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
