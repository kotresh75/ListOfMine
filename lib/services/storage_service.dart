import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/list_item.dart';

class StorageService {
  static const String _itemsKey = 'listofmine_items_v1';
  static const String _customCategoriesKey = 'listofmine_custom_cats_v1';

  static final List<CategoryDef> defaultCategories = [
    const CategoryDef(
      id: 'movies',
      name: 'Movies & Series',
      iconEmoji: '🎬',
      completedVerb: 'Watched',
      uncompletedVerb: 'To Watch',
      colorValue: 0xFF8B5CF6, // Purple
    ),
    const CategoryDef(
      id: 'places',
      name: 'Places & Travel',
      iconEmoji: '✈️',
      completedVerb: 'Visited',
      uncompletedVerb: 'Want to Visit',
      colorValue: 0xFF06B6D4, // Cyan
    ),
    const CategoryDef(
      id: 'books',
      name: 'Books & Reading',
      iconEmoji: '📚',
      completedVerb: 'Read',
      uncompletedVerb: 'To Read',
      colorValue: 0xFF10B981, // Emerald
    ),
    const CategoryDef(
      id: 'food',
      name: 'Food & Cafes',
      iconEmoji: '🍕',
      completedVerb: 'Tried',
      uncompletedVerb: 'Must Try',
      colorValue: 0xFFF59E0B, // Amber
    ),
  ];

  static Future<List<CategoryDef>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final customListRaw = prefs.getStringList(_customCategoriesKey) ?? [];
    final List<CategoryDef> list = [...defaultCategories];
    for (final raw in customListRaw) {
      try {
        final decoded = json.decode(raw);
        list.add(CategoryDef.fromMap(decoded));
      } catch (e) {
        debugPrint('Error loading custom category: $e');
      }
    }
    return list;
  }

  static Future<void> saveCustomCategory(CategoryDef cat) async {
    final prefs = await SharedPreferences.getInstance();
    final customListRaw = prefs.getStringList(_customCategoriesKey) ?? [];
    customListRaw.add(json.encode(cat.toMap()));
    await prefs.setStringList(_customCategoriesKey, customListRaw);
  }

  static Future<List<ListItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_itemsKey);
    if (rawList == null) {
      // Seed initial dummy data for pleasant first-open experience
      final initialData = _generateInitialSampleData();
      await saveItems(initialData);
      return initialData;
    }

    return rawList
        .map((str) {
          try {
            return ListItem.fromJson(str);
          } catch (e) {
            return null;
          }
        })
        .whereType<ListItem>()
        .toList();
  }

  static Future<void> saveItems(List<ListItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = items.map((i) => i.toJson()).toList();
    await prefs.setStringList(_itemsKey, rawList);

    // Update Home Screen Widget
    await updateHomeScreenWidget(items);
  }

  static Future<void> updateHomeScreenWidget(List<ListItem> items) async {
    // Skip if running in tests or unsupported environments
    if (kIsWeb) return;
    try {
      final movies = items.where((i) => i.categoryId == 'movies').toList();
      final moviesWatched = movies.where((i) => i.isCompleted).length;
      final places = items.where((i) => i.categoryId == 'places').toList();
      final placesVisited = places.where((i) => i.isCompleted).length;

      // Find the most recent pending item or last added item
      final pendingItems = items.where((i) => !i.isCompleted).toList();
      String latestItem = 'All caught up!';
      String latestCategory = 'ListofMine';

      if (pendingItems.isNotEmpty) {
        final nextItem = pendingItems.first;
        latestItem = nextItem.title;
        latestCategory = nextItem.categoryId.toUpperCase();
      } else if (items.isNotEmpty) {
        latestItem = items.first.title;
        latestCategory = 'RECENT';
      }

      await HomeWidget.saveWidgetData<String>(
        'movies_stat',
        '🎬 $moviesWatched / ${movies.length}',
      );
      await HomeWidget.saveWidgetData<String>(
        'places_stat',
        '✈️ $placesVisited / ${places.length}',
      );
      await HomeWidget.saveWidgetData<String>('latest_item', latestItem);
      await HomeWidget.saveWidgetData<String>(
        'latest_category',
        'NEXT: $latestCategory',
      );

      // Trigger update on Android
      await HomeWidget.updateWidget(
        name: 'ListAppWidgetProvider',
        androidName: 'ListAppWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  static List<ListItem> _generateInitialSampleData() {
    return [
      ListItem(
        id: '1',
        title: 'Interstellar',
        subtitle: '2014 • Christopher Nolan',
        categoryId: 'movies',
        isCompleted: true,
        rating: 5.0,
        notes: 'Masterpiece of visual storytelling and music.',
        imageUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Video5/v4/94/0b/4e/940b4e58-6628-dfb4-2565-5521c11dcdd4/pr_source.lsr/600x600bb.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ListItem(
        id: '2',
        title: 'Dune: Part Two',
        subtitle: '2024 • Denis Villeneuve',
        categoryId: 'movies',
        isCompleted: false,
        rating: 0.0,
        notes: 'Watch in IMAX theater',
        imageUrl: 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ListItem(
        id: '3',
        title: 'Kyoto, Japan',
        subtitle: 'Fushimi Inari & Arashiyama',
        categoryId: 'places',
        isCompleted: true,
        rating: 5.0,
        notes: 'Incredible cherry blossoms and peaceful temples.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        completedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ListItem(
        id: '4',
        title: 'Santorini, Greece',
        subtitle: 'Oia Sunsets & Aegean Sea',
        categoryId: 'places',
        isCompleted: false,
        rating: 0.0,
        notes: 'Summer vacation wishlist',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ListItem(
        id: '5',
        title: 'Atomic Habits',
        subtitle: 'James Clear',
        categoryId: 'books',
        isCompleted: true,
        rating: 4.5,
        notes: '1% better every day adds up.',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        completedAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
    ];
  }
}
