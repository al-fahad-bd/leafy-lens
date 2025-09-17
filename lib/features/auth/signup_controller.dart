import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ai_design_with_plants/core/routes/app_pages.dart';

class SignUpController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUp() {
    debugPrint('Signing up...');
    Get.offAllNamed(Routes.home); // Navigate to home after sign up
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
