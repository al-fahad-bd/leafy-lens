import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ai_design_with_plants/core/services/ai_service.dart';
import 'package:ai_design_with_plants/features/design/design_screen.dart';
import 'package:ai_design_with_plants/features/design/design_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: "key.env");
    debugPrint('Environment variables loaded successfully');
  } catch (e) {
    debugPrint('Error loading environment variables: $e');
  }

  // Initialize services and controllers
  Get.put(AIService());
  Get.put(DesignController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AI Design with Plants',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const DesignScreen(),
    );
  }
}
