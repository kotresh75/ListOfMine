import 'package:flutter_test/flutter_test.dart';
import 'package:listofmine/models/list_item.dart';

void main() {
  group('ListItem & CategoryDef Tests', () {
    test('ListItem serialization and deserialization', () {
      final item = ListItem(
        id: '101',
        title: 'Inception',
        subtitle: 'Sci-Fi / Christopher Nolan',
        categoryId: 'movies',
        isCompleted: true,
        rating: 5.0,
        notes: 'Mind bending classic',
        createdAt: DateTime(2026, 1, 1),
        completedAt: DateTime(2026, 1, 2),
      );

      final map = item.toMap();
      expect(map['title'], 'Inception');
      expect(map['isCompleted'], true);
      expect(map['rating'], 5.0);

      final fromMap = ListItem.fromMap(map);
      expect(fromMap.title, item.title);
      expect(fromMap.isCompleted, true);
      expect(fromMap.rating, 5.0);
    });

    test('ListItem copyWith toggle status', () {
      final item = ListItem(
        id: '102',
        title: 'Mount Fuji',
        categoryId: 'places',
        isCompleted: false,
        createdAt: DateTime(2026, 1, 1),
      );

      final completedItem = item.copyWith(
        isCompleted: true,
        completedAt: DateTime(2026, 2, 1),
      );

      expect(completedItem.isCompleted, true);
      expect(completedItem.completedAt, isNotNull);
    });

    test('CategoryDef verbs and serialization', () {
      const cat = CategoryDef(
        id: 'places',
        name: 'Places & Travel',
        iconEmoji: '✈️',
        completedVerb: 'Visited',
        uncompletedVerb: 'Want to Visit',
        colorValue: 0xFF06B6D4,
      );

      expect(cat.completedVerb, 'Visited');
      expect(cat.uncompletedVerb, 'Want to Visit');

      final map = cat.toMap();
      final restored = CategoryDef.fromMap(map);
      expect(restored.name, 'Places & Travel');
      expect(restored.iconEmoji, '✈️');
    });
  });
}
