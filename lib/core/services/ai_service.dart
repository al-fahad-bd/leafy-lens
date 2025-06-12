import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService extends GetxController {
  final RxBool isLoading = false.obs;
  late final String _apiToken;

  @override
  void onInit() {
    super.onInit();
    _apiToken = dotenv.env['REPLICATE_API_TOKEN'] ?? '';
    if (_apiToken.isEmpty) {
      throw Exception('REPLICATE_API_TOKEN not found in environment variables');
    }
  }

  Future<String?> transformImage({
    required File imageFile,
    required String prompt,
  }) async {
    isLoading.value = true;
    try {
      // Step 1: Upload image to Firebase Storage (or another CDN)
      final imageUrl = await _uploadImageToFirebase(imageFile);

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Step 2: Call Replicate API
      final response = await http.post(
        Uri.parse('https://api.replicate.com/v1/predictions'),
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'version':
              'ac732df83cea7fff18b8472768c88ad041fa750ff7682a21affe81863cbe77e4',
          'input': {
            'prompt': '$prompt, photorealistic, 4K, detailed greenery',
            'image': imageUrl,
            'scheduler': 'K_EULER',
            'num_inference_steps': 30, // Higher = better quality (but slower)
          },
        }),
      );

      if (response.statusCode == 201) {
        final prediction = json.decode(response.body);
        final predictionId = prediction['id'];

        // Step 3: Poll for results (Replicate may take a few seconds)
        return await _getPredictionResult(predictionId);
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Helper Methods ---

  /// Uploads image to Firebase Storage and returns its public URL.
  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'user_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      Get.snackbar('Upload Failed', 'Could not upload image: $e');
      return null;
    }
  }

  /// Polls Replicate API for prediction results.
  Future<String?> _getPredictionResult(String predictionId) async {
    int attempts = 0;
    while (attempts < 10) {
      // Try for ~30 seconds max
      await Future.delayed(Duration(seconds: 3));

      final response = await http.get(
        Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
        headers: {
          'Authorization': 'Token $_apiToken',
        },
      );

      final prediction = json.decode(response.body);
      if (prediction['status'] == 'succeeded') {
        return prediction['output']?[0]; // Transformed image URL
      } else if (prediction['status'] == 'failed') {
        throw Exception('AI processing failed: ${prediction['error']}');
      }
      attempts++;
    }
    throw Exception('Prediction timed out');
  }
}
