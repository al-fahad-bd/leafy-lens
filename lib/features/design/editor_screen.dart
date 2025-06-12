import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ai_design_with_plants/features/design/design_controller.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class EditorScreen extends GetView<DesignController> {
  const EditorScreen({super.key});

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<void> _saveImage(String imageUrl) async {
    try {
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        Get.snackbar('Error', 'Storage permission is required to save images');
        return;
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final fileName = 'AI_Design_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      Get.snackbar('Success', 'Image saved to ${file.path}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to save image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Editor'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Original/Transformed Image Preview
                Center(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const CircularProgressIndicator();
                    } else if (controller.transformedImageUrl.value.isNotEmpty) {
                      return Image.network(controller.transformedImageUrl.value);
                    } else if (controller.originalImageFile.value != null) {
                      return Image.file(controller.originalImageFile.value!);
                    } else {
                      return const Text('No image selected');
                    }
                  }),
                ),
                // You can add more layers here for overlays if needed
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Slider for plant density
                Obx(
                  () => Slider(
                    value: controller.plantDensity.value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: controller.plantDensity.value.toStringAsFixed(1),
                    onChanged: (newValue) {
                      controller.setPlantDensity(newValue);
                    },
                  ),
                ),
                const Text('Plant Density'),
                ElevatedButton(
                  onPressed: controller.transformImageWithAI,
                  child: Obx(() => controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text('Transform Image')),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (controller.transformedImageUrl.value.isNotEmpty) {
                          await _saveImage(
                            controller.transformedImageUrl.value,
                          );
                        } else {
                          Get.snackbar('Info', 'No transformed image to save');
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (controller.transformedImageUrl.value.isNotEmpty) {
                          await Share.share(controller.transformedImageUrl.value);
                        } else {
                          Get.snackbar('Info', 'No transformed image to share');
                        }
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}