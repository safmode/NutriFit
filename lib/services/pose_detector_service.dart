import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class PoseDetectorService {
  late final FaceDetector _faceDetector;

  PoseDetectorService() {
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  /// Detects the pose/view from an image file
  /// Returns: 'front', 'right', 'back', or 'left'
  Future<String> detectPose(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        // No face detected - assume back view
        return 'back';
      }

      final face = faces.first;

      // Get head rotation angles
      final headEulerAngleY = face.headEulerAngleY; // Left/Right rotation
      final headEulerAngleZ = face.headEulerAngleZ; // Tilt

      // Determine pose based on Y-axis rotation
      // Y angle: -90 (left profile) to +90 (right profile)
      if (headEulerAngleY == null) {
        return 'front'; // Default if angle not available
      }

      if (headEulerAngleY.abs() < 15) {
        // Face looking straight at camera (-15 to +15 degrees)
        return 'front';
      } else if (headEulerAngleY > 15 && headEulerAngleY < 65) {
        // Face turned right (camera's perspective)
        return 'right';
      } else if (headEulerAngleY < -15 && headEulerAngleY > -65) {
        // Face turned left (camera's perspective)
        return 'left';
      } else {
        // Extreme angle - likely back view or strong profile
        return headEulerAngleY > 0 ? 'right' : 'left';
      }
    } catch (e) {
      print('Error detecting pose: $e');
      return 'front'; // Default fallback
    }
  }

  /// Detects pose with confidence scores for all views
  Future<Map<String, double>> detectPoseWithConfidence(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return {
          'front': 0.0,
          'right': 0.0,
          'left': 0.0,
          'back': 1.0,
        };
      }

      final face = faces.first;
      final headEulerAngleY = face.headEulerAngleY ?? 0.0;

      // Calculate confidence for each pose
      // The closer to the ideal angle, the higher the confidence
      final frontConfidence = _calculateConfidence(headEulerAngleY, 0, 20);
      final rightConfidence = _calculateConfidence(headEulerAngleY, 45, 30);
      final leftConfidence = _calculateConfidence(headEulerAngleY, -45, 30);
      final backConfidence = headEulerAngleY.abs() > 75 ? 0.8 : 0.0;

      return {
        'front': frontConfidence,
        'right': rightConfidence,
        'left': leftConfidence,
        'back': backConfidence,
      };
    } catch (e) {
      print('Error detecting pose with confidence: $e');
      return {
        'front': 1.0,
        'right': 0.0,
        'left': 0.0,
        'back': 0.0,
      };
    }
  }

  double _calculateConfidence(double angle, double target, double range) {
    final diff = (angle - target).abs();
    if (diff > range) return 0.0;
    return 1.0 - (diff / range);
  }

  void dispose() {
    _faceDetector.close();
  }
}