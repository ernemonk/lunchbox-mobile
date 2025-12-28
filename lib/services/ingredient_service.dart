/// Ingredient detection and categorization service
/// Provides intelligent auto-detection of food categories and units
/// enabling quick, frictionless fridge inventory management
///
/// Philosophy: Minimize user input, maximize data quality through
/// intelligent inference. Based on RFC principle of "Pure utility."
/// 
/// Features:
/// - 400+ food items mapped to 8 categories
/// - Fuzzy matching for misspellings (Levenshtein distance)
/// - Partial/substring matching
/// - Word boundary matching

import 'dart:math';

class IngredientService {
  /// Comprehensive ingredient-to-category mapping
  /// Covers 400+ common grocery items across 8 categories
  /// Categories match SmartInventoryService and Gemini API for consistency
  static const Map<String, String> categoryMap = {
    // ═══════════════════════════════════════════════════════════════════
    // MEAT & PROTEIN 🍗 (150+ items - comprehensive cuts, cold cuts, variants)
    // ═══════════════════════════════════════════════════════════════════
    // === GENERAL MEAT TERMS ===
    'meat': 'Meat & Protein',
    'meats': 'Meat & Protein',
    'protein': 'Meat & Protein',
    'proteins': 'Meat & Protein',
    
    // === EGGS ===
    'egg': 'Meat & Protein',
    'eggs': 'Meat & Protein',
    'egg white': 'Meat & Protein',
    'egg yolk': 'Meat & Protein',
    'hard boiled egg': 'Meat & Protein',
    'scrambled eggs': 'Meat & Protein',
    'omelette': 'Meat & Protein',
    'omelet': 'Meat & Protein',
    'quail egg': 'Meat & Protein',
    'duck egg': 'Meat & Protein',
    
    // === CHICKEN ===
    'chicken': 'Meat & Protein',
    'chiken': 'Meat & Protein', // common misspelling
    'chickin': 'Meat & Protein', // common misspelling
    'chicken breast': 'Meat & Protein',
    'chicken thigh': 'Meat & Protein',
    'chicken thighs': 'Meat & Protein',
    'chicken wing': 'Meat & Protein',
    'chicken wings': 'Meat & Protein',
    'chicken drumstick': 'Meat & Protein',
    'chicken leg': 'Meat & Protein',
    'chicken tender': 'Meat & Protein',
    'chicken tenders': 'Meat & Protein',
    'chicken nugget': 'Meat & Protein',
    'chicken nuggets': 'Meat & Protein',
    'chicken strip': 'Meat & Protein',
    'chicken strips': 'Meat & Protein',
    'rotisserie chicken': 'Meat & Protein',
    'roasted chicken': 'Meat & Protein',
    'fried chicken': 'Meat & Protein',
    'grilled chicken': 'Meat & Protein',
    'chicken liver': 'Meat & Protein',
    'chicken heart': 'Meat & Protein',
    'whole chicken': 'Meat & Protein',
    'ground chicken': 'Meat & Protein',
    'chicken patty': 'Meat & Protein',
    'chicken sausage': 'Meat & Protein',
    
    // === BEEF & STEAK CUTS ===
    'beef': 'Meat & Protein',
    'beaf': 'Meat & Protein', // common misspelling
    'steak': 'Meat & Protein',
    'steaks': 'Meat & Protein',
    'ribeye': 'Meat & Protein',
    'rib eye': 'Meat & Protein',
    'rib-eye': 'Meat & Protein',
    'ribey': 'Meat & Protein', // misspelling
    'sirloin': 'Meat & Protein',
    'sirlon': 'Meat & Protein', // misspelling
    'filet mignon': 'Meat & Protein',
    'filet': 'Meat & Protein',
    'fillet': 'Meat & Protein',
    'tenderloin': 'Meat & Protein',
    'beef tenderloin': 'Meat & Protein',
    'pork tenderloin': 'Meat & Protein',
    't-bone': 'Meat & Protein',
    'tbone': 'Meat & Protein',
    't bone': 'Meat & Protein',
    'porterhouse': 'Meat & Protein',
    'new york strip': 'Meat & Protein',
    'ny strip': 'Meat & Protein',
    'strip steak': 'Meat & Protein',
    'flank steak': 'Meat & Protein',
    'skirt steak': 'Meat & Protein',
    'flat iron': 'Meat & Protein',
    'flat iron steak': 'Meat & Protein',
    'hanger steak': 'Meat & Protein',
    'chuck': 'Meat & Protein',
    'chuck roast': 'Meat & Protein',
    'chuck steak': 'Meat & Protein',
    'brisket': 'Meat & Protein',
    'beef brisket': 'Meat & Protein',
    'short rib': 'Meat & Protein',
    'short ribs': 'Meat & Protein',
    'beef ribs': 'Meat & Protein',
    'prime rib': 'Meat & Protein',
    'roast beef': 'Meat & Protein',
    'pot roast': 'Meat & Protein',
    'beef roast': 'Meat & Protein',
    'ground beef': 'Meat & Protein',
    'ground meat': 'Meat & Protein',
    'minced beef': 'Meat & Protein',
    'mince': 'Meat & Protein',
    'minced meat': 'Meat & Protein',
    'hamburger': 'Meat & Protein',
    'burger': 'Meat & Protein',
    'burger patty': 'Meat & Protein',
    'beef patty': 'Meat & Protein',
    'meatball': 'Meat & Protein',
    'meatballs': 'Meat & Protein',
    'meatloaf': 'Meat & Protein',
    'meat loaf': 'Meat & Protein',
    'beef stew': 'Meat & Protein',
    'stew meat': 'Meat & Protein',
    'beef shank': 'Meat & Protein',
    'oxtail': 'Meat & Protein',
    'ox tail': 'Meat & Protein',
    'beef liver': 'Meat & Protein',
    'liver': 'Meat & Protein',
    'tongue': 'Meat & Protein',
    'beef tongue': 'Meat & Protein',
    'tripe': 'Meat & Protein',
    'carne asada': 'Meat & Protein',
    'picanha': 'Meat & Protein',
    'tri tip': 'Meat & Protein',
    'tri-tip': 'Meat & Protein',
    'wagyu': 'Meat & Protein',
    'kobe': 'Meat & Protein',
    'angus': 'Meat & Protein',
    'veal': 'Meat & Protein',
    'veal chop': 'Meat & Protein',
    
    // === PORK ===
    'pork': 'Meat & Protein',
    'pork chop': 'Meat & Protein',
    'pork chops': 'Meat & Protein',
    'porkchop': 'Meat & Protein',
    'pork loin': 'Meat & Protein',
    'pork belly': 'Meat & Protein',
    'pork shoulder': 'Meat & Protein',
    'pork butt': 'Meat & Protein',
    'boston butt': 'Meat & Protein',
    'pulled pork': 'Meat & Protein',
    'pork ribs': 'Meat & Protein',
    'spare ribs': 'Meat & Protein',
    'baby back ribs': 'Meat & Protein',
    'st louis ribs': 'Meat & Protein',
    'country ribs': 'Meat & Protein',
    'ground pork': 'Meat & Protein',
    'pork sausage': 'Meat & Protein',
    'carnitas': 'Meat & Protein',
    'chicharron': 'Meat & Protein',
    'pork rind': 'Meat & Protein',
    'pork rinds': 'Meat & Protein',
    'crackling': 'Meat & Protein',
    'fatback': 'Meat & Protein',
    'lard': 'Meat & Protein',
    'pig feet': 'Meat & Protein',
    
    // === HAM & CURED PORK ===
    'ham': 'Meat & Protein',
    'honey ham': 'Meat & Protein',
    'smoked ham': 'Meat & Protein',
    'spiral ham': 'Meat & Protein',
    'ham steak': 'Meat & Protein',
    'gammon': 'Meat & Protein',
    'canadian bacon': 'Meat & Protein',
    'back bacon': 'Meat & Protein',
    
    // === BACON ===
    'bacon': 'Meat & Protein',
    'bakon': 'Meat & Protein', // misspelling
    'bacon strips': 'Meat & Protein',
    'turkey bacon': 'Meat & Protein',
    'beef bacon': 'Meat & Protein',
    'pancetta': 'Meat & Protein',
    'guanciale': 'Meat & Protein',
    'lardons': 'Meat & Protein',
    'lardon': 'Meat & Protein',
    
    // === SAUSAGES ===
    'sausage': 'Meat & Protein',
    'sausages': 'Meat & Protein',
    'sausag': 'Meat & Protein', // misspelling
    'hot dog': 'Meat & Protein',
    'hotdog': 'Meat & Protein',
    'hot dogs': 'Meat & Protein',
    'hotdogs': 'Meat & Protein',
    'frank': 'Meat & Protein',
    'franks': 'Meat & Protein',
    'frankfurter': 'Meat & Protein',
    'wiener': 'Meat & Protein',
    'weiner': 'Meat & Protein', // misspelling
    'bratwurst': 'Meat & Protein',
    'brat': 'Meat & Protein',
    'brats': 'Meat & Protein',
    'italian sausage': 'Meat & Protein',
    'breakfast sausage': 'Meat & Protein',
    'sausage link': 'Meat & Protein',
    'sausage patty': 'Meat & Protein',
    'kielbasa': 'Meat & Protein',
    'andouille': 'Meat & Protein',
    'boudin': 'Meat & Protein',
    'chorizo': 'Meat & Protein',
    'linguica': 'Meat & Protein',
    'longaniza': 'Meat & Protein',
    'merguez': 'Meat & Protein',
    'blood sausage': 'Meat & Protein',
    'black pudding': 'Meat & Protein',
    'morcilla': 'Meat & Protein',
    'liverwurst': 'Meat & Protein',
    'braunschweiger': 'Meat & Protein',
    
    // === COLD CUTS & DELI MEATS ===
    'cold cut': 'Meat & Protein',
    'cold cuts': 'Meat & Protein',
    'coldcut': 'Meat & Protein',
    'coldcuts': 'Meat & Protein',
    'deli meat': 'Meat & Protein',
    'deli meats': 'Meat & Protein',
    'lunch meat': 'Meat & Protein',
    'lunchmeat': 'Meat & Protein',
    'luncheon meat': 'Meat & Protein',
    'sliced meat': 'Meat & Protein',
    'sliced turkey': 'Meat & Protein',
    'sliced ham': 'Meat & Protein',
    'sliced chicken': 'Meat & Protein',
    'sliced beef': 'Meat & Protein',
    'roast beef slices': 'Meat & Protein',
    'turkey slices': 'Meat & Protein',
    'ham slices': 'Meat & Protein',
    'pepperoni': 'Meat & Protein',
    'peperoni': 'Meat & Protein', // misspelling
    'salami': 'Meat & Protein',
    'salame': 'Meat & Protein',
    'genoa salami': 'Meat & Protein',
    'hard salami': 'Meat & Protein',
    'sopressata': 'Meat & Protein',
    'soppressata': 'Meat & Protein',
    'capicola': 'Meat & Protein',
    'capocollo': 'Meat & Protein',
    'coppa': 'Meat & Protein',
    'gabagool': 'Meat & Protein', // colloquial
    'prosciutto': 'Meat & Protein',
    'proscuitto': 'Meat & Protein', // misspelling
    'prosciuto': 'Meat & Protein', // misspelling
    'serrano': 'Meat & Protein',
    'jamon': 'Meat & Protein',
    'jamón': 'Meat & Protein',
    'iberico': 'Meat & Protein',
    'speck': 'Meat & Protein',
    'bresaola': 'Meat & Protein',
    'pastrami': 'Meat & Protein',
    'corned beef': 'Meat & Protein',
    'corn beef': 'Meat & Protein', // variant
    'mortadella': 'Meat & Protein',
    'bologna': 'Meat & Protein',
    'baloney': 'Meat & Protein', // variant spelling
    'olive loaf': 'Meat & Protein',
    'head cheese': 'Meat & Protein',
    'pate': 'Meat & Protein',
    'pâté': 'Meat & Protein',
    'foie gras': 'Meat & Protein',
    'spam': 'Meat & Protein',
    'canned meat': 'Meat & Protein',
    'potted meat': 'Meat & Protein',
    'vienna sausage': 'Meat & Protein',
    
    // === TURKEY ===
    'turkey': 'Meat & Protein',
    'turky': 'Meat & Protein', // misspelling
    'turkey breast': 'Meat & Protein',
    'turkey leg': 'Meat & Protein',
    'turkey thigh': 'Meat & Protein',
    'turkey wing': 'Meat & Protein',
    'ground turkey': 'Meat & Protein',
    'turkey burger': 'Meat & Protein',
    'turkey sausage': 'Meat & Protein',
    'turkey meatball': 'Meat & Protein',
    'smoked turkey': 'Meat & Protein',
    'roasted turkey': 'Meat & Protein',
    'whole turkey': 'Meat & Protein',
    'turkey ham': 'Meat & Protein',
    'turkey deli': 'Meat & Protein',
    
    // === OTHER POULTRY ===
    'duck': 'Meat & Protein',
    'duck breast': 'Meat & Protein',
    'duck leg': 'Meat & Protein',
    'duck confit': 'Meat & Protein',
    'peking duck': 'Meat & Protein',
    'goose': 'Meat & Protein',
    'quail': 'Meat & Protein',
    'pheasant': 'Meat & Protein',
    'cornish hen': 'Meat & Protein',
    'game hen': 'Meat & Protein',
    
    // === LAMB & GOAT ===
    'lamb': 'Meat & Protein',
    'lamb chop': 'Meat & Protein',
    'lamb chops': 'Meat & Protein',
    'lamb leg': 'Meat & Protein',
    'leg of lamb': 'Meat & Protein',
    'lamb shank': 'Meat & Protein',
    'lamb rack': 'Meat & Protein',
    'rack of lamb': 'Meat & Protein',
    'lamb shoulder': 'Meat & Protein',
    'ground lamb': 'Meat & Protein',
    'lamb kebab': 'Meat & Protein',
    'mutton': 'Meat & Protein',
    'goat': 'Meat & Protein',
    'goat meat': 'Meat & Protein',
    'cabrito': 'Meat & Protein',
    'chevon': 'Meat & Protein',
    
    // === GAME & EXOTIC MEATS ===
    'venison': 'Meat & Protein',
    'deer': 'Meat & Protein',
    'deer meat': 'Meat & Protein',
    'elk': 'Meat & Protein',
    'moose': 'Meat & Protein',
    'bison': 'Meat & Protein',
    'buffalo': 'Meat & Protein',
    'wild boar': 'Meat & Protein',
    'boar': 'Meat & Protein',
    'rabbit': 'Meat & Protein',
    'hare': 'Meat & Protein',
    'kangaroo': 'Meat & Protein',
    'ostrich': 'Meat & Protein',
    'alligator': 'Meat & Protein',
    'frog legs': 'Meat & Protein',
    
    // === FISH ===
    'fish': 'Meat & Protein',
    'salmon': 'Meat & Protein',
    'salman': 'Meat & Protein', // misspelling
    'atlantic salmon': 'Meat & Protein',
    'sockeye salmon': 'Meat & Protein',
    'smoked salmon': 'Meat & Protein',
    'lox': 'Meat & Protein',
    'gravlax': 'Meat & Protein',
    'tuna': 'Meat & Protein',
    'ahi tuna': 'Meat & Protein',
    'yellowfin tuna': 'Meat & Protein',
    'albacore': 'Meat & Protein',
    'tuna steak': 'Meat & Protein',
    'tilapia': 'Meat & Protein',
    'cod': 'Meat & Protein',
    'pacific cod': 'Meat & Protein',
    'atlantic cod': 'Meat & Protein',
    'halibut': 'Meat & Protein',
    'haddock': 'Meat & Protein',
    'pollock': 'Meat & Protein',
    'flounder': 'Meat & Protein',
    'sole': 'Meat & Protein',
    'trout': 'Meat & Protein',
    'rainbow trout': 'Meat & Protein',
    'bass': 'Meat & Protein',
    'sea bass': 'Meat & Protein',
    'striped bass': 'Meat & Protein',
    'branzino': 'Meat & Protein',
    'catfish': 'Meat & Protein',
    'perch': 'Meat & Protein',
    'walleye': 'Meat & Protein',
    'pike': 'Meat & Protein',
    'mahi mahi': 'Meat & Protein',
    'mahi': 'Meat & Protein',
    'swordfish': 'Meat & Protein',
    'marlin': 'Meat & Protein',
    'mackerel': 'Meat & Protein',
    'sardine': 'Meat & Protein',
    'sardines': 'Meat & Protein',
    'anchovy': 'Meat & Protein',
    'anchovies': 'Meat & Protein',
    'herring': 'Meat & Protein',
    'snapper': 'Meat & Protein',
    'red snapper': 'Meat & Protein',
    'grouper': 'Meat & Protein',
    'orange roughy': 'Meat & Protein',
    'monkfish': 'Meat & Protein',
    'eel': 'Meat & Protein',
    'unagi': 'Meat & Protein',
    'fish fillet': 'Meat & Protein',
    'fish stick': 'Meat & Protein',
    'fish sticks': 'Meat & Protein',
    'fish cake': 'Meat & Protein',
    
    // === SHELLFISH & SEAFOOD ===
    'shrimp': 'Meat & Protein',
    'shrimps': 'Meat & Protein',
    'shimp': 'Meat & Protein', // misspelling
    'prawns': 'Meat & Protein',
    'prawn': 'Meat & Protein',
    'jumbo shrimp': 'Meat & Protein',
    'cocktail shrimp': 'Meat & Protein',
    'crab': 'Meat & Protein',
    'crab meat': 'Meat & Protein',
    'crabmeat': 'Meat & Protein',
    'crab leg': 'Meat & Protein',
    'crab legs': 'Meat & Protein',
    'king crab': 'Meat & Protein',
    'snow crab': 'Meat & Protein',
    'dungeness crab': 'Meat & Protein',
    'blue crab': 'Meat & Protein',
    'soft shell crab': 'Meat & Protein',
    'imitation crab': 'Meat & Protein',
    'surimi': 'Meat & Protein',
    'lobster': 'Meat & Protein',
    'lobster tail': 'Meat & Protein',
    'crawfish': 'Meat & Protein',
    'crayfish': 'Meat & Protein',
    'crawdad': 'Meat & Protein',
    'langostino': 'Meat & Protein',
    'scallop': 'Meat & Protein',
    'scallops': 'Meat & Protein',
    'sea scallop': 'Meat & Protein',
    'bay scallop': 'Meat & Protein',
    'clam': 'Meat & Protein',
    'clams': 'Meat & Protein',
    'littleneck': 'Meat & Protein',
    'cherrystone': 'Meat & Protein',
    'mussel': 'Meat & Protein',
    'mussels': 'Meat & Protein',
    'oyster': 'Meat & Protein',
    'oysters': 'Meat & Protein',
    'squid': 'Meat & Protein',
    'calamari': 'Meat & Protein',
    'octopus': 'Meat & Protein',
    'tako': 'Meat & Protein',
    'conch': 'Meat & Protein',
    'abalone': 'Meat & Protein',
    'sea urchin': 'Meat & Protein',
    'uni': 'Meat & Protein',
    'caviar': 'Meat & Protein',
    'roe': 'Meat & Protein',
    'fish roe': 'Meat & Protein',
    'ikura': 'Meat & Protein',
    'tobiko': 'Meat & Protein',
    
    // === PLANT-BASED PROTEIN ===
    'tofu': 'Meat & Protein',
    'tofoo': 'Meat & Protein', // misspelling
    'firm tofu': 'Meat & Protein',
    'silken tofu': 'Meat & Protein',
    'extra firm tofu': 'Meat & Protein',
    'tempeh': 'Meat & Protein',
    'seitan': 'Meat & Protein',
    'beyond meat': 'Meat & Protein',
    'beyond burger': 'Meat & Protein',
    'impossible burger': 'Meat & Protein',
    'impossible meat': 'Meat & Protein',
    'plant based': 'Meat & Protein',
    'plant protein': 'Meat & Protein',
    'veggie burger': 'Meat & Protein',
    'veggie patty': 'Meat & Protein',
    'meatless': 'Meat & Protein',
    'meat substitute': 'Meat & Protein',
    'fake meat': 'Meat & Protein',
    'faux meat': 'Meat & Protein',
    'tvp': 'Meat & Protein',
    'textured vegetable protein': 'Meat & Protein',
    'soy protein': 'Meat & Protein',
    'pea protein': 'Meat & Protein',
    
    // === LEGUMES (protein source) ===
    'beans': 'Meat & Protein',
    'bean': 'Meat & Protein',
    'black beans': 'Meat & Protein',
    'black bean': 'Meat & Protein',
    'kidney beans': 'Meat & Protein',
    'kidney bean': 'Meat & Protein',
    'pinto beans': 'Meat & Protein',
    'pinto bean': 'Meat & Protein',
    'navy beans': 'Meat & Protein',
    'white beans': 'Meat & Protein',
    'great northern beans': 'Meat & Protein',
    'cannellini': 'Meat & Protein',
    'cannellini beans': 'Meat & Protein',
    'lima beans': 'Meat & Protein',
    'butter beans': 'Meat & Protein',
    'fava beans': 'Meat & Protein',
    'broad beans': 'Meat & Protein',
    'adzuki beans': 'Meat & Protein',
    'mung beans': 'Meat & Protein',
    'refried beans': 'Meat & Protein',
    'baked beans': 'Meat & Protein',
    'lentils': 'Meat & Protein',
    'lentil': 'Meat & Protein',
    'red lentils': 'Meat & Protein',
    'green lentils': 'Meat & Protein',
    'brown lentils': 'Meat & Protein',
    'french lentils': 'Meat & Protein',
    'chickpea': 'Meat & Protein',
    'chickpeas': 'Meat & Protein',
    'chick pea': 'Meat & Protein',
    'garbanzo': 'Meat & Protein',
    'garbanzo beans': 'Meat & Protein',
    'split peas': 'Meat & Protein',
    'black eyed peas': 'Meat & Protein',
    'edamame': 'Meat & Protein',
    'hummus': 'Meat & Protein',
    'falafel': 'Meat & Protein',
    'dal': 'Meat & Protein',
    'daal': 'Meat & Protein',
    'dhal': 'Meat & Protein',
    
    // === NUTS & SEEDS (protein source) ===
    'nuts': 'Meat & Protein',
    'nut': 'Meat & Protein',
    'almonds': 'Meat & Protein',
    'almond': 'Meat & Protein',
    'peanuts': 'Meat & Protein',
    'peanut': 'Meat & Protein',
    'cashews': 'Meat & Protein',
    'cashew': 'Meat & Protein',
    'walnuts': 'Meat & Protein',
    'walnut': 'Meat & Protein',
    'pecans': 'Meat & Protein',
    'pecan': 'Meat & Protein',
    'pistachios': 'Meat & Protein',
    'pistachio': 'Meat & Protein',
    'macadamia': 'Meat & Protein',
    'macadamia nuts': 'Meat & Protein',
    'hazelnuts': 'Meat & Protein',
    'hazelnut': 'Meat & Protein',
    'filbert': 'Meat & Protein',
    'brazil nuts': 'Meat & Protein',
    'brazil nut': 'Meat & Protein',
    'pine nuts': 'Meat & Protein',
    'pine nut': 'Meat & Protein',
    'pignoli': 'Meat & Protein',
    'chestnuts': 'Meat & Protein',
    'chestnut': 'Meat & Protein',
    'mixed nuts': 'Meat & Protein',
    'trail mix': 'Meat & Protein',
    'seeds': 'Meat & Protein',
    'sunflower seeds': 'Meat & Protein',
    'pumpkin seeds': 'Meat & Protein',
    'pepitas': 'Meat & Protein',
    'chia seeds': 'Meat & Protein',
    'chia': 'Meat & Protein',
    'flax seeds': 'Meat & Protein',
    'flaxseed': 'Meat & Protein',
    'hemp seeds': 'Meat & Protein',
    'hemp hearts': 'Meat & Protein',
    'sesame seeds': 'Meat & Protein',
    'tahini': 'Meat & Protein',
    'protein powder': 'Meat & Protein',
    'whey protein': 'Meat & Protein',
    'protein shake': 'Meat & Protein',
    
    // ═══════════════════════════════════════════════════════════════════
    // DAIRY 🥛 (50+ items)
    // ═══════════════════════════════════════════════════════════════════
    'milk': 'Dairy',
    'whole milk': 'Dairy',
    'skim milk': 'Dairy',
    '2% milk': 'Dairy',
    'oat milk': 'Dairy',
    'almond milk': 'Dairy',
    'soy milk': 'Dairy',
    'coconut milk': 'Dairy',
    'rice milk': 'Dairy',
    'cashew milk': 'Dairy',
    'lactaid': 'Dairy',
    'half and half': 'Dairy',
    'heavy cream': 'Dairy',
    'whipping cream': 'Dairy',
    'light cream': 'Dairy',
    'cream': 'Dairy',
    'creamer': 'Dairy',
    'coffee creamer': 'Dairy',
    'cheese': 'Dairy',
    'cheddar': 'Dairy',
    'mozzarella': 'Dairy',
    'parmesan': 'Dairy',
    'parmigiano': 'Dairy',
    'swiss': 'Dairy',
    'gouda': 'Dairy',
    'brie': 'Dairy',
    'camembert': 'Dairy',
    'feta': 'Dairy',
    'goat cheese': 'Dairy',
    'blue cheese': 'Dairy',
    'gorgonzola': 'Dairy',
    'ricotta': 'Dairy',
    'mascarpone': 'Dairy',
    'cream cheese': 'Dairy',
    'cottage cheese': 'Dairy',
    'american cheese': 'Dairy',
    'provolone': 'Dairy',
    'monterey jack': 'Dairy',
    'colby': 'Dairy',
    'pepper jack': 'Dairy',
    'string cheese': 'Dairy',
    'shredded cheese': 'Dairy',
    'sliced cheese': 'Dairy',
    'butter': 'Dairy',
    'margarine': 'Dairy',
    'ghee': 'Dairy',
    'yogurt': 'Dairy',
    'yoghurt': 'Dairy',
    'greek yogurt': 'Dairy',
    'plain yogurt': 'Dairy',
    'vanilla yogurt': 'Dairy',
    'fruit yogurt': 'Dairy',
    'kefir': 'Dairy',
    'sour cream': 'Dairy',
    'creme fraiche': 'Dairy',
    'whipped cream': 'Dairy',
    'cool whip': 'Dairy',
    'ice cream': 'Dairy',
    'gelato': 'Dairy',
    'frozen yogurt': 'Dairy',
    'sherbet': 'Dairy',
    'sorbet': 'Dairy',
    'condensed milk': 'Dairy',
    'evaporated milk': 'Dairy',
    'powdered milk': 'Dairy',
    'buttermilk': 'Dairy',
    'eggnog': 'Dairy',
    'whey': 'Dairy',
    'queso': 'Dairy',
    'paneer': 'Dairy',
    'halloumi': 'Dairy',
    
    // ═══════════════════════════════════════════════════════════════════
    // FRUITS 🍎 (60+ items)
    // ═══════════════════════════════════════════════════════════════════
    'apple': 'Fruits',
    'apples': 'Fruits',
    'banana': 'Fruits',
    'bananas': 'Fruits',
    'orange': 'Fruits',
    'oranges': 'Fruits',
    'mandarin': 'Fruits',
    'tangerine': 'Fruits',
    'clementine': 'Fruits',
    'grapefruit': 'Fruits',
    'lemon': 'Fruits',
    'lemons': 'Fruits',
    'lime': 'Fruits',
    'limes': 'Fruits',
    'grape': 'Fruits',
    'grapes': 'Fruits',
    'berry': 'Fruits',
    'berries': 'Fruits',
    'strawberry': 'Fruits',
    'strawberries': 'Fruits',
    'blueberry': 'Fruits',
    'blueberries': 'Fruits',
    'raspberry': 'Fruits',
    'raspberries': 'Fruits',
    'blackberry': 'Fruits',
    'blackberries': 'Fruits',
    'cranberry': 'Fruits',
    'cranberries': 'Fruits',
    'cherry': 'Fruits',
    'cherries': 'Fruits',
    'watermelon': 'Fruits',
    'cantaloupe': 'Fruits',
    'honeydew': 'Fruits',
    'melon': 'Fruits',
    'pineapple': 'Fruits',
    'mango': 'Fruits',
    'mangoes': 'Fruits',
    'papaya': 'Fruits',
    'kiwi': 'Fruits',
    'kiwis': 'Fruits',
    'peach': 'Fruits',
    'peaches': 'Fruits',
    'nectarine': 'Fruits',
    'plum': 'Fruits',
    'plums': 'Fruits',
    'apricot': 'Fruits',
    'apricots': 'Fruits',
    'pear': 'Fruits',
    'pears': 'Fruits',
    'avocado': 'Fruits',
    'avocados': 'Fruits',
    'coconut': 'Fruits',
    'fig': 'Fruits',
    'figs': 'Fruits',
    'date': 'Fruits',
    'dates': 'Fruits',
    'pomegranate': 'Fruits',
    'persimmon': 'Fruits',
    'guava': 'Fruits',
    'passion fruit': 'Fruits',
    'dragon fruit': 'Fruits',
    'lychee': 'Fruits',
    'starfruit': 'Fruits',
    'jackfruit': 'Fruits',
    'plantain': 'Fruits',
    'raisin': 'Fruits',
    'raisins': 'Fruits',
    'dried fruit': 'Fruits',
    'prunes': 'Fruits',
    'applesauce': 'Fruits',
    'fruit cup': 'Fruits',
    'fruit salad': 'Fruits',
    'mixed berries': 'Fruits',
    'frozen fruit': 'Fruits',
    
    // ═══════════════════════════════════════════════════════════════════
    // VEGETABLES 🥬 (80+ items)
    // ═══════════════════════════════════════════════════════════════════
    'tomato': 'Vegetables',
    'tomatoes': 'Vegetables',
    'cherry tomato': 'Vegetables',
    'grape tomato': 'Vegetables',
    'roma tomato': 'Vegetables',
    'carrot': 'Vegetables',
    'carrots': 'Vegetables',
    'baby carrots': 'Vegetables',
    'broccoli': 'Vegetables',
    'cauliflower': 'Vegetables',
    'brussels sprout': 'Vegetables',
    'brussels sprouts': 'Vegetables',
    'cabbage': 'Vegetables',
    'red cabbage': 'Vegetables',
    'napa cabbage': 'Vegetables',
    'bok choy': 'Vegetables',
    'spinach': 'Vegetables',
    'kale': 'Vegetables',
    'collard greens': 'Vegetables',
    'swiss chard': 'Vegetables',
    'lettuce': 'Vegetables',
    'romaine': 'Vegetables',
    'iceberg': 'Vegetables',
    'arugula': 'Vegetables',
    'mixed greens': 'Vegetables',
    'salad': 'Vegetables',
    'salad mix': 'Vegetables',
    'spring mix': 'Vegetables',
    'cucumber': 'Vegetables',
    'cucumbers': 'Vegetables',
    'pickle': 'Vegetables',
    'pickles': 'Vegetables',
    'zucchini': 'Vegetables',
    'squash': 'Vegetables',
    'yellow squash': 'Vegetables',
    'butternut squash': 'Vegetables',
    'acorn squash': 'Vegetables',
    'spaghetti squash': 'Vegetables',
    'pumpkin': 'Vegetables',
    'bell pepper': 'Vegetables',
    'bell peppers': 'Vegetables',
    'red pepper': 'Vegetables',
    'green pepper': 'Vegetables',
    'yellow pepper': 'Vegetables',
    'jalapeno': 'Vegetables',
    'serrano pepper': 'Vegetables',
    'habanero': 'Vegetables',
    'chili pepper': 'Vegetables',
    'poblano': 'Vegetables',
    'onion': 'Vegetables',
    'onions': 'Vegetables',
    'red onion': 'Vegetables',
    'white onion': 'Vegetables',
    'yellow onion': 'Vegetables',
    'green onion': 'Vegetables',
    'scallion': 'Vegetables',
    'scallions': 'Vegetables',
    'shallot': 'Vegetables',
    'shallots': 'Vegetables',
    'garlic': 'Vegetables',
    'ginger': 'Vegetables',
    'potato': 'Vegetables',
    'potatoes': 'Vegetables',
    'russet potato': 'Vegetables',
    'red potato': 'Vegetables',
    'yukon gold': 'Vegetables',
    'fingerling': 'Vegetables',
    'sweet potato': 'Vegetables',
    'sweet potatoes': 'Vegetables',
    'yam': 'Vegetables',
    'yams': 'Vegetables',
    'corn': 'Vegetables',
    'corn on the cob': 'Vegetables',
    'sweet corn': 'Vegetables',
    'peas': 'Vegetables',
    'green peas': 'Vegetables',
    'snap peas': 'Vegetables',
    'snow peas': 'Vegetables',
    'celery': 'Vegetables',
    'mushroom': 'Vegetables',
    'mushrooms': 'Vegetables',
    'portobello': 'Vegetables',
    'shiitake': 'Vegetables',
    'cremini': 'Vegetables',
    'button mushroom': 'Vegetables',
    'green bean': 'Vegetables',
    'green beans': 'Vegetables',
    'string beans': 'Vegetables',
    'asparagus': 'Vegetables',
    'artichoke': 'Vegetables',
    'artichokes': 'Vegetables',
    'radish': 'Vegetables',
    'radishes': 'Vegetables',
    'beet': 'Vegetables',
    'beets': 'Vegetables',
    'beetroot': 'Vegetables',
    'eggplant': 'Vegetables',
    'aubergine': 'Vegetables',
    'parsnip': 'Vegetables',
    'turnip': 'Vegetables',
    'rutabaga': 'Vegetables',
    'leek': 'Vegetables',
    'leeks': 'Vegetables',
    'fennel': 'Vegetables',
    'okra': 'Vegetables',
    'watercress': 'Vegetables',
    'endive': 'Vegetables',
    'radicchio': 'Vegetables',
    'kohlrabi': 'Vegetables',
    'jicama': 'Vegetables',
    'bamboo shoots': 'Vegetables',
    'bean sprouts': 'Vegetables',
    'water chestnut': 'Vegetables',
    'parsley': 'Vegetables',
    'cilantro': 'Vegetables',
    'coriander': 'Vegetables',
    'basil': 'Vegetables',
    'dill': 'Vegetables',
    'rosemary': 'Vegetables',
    'thyme': 'Vegetables',
    'sage': 'Vegetables',
    'mint': 'Vegetables',
    'chives': 'Vegetables',
    'tarragon': 'Vegetables',
    'oregano': 'Vegetables',
    'bay leaves': 'Vegetables',
    'lemongrass': 'Vegetables',
    
    // ═══════════════════════════════════════════════════════════════════
    // BREAD & GRAINS 🍞 (50+ items)
    // ═══════════════════════════════════════════════════════════════════
    'bread': 'Bread & Grains',
    'white bread': 'Bread & Grains',
    'wheat bread': 'Bread & Grains',
    'whole wheat': 'Bread & Grains',
    'sourdough': 'Bread & Grains',
    'rye bread': 'Bread & Grains',
    'pumpernickel': 'Bread & Grains',
    'baguette': 'Bread & Grains',
    'ciabatta': 'Bread & Grains',
    'focaccia': 'Bread & Grains',
    'pita': 'Bread & Grains',
    'naan': 'Bread & Grains',
    'flatbread': 'Bread & Grains',
    'tortilla': 'Bread & Grains',
    'tortillas': 'Bread & Grains',
    'wrap': 'Bread & Grains',
    'wraps': 'Bread & Grains',
    'bagel': 'Bread & Grains',
    'bagels': 'Bread & Grains',
    'english muffin': 'Bread & Grains',
    'croissant': 'Bread & Grains',
    'muffin': 'Bread & Grains',
    'biscuit': 'Bread & Grains',
    'roll': 'Bread & Grains',
    'rolls': 'Bread & Grains',
    'bun': 'Bread & Grains',
    'buns': 'Bread & Grains',
    'hamburger bun': 'Bread & Grains',
    'hot dog bun': 'Bread & Grains',
    'croutons': 'Bread & Grains',
    'breadcrumbs': 'Bread & Grains',
    'panko': 'Bread & Grains',
    'rice': 'Bread & Grains',
    'white rice': 'Bread & Grains',
    'brown rice': 'Bread & Grains',
    'jasmine rice': 'Bread & Grains',
    'basmati rice': 'Bread & Grains',
    'wild rice': 'Bread & Grains',
    'arborio rice': 'Bread & Grains',
    'sushi rice': 'Bread & Grains',
    'fried rice': 'Bread & Grains',
    'rice cake': 'Bread & Grains',
    'pasta': 'Bread & Grains',
    'spaghetti': 'Bread & Grains',
    'penne': 'Bread & Grains',
    'rigatoni': 'Bread & Grains',
    'fusilli': 'Bread & Grains',
    'farfalle': 'Bread & Grains',
    'linguine': 'Bread & Grains',
    'fettuccine': 'Bread & Grains',
    'lasagna': 'Bread & Grains',
    'macaroni': 'Bread & Grains',
    'ravioli': 'Bread & Grains',
    'tortellini': 'Bread & Grains',
    'gnocchi': 'Bread & Grains',
    'orzo': 'Bread & Grains',
    'noodles': 'Bread & Grains',
    'ramen': 'Bread & Grains',
    'udon': 'Bread & Grains',
    'soba': 'Bread & Grains',
    'rice noodles': 'Bread & Grains',
    'egg noodles': 'Bread & Grains',
    'cereal': 'Bread & Grains',
    'cheerios': 'Bread & Grains',
    'cornflakes': 'Bread & Grains',
    'granola': 'Bread & Grains',
    'muesli': 'Bread & Grains',
    'oats': 'Bread & Grains',
    'oatmeal': 'Bread & Grains',
    'instant oatmeal': 'Bread & Grains',
    'steel cut oats': 'Bread & Grains',
    'flour': 'Bread & Grains',
    'all purpose flour': 'Bread & Grains',
    'bread flour': 'Bread & Grains',
    'cake flour': 'Bread & Grains',
    'whole wheat flour': 'Bread & Grains',
    'almond flour': 'Bread & Grains',
    'coconut flour': 'Bread & Grains',
    'quinoa': 'Bread & Grains',
    'couscous': 'Bread & Grains',
    'bulgur': 'Bread & Grains',
    'farro': 'Bread & Grains',
    'barley': 'Bread & Grains',
    'millet': 'Bread & Grains',
    'buckwheat': 'Bread & Grains',
    'polenta': 'Bread & Grains',
    'cornmeal': 'Bread & Grains',
    'grits': 'Bread & Grains',
    'cornstarch': 'Bread & Grains',
    'tapioca': 'Bread & Grains',
    'crackers': 'Bread & Grains',
    'chips': 'Bread & Grains',
    'tortilla chips': 'Bread & Grains',
    'pretzels': 'Bread & Grains',
    'popcorn': 'Bread & Grains',
    
    // ═══════════════════════════════════════════════════════════════════
    // CONDIMENTS & SAUCES 🧂 (60+ items)
    // ═══════════════════════════════════════════════════════════════════
    'ketchup': 'Condiments',
    'catsup': 'Condiments',
    'mustard': 'Condiments',
    'dijon': 'Condiments',
    'yellow mustard': 'Condiments',
    'mayonnaise': 'Condiments',
    'mayo': 'Condiments',
    'miracle whip': 'Condiments',
    'relish': 'Condiments',
    'tartar sauce': 'Condiments',
    'bbq sauce': 'Condiments',
    'barbecue sauce': 'Condiments',
    'hot sauce': 'Condiments',
    'sriracha': 'Condiments',
    'tabasco': 'Condiments',
    'buffalo sauce': 'Condiments',
    'wing sauce': 'Condiments',
    'salsa': 'Condiments',
    'pico de gallo': 'Condiments',
    'guacamole': 'Condiments',
    'soy sauce': 'Condiments',
    'tamari': 'Condiments',
    'teriyaki': 'Condiments',
    'hoisin': 'Condiments',
    'fish sauce': 'Condiments',
    'oyster sauce': 'Condiments',
    'worcestershire': 'Condiments',
    'steak sauce': 'Condiments',
    'a1 sauce': 'Condiments',
    'pasta sauce': 'Condiments',
    'marinara': 'Condiments',
    'tomato sauce': 'Condiments',
    'tomato paste': 'Condiments',
    'alfredo sauce': 'Condiments',
    'pesto': 'Condiments',
    'salad dressing': 'Condiments',
    'ranch dressing': 'Condiments',
    'ranch': 'Condiments',
    'italian dressing': 'Condiments',
    'caesar dressing': 'Condiments',
    'balsamic': 'Condiments',
    'vinaigrette': 'Condiments',
    'oil': 'Condiments',
    'olive oil': 'Condiments',
    'vegetable oil': 'Condiments',
    'canola oil': 'Condiments',
    'coconut oil': 'Condiments',
    'sesame oil': 'Condiments',
    'avocado oil': 'Condiments',
    'peanut oil': 'Condiments',
    'vinegar': 'Condiments',
    'apple cider vinegar': 'Condiments',
    'white vinegar': 'Condiments',
    'red wine vinegar': 'Condiments',
    'balsamic vinegar': 'Condiments',
    'rice vinegar': 'Condiments',
    'sugar': 'Condiments',
    'brown sugar': 'Condiments',
    'powdered sugar': 'Condiments',
    'honey': 'Condiments',
    'maple syrup': 'Condiments',
    'agave': 'Condiments',
    'molasses': 'Condiments',
    'corn syrup': 'Condiments',
    'jam': 'Condiments',
    'jelly': 'Condiments',
    'preserves': 'Condiments',
    'marmalade': 'Condiments',
    'peanut butter': 'Condiments',
    'almond butter': 'Condiments',
    'nutella': 'Condiments',
    'salt': 'Condiments',
    'sea salt': 'Condiments',
    'kosher salt': 'Condiments',
    'pepper': 'Condiments',
    'black pepper': 'Condiments',
    'white pepper': 'Condiments',
    'spice': 'Condiments',
    'spices': 'Condiments',
    'seasoning': 'Condiments',
    'cinnamon': 'Condiments',
    'paprika': 'Condiments',
    'cumin': 'Condiments',
    'turmeric': 'Condiments',
    'curry powder': 'Condiments',
    'chili powder': 'Condiments',
    'cayenne': 'Condiments',
    'garlic powder': 'Condiments',
    'onion powder': 'Condiments',
    'italian seasoning': 'Condiments',
    'taco seasoning': 'Condiments',
    'everything bagel': 'Condiments',
    'vanilla': 'Condiments',
    'vanilla extract': 'Condiments',
    'cocoa powder': 'Condiments',
    'baking powder': 'Condiments',
    'baking soda': 'Condiments',
    'yeast': 'Condiments',
    
    // ═══════════════════════════════════════════════════════════════════
    // BEVERAGES 🥤 (40+ items)
    // ═══════════════════════════════════════════════════════════════════
    'water': 'Beverages',
    'sparkling water': 'Beverages',
    'seltzer': 'Beverages',
    'mineral water': 'Beverages',
    'tonic water': 'Beverages',
    'juice': 'Beverages',
    'orange juice': 'Beverages',
    'apple juice': 'Beverages',
    'grape juice': 'Beverages',
    'cranberry juice': 'Beverages',
    'tomato juice': 'Beverages',
    'lemonade': 'Beverages',
    'limeade': 'Beverages',
    'fruit punch': 'Beverages',
    'soda': 'Beverages',
    'cola': 'Beverages',
    'coke': 'Beverages',
    'pepsi': 'Beverages',
    'sprite': 'Beverages',
    'ginger ale': 'Beverages',
    'root beer': 'Beverages',
    'energy drink': 'Beverages',
    'red bull': 'Beverages',
    'monster': 'Beverages',
    'sports drink': 'Beverages',
    'gatorade': 'Beverages',
    'powerade': 'Beverages',
    'coffee': 'Beverages',
    'espresso': 'Beverages',
    'cold brew': 'Beverages',
    'iced coffee': 'Beverages',
    'instant coffee': 'Beverages',
    'decaf': 'Beverages',
    'tea': 'Beverages',
    'green tea': 'Beverages',
    'black tea': 'Beverages',
    'herbal tea': 'Beverages',
    'iced tea': 'Beverages',
    'chai': 'Beverages',
    'matcha': 'Beverages',
    'kombucha': 'Beverages',
    'smoothie': 'Beverages',
    'shake': 'Beverages',
    'milkshake': 'Beverages',
    'beer': 'Beverages',
    'ipa': 'Beverages',
    'lager': 'Beverages',
    'ale': 'Beverages',
    'stout': 'Beverages',
    'wine': 'Beverages',
    'red wine': 'Beverages',
    'white wine': 'Beverages',
    'rose': 'Beverages',
    'champagne': 'Beverages',
    'prosecco': 'Beverages',
    'vodka': 'Beverages',
    'rum': 'Beverages',
    'whiskey': 'Beverages',
    'bourbon': 'Beverages',
    'gin': 'Beverages',
    'tequila': 'Beverages',
    'liquor': 'Beverages',
    'cocktail': 'Beverages',
    'hard seltzer': 'Beverages',
    
    // ═══════════════════════════════════════════════════════════════════
    // OTHER / PANTRY 📦 (40+ items)
    // ═══════════════════════════════════════════════════════════════════
    'broth': 'Other',
    'stock': 'Other',
    'chicken broth': 'Other',
    'beef broth': 'Other',
    'vegetable broth': 'Other',
    'bone broth': 'Other',
    'bouillon': 'Other',
    'soup': 'Other',
    'canned soup': 'Other',
    'canned tomatoes': 'Other',
    'diced tomatoes': 'Other',
    'crushed tomatoes': 'Other',
    'canned beans': 'Other',
    'canned tuna': 'Other',
    'canned salmon': 'Other',
    'canned chicken': 'Other',
    'canned corn': 'Other',
    'canned peas': 'Other',
    'canned fruit': 'Other',
    'coconut cream': 'Other',
    'coconut water': 'Other',
    'chocolate': 'Other',
    'chocolate chips': 'Other',
    'dark chocolate': 'Other',
    'white chocolate': 'Other',
    'candy': 'Other',
    'gummy': 'Other',
    'cookies': 'Other',
    'cookie': 'Other',
    'cake': 'Other',
    'brownie': 'Other',
    'pie': 'Other',
    'pastry': 'Other',
    'donut': 'Other',
    'doughnut': 'Other',
    'snack': 'Other',
    'snacks': 'Other',
    'protein bar': 'Other',
    'granola bar': 'Other',
    'nutrition bar': 'Other',
    'baby food': 'Other',
    'formula': 'Other',
    'pet food': 'Other',
    'dog food': 'Other',
    'cat food': 'Other',
    'frozen dinner': 'Other',
    'tv dinner': 'Other',
    'frozen pizza': 'Other',
    'frozen veggies': 'Other',
    'ice': 'Other',
    'ice cubes': 'Other',
  };

