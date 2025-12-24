/// Re-exports recipe generation functions from the main service.
/// 
/// This file exists for backward compatibility with existing code.
/// New code should import from 'recipe_service.dart' directly.
export 'recipe_service.dart' show generateRecipes, generateRecipesStream;
