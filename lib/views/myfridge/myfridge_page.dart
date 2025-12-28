import 'package:flutter/material.dart';
import 'myfridge_state.dart';
import 'myfridge_dialogs.dart';
import 'myfridge_barcode.dart';
import 'myfridge_photo.dart';
import 'myfridge_widgets.dart';

/// Fridge inventory management page.
/// 
/// Allows users to:
/// - View their fridge contents
/// - Add new items with quantities
/// - Edit existing items
/// - Delete items
/// 
/// Data is synced with Firebase Firestore.
class MyFridgePage extends StatefulWidget {
  const MyFridgePage({super.key});

  @override
  State<MyFridgePage> createState() => _MyFridgePageState();
}

class _MyFridgePageState extends State<MyFridgePage>
    with MyFridgeStateMixin, MyFridgeBarcodesMixin, MyFridgePhotoMixin {
  
  @override
  void initState() {
    super.initState();
    fetchFridgeContents();
  }

  // ============= Dialog handlers =============
  
  void _showFridgeItemDialog({Map<String, dynamic>? item, int? index}) {
    if (item == null) {
      MyFridgeDialogs.showQuickAddDialog(
        context: context,
        onAdd: addItem,
      );
    } else {
      MyFridgeDialogs.showFullEditDialog(
        context: context,
        item: item,
        index: index!,
        onEdit: editItem,
        onDelete: deleteItem,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: fridgeItems.isEmpty
          ? MyFridgeWidgets.buildEmptyState()
          : Column(
              children: [
                // Category filter chips
                if (categories.isNotEmpty)
                  MyFridgeWidgets.buildCategoryFilter(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    fridgeItems: fridgeItems,
                    filteredItems: filteredItems,
                    onCategorySelected: setSelectedCategory,
                  ),
                // Items list
                Expanded(
                  child: filteredItems.isEmpty
                      ? MyFridgeWidgets.buildEmptyFilteredState(selectedCategory)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final actualIndex = fridgeItems.indexOf(item);
                            return MyFridgeWidgets.buildFridgeItemCard(
                              item: item,
                              index: actualIndex,
                              onTap: () => _showFridgeItemDialog(
                                item: item,
                                index: actualIndex,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: MyFridgeWidgets.buildFABColumn(
        onScan: scanBarcode,
        onPhoto: showPhotoModeDialog,
        onAdd: () => _showFridgeItemDialog(),
      ),
    );
  }
}
