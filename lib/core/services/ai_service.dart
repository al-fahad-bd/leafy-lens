import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class AIService extends GetxController {
  final RxBool isLoading = false.obs;
  String? _apiToken;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _loadApiToken();
  }

  void _showSnackbar(String title, String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
    });
  }

  Future<void> _loadApiToken() async {
    try {
      await dotenv.load(fileName: "key.env");
      _apiToken = dotenv.env['REPLICATE_API_TOKEN'];
      if (_apiToken == null || _apiToken!.isEmpty) {
        debugPrint('AIService: API token not found in environment variables');
        _showSnackbar('Error', 'API token not found in environment variables');
        return;
      }
      _isInitialized = true;
      debugPrint('AIService: API token loaded successfully');
    } catch (e) {
      debugPrint('AIService: Error loading API token: $e');
      _showSnackbar('Error', 'Failed to load API token');
    }
  }

  Future<String?> transformImage({
    required File imageFile,
    required String prompt,
  }) async {
    if (_apiToken == null) {
      _showSnackbar('Error', 'API configuration not loaded');
      return null;
    }

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
            'num_inference_steps': 30,
          },
        }),
      );

      if (response.statusCode == 201) {
        final prediction = json.decode(response.body);
        final predictionId = prediction['id'];

        // Step 3: Poll for results
        return await _getPredictionResult(predictionId);
      } else {
        throw Exception('API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _showSnackbar('Error', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> generatePlantDesign(
      String baseImagePath, String plantName) async {
    try {
      if (!_isInitialized) {
        debugPrint(
            'AIService: Service not initialized, attempting to load API token');
        await _loadApiToken();
      }

      if (_apiToken == null) {
        debugPrint('AIService: API token is null after initialization attempt');
        _showSnackbar('Error',
            'API token not loaded. Please check your environment variables.');
        return null;
      }

      debugPrint('AIService: Reading base image file from: $baseImagePath');
      // Read the base image file
      final baseImageFile = File(baseImagePath);
      if (!await baseImageFile.exists()) {
        debugPrint(
            'AIService: Base image file does not exist at path: $baseImagePath');
        _showSnackbar('Error', 'Base image not found');
        return null;
      }

      // Read and resize the image
      debugPrint('AIService: Reading and resizing image');
      final imageBytes = await baseImageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('AIService: Failed to decode image');
        _showSnackbar('Error', 'Failed to process image');
        return null;
      }

      // Resize image to 1024x1024 while maintaining aspect ratio
      final resizedImage = img.copyResize(
        originalImage,
        width: 1024,
        height: 1024,
        interpolation: img.Interpolation.linear,
      );

      // Save resized image to temporary file
      final tempDir = await getTemporaryDirectory();
      final resizedImagePath =
          '${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedImageFile = File(resizedImagePath);
      await resizedImageFile
          .writeAsBytes(img.encodeJpg(resizedImage, quality: 90));

      debugPrint('AIService: Image resized and saved to: $resizedImagePath');

      // Convert resized image to base64
      final resizedImageBytes = await resizedImageFile.readAsBytes();
      final base64Image = base64Encode(resizedImageBytes);
      debugPrint(
          'AIService: Image converted to base64, length: ${base64Image.length}');

      // Prepare the prompt for the AI
      final prompt =
          'Add a realistic $plantName plant to this room, make it look natural and well-integrated with the space';
      debugPrint('AIService: Using prompt: $prompt');

      debugPrint('AIService: Making API request to Replicate');

      // Create prediction request
      final response = await http.post(
        Uri.parse('https://api.replicate.com/v1/predictions'),
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'version':
              'stability-ai/stable-diffusion:db21e45d3f7023abc2a46ee38a23973f6dce16bb082a930b0c49861f96d1e5bf',
          'input': {
            'prompt': prompt,
            'image': 'data:image/jpeg;base64,$base64Image',
            'num_inference_steps': 30,
            'guidance_scale': 7.5,
            'image_strength': 0.35,
            'negative_prompt':
                'blurry, low quality, distorted, unrealistic, artificial',
            'width': 768,
            'height': 768,
          },
        }),
      );

      // Clean up temporary resized image
      await resizedImageFile.delete();

      debugPrint('AIService: API Response Status Code: ${response.statusCode}');
      debugPrint('AIService: API Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final predictionId = data['id'];
        debugPrint('AIService: Prediction created with ID: $predictionId');

        // Poll for the result
        String? outputUrl;
        for (int i = 0; i < 30; i++) {
          // Try for 30 seconds
          debugPrint('AIService: Polling attempt ${i + 1}/30');
          await Future.delayed(const Duration(seconds: 1));
          final statusResponse = await http.get(
            Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
            headers: {
              'Authorization': 'Token $_apiToken',
            },
          );

          if (statusResponse.statusCode == 200) {
            final statusData = jsonDecode(statusResponse.body);
            debugPrint('AIService: Prediction status: ${statusData['status']}');
            if (statusData['status'] == 'succeeded') {
              outputUrl = statusData['output'][0];
              debugPrint(
                  'AIService: Prediction succeeded, output URL: $outputUrl');
              break;
            } else if (statusData['status'] == 'failed') {
              throw Exception('Prediction failed: ${statusData['error']}');
            }
          } else {
            debugPrint(
                'AIService: Status check failed with code: ${statusResponse.statusCode}');
            debugPrint('AIService: Status response: ${statusResponse.body}');
          }
        }

        if (outputUrl == null) {
          throw Exception('Prediction timed out');
        }

        // Download the generated image
        debugPrint('AIService: Downloading generated image from: $outputUrl');
        final imageResponse = await http.get(Uri.parse(outputUrl));
        if (imageResponse.statusCode == 200) {
          final outputPath =
              '${tempDir.path}/generated_design_${DateTime.now().millisecondsSinceEpoch}.png';
          await File(outputPath).writeAsBytes(imageResponse.bodyBytes);
          debugPrint('AIService: Image saved successfully at: $outputPath');
          return outputPath;
        } else {
          debugPrint(
              'AIService: Failed to download image, status code: ${imageResponse.statusCode}');
          throw Exception('Failed to download generated image');
        }
      } else {
        debugPrint(
            'AIService: API request failed with status ${response.statusCode}');
        debugPrint('AIService: Error response: ${response.body}');
        _showSnackbar('Error', 'Failed to generate design: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('AIService: Error in generatePlantDesign: $e');
      debugPrint('AIService: Stack trace: $stackTrace');
      _showSnackbar('Error', 'Failed to generate design: $e');
      return null;
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
      _showSnackbar('Upload Failed', 'Could not upload image: $e');
      return null;
    }
  }

  /// Polls Replicate API for prediction results.
  Future<String?> _getPredictionResult(String predictionId) async {
    if (_apiToken == null) {
      _showSnackbar('Error', 'API configuration not loaded');
      return null;
    }

    int attempts = 0;
    while (attempts < 10) {
      await Future.delayed(const Duration(seconds: 3));

      final response = await http.get(
        Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
        headers: {
          'Authorization': 'Token $_apiToken',
        },
      );

      final prediction = json.decode(response.body);
      if (prediction['status'] == 'succeeded') {
        return prediction['output']?[0];
      } else if (prediction['status'] == 'failed') {
        throw Exception('AI processing failed: ${prediction['error']}');
      }
      attempts++;
    }
    throw Exception('Prediction timed out');
  }
}
