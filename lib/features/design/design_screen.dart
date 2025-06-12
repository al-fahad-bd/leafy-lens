import 'dart:io';
import 'package:ai_design_with_plants/features/design/design_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DesignScreen extends GetView<DesignController> {
  const DesignScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design with Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: controller.saveDesign,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview Section
          Expanded(
            flex: 2,
            child: Obx(() {
              if (controller.selectedImagePath.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: controller.selectImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: controller.captureImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              if (controller.isGenerating.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating design...'),
                    ],
                  ),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(
                      controller.generatedDesignPath.value ??
                          controller.selectedImagePath.value!,
                    ),
                    fit: BoxFit.cover,
                  ),
                  if (controller.generatedDesignPath.value == null)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: controller.generateDesign,
                        child: const Icon(Icons.auto_fix_high),
                      ),
                    ),
                ],
              );
            }),
          ),

          // Plant Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a Plant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPlantList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantList() {
    return SizedBox(
      height: 150,
      child: Obx(
        () => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.availablePlants.length,
          itemBuilder: (context, index) {
            final plant = controller.availablePlants[index];
            return GestureDetector(
              onTap: () => controller.selectPlant(plant),
              child: Obx(() {
                final isSelected = controller.selectedPlant.value == plant;
                return Card(
                  elevation: isSelected ? 8 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              plant.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            plant.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