  /// Get emoji icon for category
  /// Migrates old category names to new ones
  static String migrateCategory(String category) {
    switch (category) {
      case 'Proteins':
      case 'Meats':
        return 'Meat & Protein';
      case 'Grains':
      case 'Breads':
        return 'Bread & Grains';
      case 'Produce':
        // Default produce items to Vegetables (most common case)
        return 'Vegetables';
      default:
        return category;
    }
  }

  static String getCategoryEmoji(String category) {
    switch (category) {
      case 'Fruits':
        return '🍊';
      case 'Vegetables':
        return '🥕';
      case 'Dairy':
        return '🧀';
      case 'Meat & Protein':
        return '🥩';
      case 'Beverages':
        return '🧃';
      case 'Condiments':
        return '🍯';
      case 'Bread & Grains':
        return '🥖';
      case 'Other':
        return '🛒';
      default:
        return '🍽️';
    }
  }

  /// Comprehensive unit-to-item-type mapping
  /// Suggests appropriate unit based on item characteristics
  static const Map<String, String> unitMap = {
    // Count-based items (pieces, individual units)
    'egg': 'pieces',
    'eggs': 'pieces',
    'apple': 'pieces',
    'banana': 'pieces',
    'orange': 'pieces',
    'tomato': 'pieces',
    'potato': 'pieces',
    'onion': 'pieces',
    'carrot': 'pieces',
    'bread': 'pieces',
    'roll': 'pieces',
    'bun': 'pieces',
    'bagel': 'pieces',
    'cookie': 'pieces',
    'donut': 'pieces',
    'pizza': 'pieces',

    // Liquid items (ml, l)
    'milk': 'ml',
    'water': 'ml',
    'juice': 'ml',
    'oil': 'ml',
    'vinegar': 'ml',
    'sauce': 'ml',
    'soup': 'ml',
    'broth': 'ml',
    'stock': 'ml',
    'cream': 'ml',
    'yogurt': 'ml',
    'kefir': 'ml',
    'honey': 'ml',
    'maple syrup': 'ml',
    'vanilla extract': 'ml',
    'soy sauce': 'ml',
    'hot sauce': 'ml',
    'salsa': 'ml',

    // Weight-based items (g, kg)
    'flour': 'g',
    'sugar': 'g',
    'salt': 'g',
    'rice': 'g',
    'pasta': 'g',
    'lentils': 'g',
    'nuts': 'g',
    'chocolate': 'g',
    'cheese': 'g',
    'butter': 'g',
    'meat': 'g',
    'beef': 'g',
    'pork': 'g',
    'fish': 'g',
    'shrimp': 'g',
    'spinach': 'g',
    'broccoli': 'g',
    'asparagus': 'g',
    'mushroom': 'g',
    'coffee': 'g',
    'cocoa powder': 'g',
  };

