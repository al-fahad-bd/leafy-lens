import 'package:flutter/material.dart';
import 'dart:io';

import 'package:ai_design_with_plants/core/services/ai_service.dart';
import 'package:get/get.dart';

class Plant {
  final String name;
  final String imageUrl; // Changed from 'image' to 'imageUrl' for network images

  Plant({required this.name, required this.imageUrl});
}

class DesignController extends GetxController {
  late final String imagePath;
  final RxList<Plant> availablePlants = <Plant>[].obs;
  final Rxn<Plant> selectedPlant = Rxn<Plant>();

  final AIService _aiService = Get.find<AIService>();

  final RxBool isLoading = false.obs;
  final Rxn<File> originalImageFile = Rxn<File>();
  final RxString transformedImageUrl = ''.obs;
  final RxDouble plantDensity = 0.5.obs; // Initial plant density

  @override
  void onInit() {
    super.onInit();
    imagePath = Get.arguments;
    originalImageFile.value = File(imagePath);
    loadPlants();
  }

  void loadPlants() {
    // TODO: Load from a service or API
    availablePlants.value = [
      Plant(name: 'Fiddle Leaf Fig', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Ficus_lyrata_001.jpg/800px-Ficus_lyrata_001.jpg'),
      Plant(name: 'Snake Plant', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Sansevieria_trifasciata_001.jpg/800px-Sansevieria_trifasciata_001.jpg'),
      Plant(name: 'Monstera', imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Monstera_deliciosa2.jpg/800px-Monstera_deliciosa2.jpg'),
      // Add more plants with network image URLs
    ];
  }

  void selectPlant(Plant plant) {
    selectedPlant.value = plant;
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
}
