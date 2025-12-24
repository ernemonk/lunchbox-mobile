import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

/// Service for logging recipe generation inputs and outputs to a file.
/// Useful for debugging, quality analysis, and understanding user behavior.
class RecipeLogService {
  static const String _logFileName = 'recipe_generation_log.txt';

  /// Get the log file path
  static Future<File> _getLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_logFileName');
  }

  /// Log recipe generation input
  static Future<void> logInput({
    required String userId,
    required String diet,
    required int recipeCount,
    required bool hasAllergies,
    required String allergies,
    required String additionalInstructions,
    required bool useOnlyFridgeItems,
    required List<dynamic> fridgeIngredients,
  }) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toIso8601String();
      
      final logEntry = StringBuffer();
      logEntry.writeln('\n${'=' * 80}');
      logEntry.writeln('RECIPE GENERATION INPUT');
      logEntry.writeln('Timestamp: $timestamp');
      logEntry.writeln('User ID: $userId');
      logEntry.writeln('${'=' * 80}');
      logEntry.writeln('Diet: $diet');
      logEntry.writeln('Recipe Count: $recipeCount');
      logEntry.writeln('Has Allergies: $hasAllergies');
      if (hasAllergies) {
        logEntry.writeln('Allergies: $allergies');
      }
      if (additionalInstructions.isNotEmpty) {
        logEntry.writeln('Additional Instructions: $additionalInstructions');
      }
      logEntry.writeln('Use Only Fridge Items: $useOnlyFridgeItems');
      logEntry.writeln('Fridge Ingredients (${fridgeIngredients.length}): ${fridgeIngredients.join(', ')}');
      logEntry.writeln('-' * 80);
      
      await file.writeAsString(logEntry.toString(), mode: FileMode.append);
      print('[LOG] Input logged to ${file.path}');
    } catch (e) {
      print('[LOG ERROR] Failed to log input: $e');
    }
  }

  /// Log recipe generation output
  static Future<void> logOutput({
    required String userId,
    required List<Map<String, dynamic>> recipes,
    required Duration generationTime,
    String? errorMessage,
  }) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toIso8601String();
      
      final logEntry = StringBuffer();
      logEntry.writeln('RECIPE GENERATION OUTPUT');
      logEntry.writeln('Timestamp: $timestamp');
      logEntry.writeln('User ID: $userId');
      logEntry.writeln('Generation Time: ${generationTime.inSeconds}s');
      
      if (errorMessage != null) {
        logEntry.writeln('❌ ERROR: $errorMessage');
      } else {
        logEntry.writeln('✅ Success: ${recipes.length} recipes generated');
        logEntry.writeln('-' * 80);
        
        for (int i = 0; i < recipes.length; i++) {
          final recipe = recipes[i];
          logEntry.writeln('\nRECIPE ${i + 1}:');
          logEntry.writeln('Title: ${recipe['title'] ?? 'Untitled'}');
          
          if (recipe.containsKey('servings')) {
            logEntry.writeln('Servings: ${recipe['servings']}');
          }
          if (recipe.containsKey('cookingTime')) {
            logEntry.writeln('Cooking Time: ${recipe['cookingTime']}');
          }
          if (recipe.containsKey('difficulty')) {
            logEntry.writeln('Difficulty: ${recipe['difficulty']}');
          }
          
          final ingredients = recipe['ingredients'];
          if (ingredients is List) {
            logEntry.writeln('Ingredients (${ingredients.length}):');
            for (var ingredient in ingredients) {
              logEntry.writeln('  - $ingredient');
            }
          }
          
          final instructions = recipe['instructions'];
          if (instructions != null) {
            logEntry.writeln('Instructions:');
            if (instructions is List) {
              for (int j = 0; j < instructions.length; j++) {
                logEntry.writeln('  ${j + 1}. ${instructions[j]}');
              }
            } else {
              logEntry.writeln('  $instructions');
            }
          }
          
          logEntry.writeln('-' * 40);
        }
      }
      
      logEntry.writeln('${'=' * 80}\n');
      
      await file.writeAsString(logEntry.toString(), mode: FileMode.append);
      print('[LOG] Output logged to ${file.path}');
    } catch (e) {
      print('[LOG ERROR] Failed to log output: $e');
    }
  }

  /// Log recipe quality analysis
  static Future<void> logQualityAnalysis({
    required String userId,
    required Map<String, dynamic> recipe,
    required int qualityScore,
    required String grade,
    required List<String> issues,
  }) async {
    try {
      final file = await _getLogFile();
      final timestamp = DateTime.now().toIso8601String();
      
      final logEntry = StringBuffer();
      logEntry.writeln('\n${'~' * 80}');
      logEntry.writeln('QUALITY ANALYSIS');
      logEntry.writeln('Timestamp: $timestamp');
      logEntry.writeln('User ID: $userId');
      logEntry.writeln('Recipe: ${recipe['title'] ?? 'Untitled'}');
      logEntry.writeln('${'~' * 80}');
      logEntry.writeln('Quality Score: $qualityScore/100');
      logEntry.writeln('Grade: $grade');
      
      if (issues.isNotEmpty) {
        logEntry.writeln('Issues Found (${issues.length}):');
        for (var issue in issues) {
          logEntry.writeln('  ⚠️  $issue');
        }
      } else {
        logEntry.writeln('✅ No quality issues found!');
      }
      
      logEntry.writeln('${'~' * 80}\n');
      
      await file.writeAsString(logEntry.toString(), mode: FileMode.append);
      print('[LOG] Quality analysis logged to ${file.path}');
    } catch (e) {
      print('[LOG ERROR] Failed to log quality analysis: $e');
    }
  }

  /// Read the entire log file
  static Future<String> readLog() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'No log file found.';
    } catch (e) {
      return 'Error reading log: $e';
    }
  }

  /// Clear the log file
  static Future<void> clearLog() async {
    try {
      final file = await _getLogFile();
      if (await file.exists()) {
        await file.delete();
        print('[LOG] Log file cleared');
      }
    } catch (e) {
      print('[LOG ERROR] Failed to clear log: $e');
    }
  }

  /// Get log file path for sharing
  static Future<String> getLogFilePath() async {
    final file = await _getLogFile();
    return file.path;
  }

  /// Export log as JSON
  static Future<void> exportLogAsJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final jsonFile = File('${directory.path}/recipe_log_export.json');
      
      final log = await readLog();
      final export = {
        'exportedAt': DateTime.now().toIso8601String(),
        'logContent': log,
      };
      
      await jsonFile.writeAsString(jsonEncode(export));
      print('[LOG] Exported log to ${jsonFile.path}');
    } catch (e) {
      print('[LOG ERROR] Failed to export log: $e');
    }
  }
}
