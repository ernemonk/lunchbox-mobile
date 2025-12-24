import 'package:flutter_test/flutter_test.dart';
import 'package:lunchbox/services/recipe_quality_service.dart';

void main() {
  print('\n🧪 ========== RECIPE QUALITY TESTS WITH SCORES ==========\n');
  
  group('Recipe Quality Examples', () {
    test('Excellent Recipe - Full Details', () {
      final recipe = {
        'title': 'Keto Chicken Breast with Garlic Butter',
        'ingredients': ['chicken breast', 'butter', 'garlic', 'salt', 'pepper', 'olive oil'],
        'instructions': 'Heat olive oil in a large pan over medium-high heat. Season chicken with salt and pepper. Cook chicken for 6-7 minutes per side until golden brown and cooked through. In the last minute, add butter and minced garlic. Spoon the garlic butter over the chicken. Serve hot.',
        'servings': '4',
        'cookingTime': '20 minutes',
        'difficulty': 'Easy',
        'cuisine': 'Keto',
      };

      final score = RecipeQualityService.calculateQualityScore(recipe);
      final grade = RecipeQualityService.getQualityGrade(score);
      final issues = RecipeQualityService.getQualityIssues(recipe);

      print('\n📊 EXCELLENT RECIPE');
      print('━' * 60);
      print('Recipe: ${recipe['title']}');
      print('Score: $score/100');
      print('Grade: $grade');
      print('Issues: ${issues.isEmpty ? "✅ None!" : issues.join(", ")}');
      print('');

      expect(score, greaterThanOrEqualTo(90));
    });

    test('Good Recipe - Minor Issues', () {
      final recipe = {
        'title': 'Simple Chicken',
        'ingredients': ['chicken', 'salt', 'pepper'],
        'instructions': 'Cook the chicken for 20 minutes.',
        'servings': '4',
        'cookingTime': '20 minutes',
      };

      final score = RecipeQualityService.calculateQualityScore(recipe);
      final grade = RecipeQualityService.getQualityGrade(score);
      final issues = RecipeQualityService.getQualityIssues(recipe);

      print('📊 GOOD RECIPE');
      print('━' * 60);
      print('Recipe: ${recipe['title']}');
      print('Score: $score/100');
      print('Grade: $grade');
      print('Issues:');
      for (var issue in issues) {
        print('  ⚠️  $issue');
      }
      print('');

      expect(score, greaterThan(50));
    });

    test('Poor Recipe - Many Issues', () {
      final recipe = {
        'title': 'C',
        'ingredients': ['chicken'],
        'instructions': 'Cook',
      };

      final score = RecipeQualityService.calculateQualityScore(recipe);
      final grade = RecipeQualityService.getQualityGrade(score);
      final issues = RecipeQualityService.getQualityIssues(recipe);

      print('📊 POOR QUALITY RECIPE');
      print('━' * 60);
      print('Recipe: ${recipe['title']}');
      print('Score: $score/100');
      print('Grade: $grade');
      print('Issues Found: ${issues.length}');
      for (var issue in issues) {
        print('  ⚠️  $issue');
      }
      print('');

      expect(score, lessThan(50));
    });

    test('Multiple Recipes - Score Comparison', () {
      final recipes = [
        {
          'title': 'Perfect Keto Bowl',
          'ingredients': ['chicken', 'avocado', 'spinach', 'olive oil', 'lemon'],
          'instructions': 'Grill chicken for 15 minutes. Chop vegetables. Mix with olive oil and lemon. Serve in a bowl with sliced avocado on top.',
          'servings': '2',
          'cookingTime': '20 minutes',
          'difficulty': 'Easy',
        },
        {
          'title': 'Quick Snack',
          'ingredients': ['chicken'],
          'instructions': 'Cook it',
          'servings': '1',
        },
        {
          'title': 'Gourmet Salmon',
          'ingredients': ['salmon', 'butter', 'garlic', 'herbs', 'lemon', 'capers'],
          'instructions': 'Season salmon with salt and pepper. Heat butter in pan. Cook salmon skin-side down for 5 minutes. Flip and cook 3 more minutes. Add garlic, herbs, and capers in last minute. Squeeze lemon juice over fish. Serve immediately.',
          'servings': '2',
          'cookingTime': '15 minutes',
          'difficulty': 'Medium',
          'cuisine': 'French',
        },
      ];

      print('📊 RECIPE COMPARISON');
      print('━' * 60);
      
      for (var recipe in recipes) {
        final score = RecipeQualityService.calculateQualityScore(recipe);
        final grade = RecipeQualityService.getQualityGrade(score);
        
        print('${recipe['title']}:');
        print('  Score: $score/100 | Grade: $grade');
      }
      print('');

      expect(recipes.length, 3);
    });

    test('Full Analysis Output', () {
      final recipe = {
        'title': 'Mediterranean Chicken',
        'ingredients': ['chicken breast', 'olive oil', 'tomatoes', 'olives', 'feta cheese'],
        'instructions': 'Heat olive oil. Cook chicken until done. Add tomatoes and olives. Top with feta.',
        'servings': '4',
        'cookingTime': '25 minutes',
        'difficulty': 'Easy',
        'cuisine': 'Mediterranean',
      };

      final analysis = RecipeQualityService.analyzeRecipe(recipe);

      print('📊 COMPLETE ANALYSIS');
      print('━' * 60);
      print('Recipe: ${recipe['title']}');
      print('Score: ${analysis['score']}/100');
      print('Grade: ${analysis['grade']}');
      print('Color Code: ${analysis['color']}');
      print('Has Issues: ${analysis['hasIssues']}');
      
      if (analysis['hasIssues']) {
        print('Issues:');
        for (var issue in analysis['issues']) {
          print('  ⚠️  $issue');
        }
      } else {
        print('✅ No quality issues found!');
      }
      print('');

      expect(analysis['score'], greaterThan(0));
    });
  });

  print('\n🧪 ========== TESTS COMPLETE ==========\n');
}
