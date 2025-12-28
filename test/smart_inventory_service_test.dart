import 'package:flutter_test/flutter_test.dart';
import 'package:lunchbox/services/smart_inventory_service.dart';

void main() {
  group('SmartInventoryService', () {
    group('calculateSimilarity', () {
      test('exact match returns 1.0', () {
        expect(
          SmartInventoryService.calculateSimilarity('Apple', 'Apple'),
          1.0,
        );
      });

      test('case-insensitive exact match returns 1.0', () {
        expect(
          SmartInventoryService.calculateSimilarity('apple', 'APPLE'),
          1.0,
        );
      });

      test('contains match returns high similarity', () {
        final similarity = SmartInventoryService.calculateSimilarity(
          'Apple',
          'Green Apple',
        );
        expect(similarity, greaterThanOrEqualTo(0.85));
      });

      test('known variations return high similarity', () {
        final similarity = SmartInventoryService.calculateSimilarity(
          'Milk',
          'Whole Milk',
        );
        expect(similarity, greaterThanOrEqualTo(0.75));
      });

      test('different items return low similarity', () {
        final similarity = SmartInventoryService.calculateSimilarity(
          'Apple',
          'Orange',
        );
        expect(similarity, lessThan(0.5));
      });
    });

    group('mergeWithExistingInventory', () {
      test('new items are added', () {
        final detected = [
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '85.5'},
          {'name': 'Orange', 'quantity': '1', 'unit': 'pieces', 'confidence': '90.0'},
        ];
        final existing = <Map<String, dynamic>>[];

        final result = SmartInventoryService.mergeWithExistingInventory(
          detectedItems: detected,
          existingItems: existing,
        );

        expect(result.itemsToAdd.length, 2);
        expect(result.itemsToUpdate.length, 0);
        expect(result.itemsToAdd[0]['name'], 'Apple');
        expect(result.itemsToAdd[1]['name'], 'Orange');
      });

      test('duplicate detections are counted', () {
        final detected = [
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '85.5'},
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '82.0'},
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '88.5'},
        ];
        final existing = <Map<String, dynamic>>[];

        final result = SmartInventoryService.mergeWithExistingInventory(
          detectedItems: detected,
          existingItems: existing,
        );

        expect(result.itemsToAdd.length, 1);
        expect(result.itemsToAdd[0]['name'], 'Apple');
        expect(result.itemsToAdd[0]['quantity'], '3'); // 3 apples detected
      });

      test('similar existing items are updated', () {
        final detected = [
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '85.5'},
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '82.0'},
        ];
        final existing = [
          {'name': 'Gala Apple', 'quantity': '3', 'unit': 'pieces', 'category': 'Fruits'},
        ];

        final result = SmartInventoryService.mergeWithExistingInventory(
          detectedItems: detected,
          existingItems: existing,
        );

        expect(result.itemsToAdd.length, 0);
        expect(result.itemsToUpdate.length, 1);
        expect(result.itemsToUpdate[0]['item']['quantity'], '5'); // 3 + 2
        expect(result.itemsToUpdate[0]['addedCount'], 2);
      });

      test('mixed new and updated items', () {
        final detected = [
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '85.5'},
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '82.0'},
          {'name': 'Orange', 'quantity': '1', 'unit': 'pieces', 'confidence': '90.0'},
          {'name': 'Milk', 'quantity': '1', 'unit': 'pieces', 'confidence': '88.0'},
        ];
        final existing = [
          {'name': 'Gala Apple', 'quantity': '3', 'unit': 'pieces', 'category': 'Fruits'},
          {'name': 'Whole Milk', 'quantity': '1', 'unit': 'pieces', 'category': 'Dairy'},
        ];

        final result = SmartInventoryService.mergeWithExistingInventory(
          detectedItems: detected,
          existingItems: existing,
        );

        expect(result.itemsToAdd.length, 1); // Orange is new
        expect(result.itemsToUpdate.length, 2); // Apple and Milk updated
        expect(result.itemsToAdd[0]['name'], 'Orange');
      });

      test('respects similarity threshold', () {
        final detected = [
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '85.5'},
        ];
        final existing = [
          {'name': 'Orange', 'quantity': '1', 'unit': 'pieces', 'category': 'Fruits'},
        ];

        // With default threshold (0.75), Apple and Orange should NOT merge
        final result = SmartInventoryService.mergeWithExistingInventory(
          detectedItems: detected,
          existingItems: existing,
        );

        expect(result.itemsToAdd.length, 1); // Apple added as new
        expect(result.itemsToUpdate.length, 0); // Orange not updated
      });

      test('auto-categorizes new items', () {
        final detected = [
          {'name': 'Apple', 'quantity': '1', 'unit': 'pieces', 'confidence': '85.5'},
          {'name': 'Carrot', 'quantity': '1', 'unit': 'pieces', 'confidence': '90.0'},
          {'name': 'Milk', 'quantity': '1', 'unit': 'pieces', 'confidence': '88.0'},
          {'name': 'Chicken', 'quantity': '1', 'unit': 'pieces', 'confidence': '92.0'},
        ];
        final existing = <Map<String, dynamic>>[];

        final result = SmartInventoryService.mergeWithExistingInventory(
          detectedItems: detected,
          existingItems: existing,
        );

        expect(result.itemsToAdd.length, 4);
        
        final apple = result.itemsToAdd.firstWhere((item) => item['name'] == 'Apple');
        expect(apple['category'], 'Fruits');
        
        final carrot = result.itemsToAdd.firstWhere((item) => item['name'] == 'Carrot');
        expect(carrot['category'], 'Vegetables');
        
        final milk = result.itemsToAdd.firstWhere((item) => item['name'] == 'Milk');
        expect(milk['category'], 'Dairy');
        
        final chicken = result.itemsToAdd.firstWhere((item) => item['name'] == 'Chicken');
        expect(chicken['category'], 'Meat & Protein');
      });
    });

    group('SmartMergeResult', () {
      test('getSummary returns correct summary', () {
        final result = SmartMergeResult(
          itemsToAdd: [
            {'name': 'Apple'},
            {'name': 'Orange'},
          ],
          itemsToUpdate: [
            {'index': 0},
          ],
          duplicatesSkipped: [],
        );

        expect(result.getSummary(), '2 new, 1 updated');
        expect(result.totalChanges, 3);
      });

      test('getSummary handles empty results', () {
        final result = SmartMergeResult(
          itemsToAdd: [],
          itemsToUpdate: [],
          duplicatesSkipped: ['Milk'],
        );

        expect(result.getSummary(), '1 duplicates');
        expect(result.totalChanges, 0);
      });
    });
  });
}
