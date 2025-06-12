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
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Image.file(File(controller.imagePath), fit: BoxFit.cover),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add plants',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildPlantList(),
                  const Spacer(),
                  _buildActionButtons(),
                ],
              ),
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
                          // TODO: Replace with Image.asset
                          child: Container(
                            color: Colors.grey[300],
                            margin: const EdgeInsets.all(8),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(plant.name, textAlign: TextAlign.center),
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: controller.undo,
            child: const Text('Undo'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: controller.addPlant,
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }
}