  /// Detect category from item name using fuzzy matching
  /// Returns matched category or 'Other' if no match found
  ///
  /// Algorithm:
  /// 1. Exact match (ignoring case, trimmed)
  /// 2. Partial/substring match
  /// 3. Word boundary match
  /// 4. Fuzzy match (handles typos/misspellings using Levenshtein distance)
  /// 5. Default to 'Other'
  static String detectCategory(String itemName) {
    if (itemName.isEmpty) return 'Other';

    final normalized = itemName.toLowerCase().trim();

    // 1. Exact match
    if (categoryMap.containsKey(normalized)) {
      return categoryMap[normalized]!;
    }

    // 2. Partial match (substring anywhere)
    for (final entry in categoryMap.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // 3. Word boundary match (check each word)
    final words = normalized.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length < 2) continue; // Skip very short words
      if (categoryMap.containsKey(word)) {
        return categoryMap[word]!;
      }
      // Also check if any category keyword contains this word
      for (final entry in categoryMap.entries) {
        if (entry.key.contains(word) && word.length >= 3) {
          return entry.value;
        }
      }
    }

    // 4. Fuzzy match for typos/misspellings (Levenshtein distance)
    String? bestMatch;
    int bestDistance = 999;
    final threshold = normalized.length <= 4 ? 1 : (normalized.length <= 7 ? 2 : 3);
    
