#!/bin/bash
# Download pre-trained MobileNet food recognition model

echo "📥 Downloading TensorFlow Lite Food Recognition Model..."
echo "==========================================================="

cd "$(dirname "$0")/../assets/models"

# Download MobileNet V2 Food-101 model (quantized, ~4MB)
echo "🔽 Downloading model file..."
curl -L -o food_model.tflite \
  "https://storage.googleapis.com/download.tensorflow.org/models/tflite/mobilenetv2_food101_1.0_224_quantized_1_default_1.tflite"

if [ $? -ne 0 ]; then
    echo "❌ Failed to download model"
    echo "⚠️  Trying alternative source..."
    
    # Alternative: Download from TensorFlow Hub
    curl -L -o food_model.tflite \
      "https://tfhub.dev/google/lite-model/aiy/vision/classifier/food_V1/1?lite-format=tflite"
fi

# Create labels file (Food-101 categories)
echo "📝 Creating labels file..."
cat > food_labels.txt << 'EOF'
apple_pie
baby_back_ribs
baklava
beef_carpaccio
beef_tartare
beet_salad
beignets
bibimbap
bread_pudding
breakfast_burrito
bruschetta
caesar_salad
cannoli
caprese_salad
carrot_cake
ceviche
cheese_plate
cheesecake
chicken_curry
chicken_quesadilla
chicken_wings
chocolate_cake
chocolate_mousse
churros
clam_chowder
club_sandwich
crab_cakes
creme_brulee
croque_madame
cup_cakes
deviled_eggs
donuts
dumplings
edamame
eggs_benedict
escargots
falafel
filet_mignon
fish_and_chips
foie_gras
french_fries
french_onion_soup
french_toast
fried_calamari
fried_rice
frozen_yogurt
garlic_bread
gnocchi
greek_salad
grilled_cheese_sandwich
grilled_salmon
guacamole
gyoza
hamburger
hot_and_sour_soup
hot_dog
huevos_rancheros
hummus
ice_cream
lasagna
lobster_bisque
lobster_roll_sandwich
macaroni_and_cheese
macarons
miso_soup
mussels
nachos
omelette
onion_rings
oysters
pad_thai
paella
pancakes
panna_cotta
peking_duck
pho
pizza
pork_chop
poutine
prime_rib
pulled_pork_sandwich
ramen
ravioli
red_velvet_cake
risotto
samosa
sashimi
scallops
seaweed_salad
shrimp_and_grits
spaghetti_bolognese
spaghetti_carbonara
spring_rolls
steak
strawberry_shortcake
sushi
tacos
takoyaki
tiramisu
tuna_tartare
waffles
EOF

# Verify files
if [ -f "food_model.tflite" ] && [ -f "food_labels.txt" ]; then
    MODEL_SIZE=$(ls -lh food_model.tflite | awk '{print $5}')
    LABEL_COUNT=$(wc -l < food_labels.txt)
    
    echo "==========================================================="
    echo "✅ Download complete!"
    echo "📦 Model size: $MODEL_SIZE"
    echo "🏷️  Categories: $LABEL_COUNT foods"
    echo ""
    echo "Files created:"
    echo "  - assets/models/food_model.tflite"
    echo "  - assets/models/food_labels.txt"
    echo "==========================================================="
else
    echo "❌ Download failed. Please check your internet connection."
    exit 1
fi
