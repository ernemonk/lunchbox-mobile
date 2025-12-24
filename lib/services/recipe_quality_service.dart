/// Service for evaluating recipe quality based on completeness and content.
class RecipeQualityService {
  /// Calculates a quality score (0-100) for a recipe
  static int calculateQualityScore(Map<String, dynamic> recipe) {
    int score = 0;

    // Title (20 points)
    if (recipe.containsKey('title') && recipe['title'] != null) {
      final title = recipe['title'].toString();
      if (title.isNotEmpty && title.length >= 3) {
        score += 20;
      } else if (title.isNotEmpty) {
        score += 10;
      }
    }

    // Ingredients (30 points)
    if (recipe.containsKey('ingredients') && recipe['ingredients'] != null) {
      final ingredients = recipe['ingredients'];
      if (ingredients is List && ingredients.isNotEmpty) {
        final nonEmptyIngredients = ingredients.where((i) => i.toString().trim().isNotEmpty).length;
        if (nonEmptyIngredients >= 5) {
          score += 30;
        } else if (nonEmptyIngredients >= 3) {
          score += 25;
        } else if (nonEmptyIngredients >= 1) {
          score += 15;
        }
      }
    }

    // Instructions (30 points)
    if (recipe.containsKey('instructions') && recipe['instructions'] != null) {
      final instructions = recipe['instructions'].toString();
      if (instructions.length >= 100) {
        score += 30;
      } else if (instructions.length >= 50) {
        score += 20;
      } else if (instructions.length >= 20) {
        score += 10;
      }

      // Bonus for cooking verbs
      final cookingVerbs = ['heat', 'cook', 'bake', 'boil', 'fry', 'grill', 'roast', 'sauté', 'simmer', 'stir'];
      final verbsFound = cookingVerbs.where((verb) => instructions.toLowerCase().contains(verb)).length;
      if (verbsFound >= 3 && score == 30) {
        // Already at max for instructions
      }
    }

    // Metadata (20 points total)
    if (recipe.containsKey('servings') && recipe['servings'] != null && recipe['servings'].toString().isNotEmpty) {
      score += 5;
    }
    if (recipe.containsKey('cookingTime') && recipe['cookingTime'] != null && recipe['cookingTime'].toString().isNotEmpty) {
      score += 5;
    }
    if (recipe.containsKey('difficulty') && recipe['difficulty'] != null && recipe['difficulty'].toString().isNotEmpty) {
      score += 5;
    }
    if (recipe.containsKey('cuisine') && recipe['cuisine'] != null && recipe['cuisine'].toString().isNotEmpty) {
      score += 5;
    }

    return score;
  }

  /// Returns a grade label based on score
  static String getQualityGrade(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 45) return 'Fair';
    if (score >= 30) return 'Poor';
    return 'Very Poor';
  }

  /// Returns a color code for the grade
  static String getGradeColor(int score) {
    if (score >= 90) return '#22c55e'; // Green
    if (score >= 75) return '#84cc16'; // Light green
    if (score >= 60) return '#eab308'; // Yellow
    if (score >= 45) return '#f97316'; // Orange
    return '#ef4444'; // Red
  }

  /// Returns detailed quality issues
  static List<String> getQualityIssues(Map<String, dynamic> recipe) {
    final issues = <String>[];

    // Check title
    if (!recipe.containsKey('title') || recipe['title'] == null || recipe['title'].toString().isEmpty) {
      issues.add('Missing recipe title');
    } else if (recipe['title'].toString().length < 3) {
      issues.add('Recipe title is too short');
    }

    // Check ingredients
    if (!recipe.containsKey('ingredients') || recipe['ingredients'] == null) {
      issues.add('Missing ingredients list');
    } else if (recipe['ingredients'] is List) {
      final ingredients = recipe['ingredients'] as List;
      if (ingredients.isEmpty) {
        issues.add('No ingredients provided');
      } else if (ingredients.length < 3) {
        issues.add('Very few ingredients (less than 3)');
      }
      
      final emptyIngredients = ingredients.where((i) => i.toString().trim().isEmpty).length;
      if (emptyIngredients > 0) {
        issues.add('$emptyIngredients empty ingredient(s)');
      }
    }

    // Check instructions
    if (!recipe.containsKey('instructions') || recipe['instructions'] == null || recipe['instructions'].toString().isEmpty) {
      issues.add('Missing cooking instructions');
    } else if (recipe['instructions'].toString().length < 20) {
      issues.add('Instructions are too brief');
    }

    // Check metadata
    if (!recipe.containsKey('servings') || recipe['servings'] == null || recipe['servings'].toString().isEmpty) {
      issues.add('Missing serving size');
    }
    if (!recipe.containsKey('cookingTime') || recipe['cookingTime'] == null || recipe['cookingTime'].toString().isEmpty) {
      issues.add('Missing cooking time');
    }

    return issues;
  }

  /// Returns quality insights
  static Map<String, dynamic> analyzeRecipe(Map<String, dynamic> recipe) {
    final score = calculateQualityScore(recipe);
    final grade = getQualityGrade(score);
    final issues = getQualityIssues(recipe);
    
    return {
      'score': score,
      'grade': grade,
      'color': getGradeColor(score),
      'issues': issues,
      'hasIssues': issues.isNotEmpty,
    };
  }
}