    for (final entry in categoryMap.entries) {
      final keyword = entry.key;
      
      // Check full input against keyword
      final distance = _levenshteinDistance(normalized, keyword);
      if (distance <= threshold && distance < bestDistance) {
        bestDistance = distance;
        bestMatch = entry.value;
      }
      
      // Also check each word against keyword
      for (final word in words) {
        if (word.length < 3) continue; // Skip short words for fuzzy
        final wordDistance = _levenshteinDistance(word, keyword);
        final wordThreshold = word.length <= 4 ? 1 : (word.length <= 7 ? 2 : 3);
        if (wordDistance <= wordThreshold && wordDistance < bestDistance) {
          bestDistance = wordDistance;
          bestMatch = entry.value;
        }
      }
    }
    
    if (bestMatch != null) {
      return bestMatch;
    }

    return 'Other';
  }
  
  /// Calculate Levenshtein distance between two strings
  /// Used for fuzzy matching to handle typos/misspellings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = min(min(v1[j] + 1, v0[j + 1] + 1), v0[j] + cost);
      }

      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  /// Suggest unit based on item name and type
  /// Returns suggested unit or 'pieces' as default
  ///
  /// Priority:
  /// 1. Exact match from unitMap
  /// 2. Partial/substring match
  /// 3. Infer from category (liquids → ml, weights → g)
  /// 4. Default to 'pieces'
  static String suggestUnit(String itemName) {
    if (itemName.isEmpty) return 'pieces';

    final normalized = itemName.toLowerCase().trim();

    // Exact match
    if (unitMap.containsKey(normalized)) {
      return unitMap[normalized]!;
    }

    // Partial match
    for (final entry in unitMap.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Infer from category
    final category = detectCategory(itemName);
    switch (category) {
      case 'Dairy':
        // Dairy can be liquid or weight
        if (normalized.contains('milk') || 
            normalized.contains('cream') || 
            normalized.contains('yogurt')) {
          return 'ml';
        }
        return 'g'; // cheese, butter
      case 'Produce':
        // Most produce is counted or by weight
        if (normalized.contains('juice') || 
            normalized.contains('sauce') ||
            normalized.contains('oil')) {
          return 'ml';
        }
        return 'pieces'; // most produce by count
      case 'Pantry':
        // Pantry is mostly weight or volume
        if (normalized.contains('oil') || 
            normalized.contains('sauce') ||
            normalized.contains('juice') ||
            normalized.contains('milk')) {
          return 'ml';
        }
        return 'g'; // flour, rice, pasta, etc.
      case 'Proteins':
        return 'pieces'; // proteins typically counted
      default:
        return 'pieces';
    }
  }

  /// Get list of all available categories
  static List<String> getCategories() {
    return ['Fruits', 'Vegetables', 'Dairy', 'Meat & Protein', 'Beverages', 'Condiments', 'Bread & Grains', 'Other'];
  }

  /// Get list of all available units
  static List<String> getUnits() {
    return ['pieces', 'kg', 'g', 'lbs', 'oz', 'cups', 'tbsp', 'tsp', 'ml', 'l', 'bag', 'bunch', 'head'];
  }

  /// Get category color (for future visual categorization)
  /// Returns hex color string
  static String getCategoryColor(String category) {
    const colors = {
      'Fruits': '#51CF66',         // Green
      'Vegetables': '#4CAF50',     // Dark Green
      'Dairy': '#FFD43B',          // Yellow
      'Meat & Protein': '#FF6B6B', // Red
      'Beverages': '#4FC3F7',      // Blue
      'Condiments': '#FFA726',     // Orange
      'Bread & Grains': '#D4A373', // Brown
      'Other': '#A8A8A8',          // Gray
    };
    return colors[category] ?? colors['Other']!;
  }
}
