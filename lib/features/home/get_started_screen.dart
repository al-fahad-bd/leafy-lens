import 'package:ai_design_with_plants/features/home/get_started_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetStartedScreen extends GetView<GetStartedController> {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // TODO: Add image asset here
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            color: Colors.grey[300],
            child: const Center(child: Text('Image Placeholder')),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Transform Your Space with Plants',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: controller.navigateToSignUp,
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
