/// App-wide string constants
class AppStrings {
  AppStrings._(); // Private constructor to prevent instantiation

  // App Info
  static const String appName = 'Lunchbox';

  // Navigation Titles
  static const String recipeGenerator = 'Recipe Generator';
  static const String favorites = 'Favorites';
  static const String myFridge = 'My Fridge';
  static const String settings = 'Settings';

  // Auth Pages
  static const String login = 'Log In';
  static const String signUp = 'Sign Up';
  static const String loginSubtitle = 'Sign in with your email and password';
  static const String signUpSubtitle = 'Create an account with your email and password';
  static const String noAccountPrompt = "Don't have an account? Sign Up";
  static const String hasAccountPrompt = 'Already have an account? Log In';

  // Form Labels
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';

  // Diet Options
  static const List<String> dietOptions = [
    'Any',
    'Keto',
    'Carnivore',
    'Vegetarian',
    'Vegan',
    'Pescetarian',
    'Raw Vegan',
    'Ayurvedic',
  ];

  // Recipe Generator
  static const String selectDiet = 'Select Your Diet:';
  static const String hasAllergies = 'Do you have any allergies?';
  static const String allergiesHint = 'Enter allergies (e.g., nuts, gluten)';
  static const String additionalInstructions = 'Additional Instructions:';
  static const String instructionsHint = 'Enter any other instructions here';
  static const String useOnlyFridgeItems = 'Use only my fridge items:';
  static const String generateRecipes = 'Generate Recipes';
  static const String setPreferences = 'Set Preferences';
  static const String generatedRecipes = 'Generated Recipes:';
  static const String noRecipesYet = 'No recipes generated yet.';
  static const String generatingRecipes = 'Your recipes are being generated...';

  // My Fridge
  static const String addItem = 'Add Item';
  static const String editItem = 'Edit Item';
  static const String fridgeItem = 'Fridge Item';
  static const String quantity = 'Quantity';

  // Favorites
  static const String noFavoritesYet = "You haven't added any recipes yet.";
  static const String recipeSaved = 'Recipe saved!';
  static const String recipeRemoved = 'Recipe removed from favorites.';

  // Settings
  static const String deleteAccount = 'Delete Account';
  static const String confirmDeletion = 'Confirm Account Deletion';
  static const String deletionWarning =
      '⚠ Warning: This action is irreversible!\n'
      'All your data, including account details and associated files, '
      'will be permanently erased.';
  static const String enterEmailToConfirm = 'Enter your email to confirm';

  // Error Messages
  static const String errorEmptyFields = 'Please enter both email and password.';
  static const String errorFillAllFields = 'Please fill in all fields.';
  static const String errorPasswordsMismatch = 'Passwords do not match.';
  static const String errorNotLoggedIn = 'User not logged in.';
  static const String errorGeneric = 'An error occurred';

  // Success Messages
  static const String preferencesSaved = 'Preferences saved successfully!';
}
