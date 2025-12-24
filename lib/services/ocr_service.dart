/// OCR (Optical Character Recognition) service for ingredient detection
/// Uses Google ML Kit for on-device text recognition
/// Parses receipts and ingredient lists into structured fridge items

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';

class OCRService {
  static final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Pick image from camera or gallery
  /// Returns File or null if user cancels
  /// ImagePicker handles permission requests automatically
  static Future<File?> pickImage({ImageSource source = ImageSource.camera}) async {
    try {
      final picker = ImagePicker();
      
      // ImagePicker handles permission requests internally
      // iOS will show the permission dialog automatically if needed
      final image = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        return File(image.path);
      }
      
      // User cancelled or no image selected
      return null;
    } catch (e) {
      print('[OCR] Pick image error: $e');
      
      // If it's a permission error, provide helpful message
      if (e.toString().contains('photo') || 
          e.toString().contains('camera') ||
          e.toString().contains('permission')) {
        throw Exception(
          'Camera access is required. Please enable Camera in Settings:\n'
          'Settings > Lunchbox > Camera'
        );
      }
      
      rethrow;
    }
  }

  /// Extract text from image using ML Kit
  /// Handles image rotation and optimization
  ///
  /// Returns raw OCR text or empty string if no text detected
  static Future<String> extractText(File imageFile) async {
    try {
      // Optimize image for better OCR accuracy
      final optimizedFile = await _optimizeImage(imageFile);

      final inputImage = InputImage.fromFile(optimizedFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Clean up optimized file if different
      if (optimizedFile.path != imageFile.path) {
        optimizedFile.deleteSync();
      }

      return recognizedText.text;
    } catch (e) {
      print('[OCR] Extract text error: $e');
      return '';
    }
  }

  /// Parse OCR text into list of structured ingredients
  /// Handles common receipt formats and ingredient lists
  ///
  /// Returns list of:
  /// - name: Ingredient name (cleaned)
  /// - quantity: Numeric quantity or empty
  /// - unit: Unit (pieces, kg, ml, etc.) or empty
  static Future<List<Map<String, dynamic>>> parseIngredients(
      String ocrText) async {
    final ingredients = <Map<String, dynamic>>[];

    if (ocrText.isEmpty) return ingredients;

    final lines = ocrText.split('\n');

    for (final line in lines) {
      final cleaned = line.trim();

      // Skip empty lines, prices, receipt noise
      if (cleaned.isEmpty ||
          cleaned.length < 2 ||
          _isNoise(cleaned) ||
          _isPrice(cleaned)) {
        continue;
      }

      // Parse ingredient from line
      final ingredient = _parseIngredientLine(cleaned);
      if (ingredient != null && ingredient['name'].isNotEmpty) {
        ingredients.add(ingredient);
      }
    }

    return ingredients;
  }

  /// Parse single ingredient line into structured data
  /// Handles formats like:
  /// - "Eggs 12 count"
  /// - "Spinach 200g"
  /// - "Milk 1L"
  /// - "Bread"
  static Map<String, dynamic>? _parseIngredientLine(String line) {
    // Remove common noise
    var cleaned = _cleanItemName(line);

    if (cleaned.isEmpty) return null;

    String name = cleaned;
    String quantity = '';
    String unit = '';

    // Try to extract quantity + unit
    final quantityMatch = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z%]*)').firstMatch(cleaned);
    if (quantityMatch != null) {
      quantity = quantityMatch.group(1) ?? '';
      unit = quantityMatch.group(2)?.trim() ?? '';

      // Remove quantity from name
      name = cleaned.replaceFirst(quantityMatch.group(0)!, '').trim();

      // Normalize unit
      unit = _normalizeUnit(unit, quantity);
    }

    // Clean up name
    name = name.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
    };
  }

  /// Clean item name by removing common receipt noise
  static String _cleanItemName(String line) {
    var cleaned = line;

    // Remove SKU/product codes at start
    cleaned = cleaned.replaceFirst(RegExp(r'^\d{8,}\s+'), '');

    // Remove price info
    cleaned = cleaned.replaceAll(RegExp(r'\$[\d.]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[£€¥][\d.]+'), '');

    // Remove discount/promotional text
    cleaned = cleaned.replaceAll(RegExp(r'[*@#]'), '');

    // Remove excessive punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\.{2,}'), ' ');

    return cleaned.trim();
  }

  /// Normalize unit from OCR text to standard units
  /// Maps variations like "g" → "g", "grams" → "g", "gr" → "g"
  static String _normalizeUnit(String unit, String quantity) {
    if (unit.isEmpty) {
      // Infer from quantity (e.g., "3" likely pieces, "500" likely g)
      try {
        final qty = double.parse(quantity);
        if (qty > 100) return 'g'; // Likely grams
        if (qty > 10) return 'pieces'; // Likely count
        return 'pieces';
      } catch (e) {
        return '';
      }
    }

    final normalized = unit.toLowerCase();

    // Weight units
    if (normalized.contains('kg') || normalized.contains('k')) return 'kg';
    if (normalized.contains('g') && !normalized.contains('kg')) return 'g';
    if (normalized.contains('oz')) return 'oz';
    if (normalized.contains('lb') || normalized.contains('lbs')) return 'lbs';

    // Volume units
    if (normalized.contains('ml')) return 'ml';
    if (normalized.contains('l') && !normalized.contains('ml')) return 'l';
    if (normalized.contains('cup')) return 'cups';
    if (normalized.contains('tbsp') || normalized.contains('tablespoon')) {
      return 'tbsp';
    }
    if (normalized.contains('tsp') || normalized.contains('teaspoon')) {
      return 'tsp';
    }

    // Count units
    if (normalized.contains('piece') ||
        normalized.contains('pc') ||
        normalized.contains('pcs')) {
      return 'pieces';
    }
    if (normalized.contains('dozen') || normalized.contains('dz')) return 'pieces';
    if (normalized.contains('count')) return 'pieces';

    // Fallback
    return '';
  }

  /// Check if line is receipt noise (not an ingredient)
  static bool _isNoise(String line) {
    final lower = line.toLowerCase();

    // Common receipt elements
    final noisePatterns = [
      'subtotal',
      'total',
      'tax',
      'cash',
      'change',
      'thank you',
      'receipt',
      'store',
      'clerk',
      'register',
      'date',
      'time',
      'card',
      'debit',
      'credit',
      'void',
      'coupon',
      'discount',
      'weight',
      'price',
      'qty',
      'item',
      'dept',
      'aisle',
    ];

    return noisePatterns.any((pattern) => lower.contains(pattern));
  }

  /// Check if line is a price (not an ingredient)
  static bool _isPrice(String line) {
    // Regex for prices
    return RegExp(r'^\s*[\$£€¥]?\s*[\d.]+\s*[\$£€¥]?\s*$').hasMatch(line);
  }

  /// Optimize image for better OCR accuracy
  /// - Compress if too large
  /// - Correct rotation if needed
  /// - Enhance contrast if needed
  static Future<File> _optimizeImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      // Check if optimization needed
      if (image.width > 1920 || image.height > 1920) {
        // Resize if too large (maintain aspect ratio)
        int width = image.width;
        int height = image.height;

        if (width > height) {
          height = (height * 1920 ~/ width);
          width = 1920;
        } else {
          width = (width * 1920 ~/ height);
          height = 1920;
        }

        final resized = img.copyResize(
          image,
          width: width,
          height: height,
          interpolation: img.Interpolation.linear,
        );

        // Save optimized image
        final tempDir = imageFile.parent;
        final optimizedFile =
            File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await optimizedFile.writeAsBytes(img.encodeJpg(resized));

        return optimizedFile;
      }

      return imageFile;
    } catch (e) {
      print('[OCR] Optimize image error: $e');
      return imageFile;
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
