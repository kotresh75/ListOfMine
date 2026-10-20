import 'dart:convert';

enum CategoryType {
  movies,
  places,
  books,
  custom,
}

class ListItem {
  final String id;
  final String title;
  final String subtitle; // e.g. "Paris, France" or "Directed by Nolan"
  final String categoryId;
  final bool isCompleted; // true = watched/visited/read, false = to watch/visit/read
  final double rating; // 1 to 5 stars
  final String notes;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? completedAt;

  ListItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.categoryId,
    this.isCompleted = false,
    this.rating = 0.0,
    this.notes = '',
    this.imageUrl,
    required this.createdAt,
    this.completedAt,
  });

  ListItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? categoryId,
    bool? isCompleted,
    double? rating,
    String? notes,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return ListItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'categoryId': categoryId,
      'isCompleted': isCompleted,
      'rating': rating,
      'notes': notes,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ListItem.fromMap(Map<String, dynamic> map) {
    return ListItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      categoryId: map['categoryId'] ?? 'movies',
      isCompleted: map['isCompleted'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ListItem.fromJson(String source) =>
      ListItem.fromMap(json.decode(source));
}

class CategoryDef {
  final String id;
  final String name;
  final String iconEmoji;
  final String completedVerb; // e.g. "Watched", "Visited", "Read"
  final String uncompletedVerb; // e.g. "To Watch", "Want to Visit", "Want to Read"
  final int colorValue;

  const CategoryDef({
    required this.id,
    required this.name,
    required this.iconEmoji,
    required this.completedVerb,
    required this.uncompletedVerb,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconEmoji': iconEmoji,
      'completedVerb': completedVerb,
      'uncompletedVerb': uncompletedVerb,
      'colorValue': colorValue,
    };
  }

  factory CategoryDef.fromMap(Map<String, dynamic> map) {
    return CategoryDef(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      iconEmoji: map['iconEmoji'] ?? '📌',
      completedVerb: map['completedVerb'] ?? 'Done',
      uncompletedVerb: map['uncompletedVerb'] ?? 'To Do',
      colorValue: map['colorValue'] ?? 0xFF6366F1,
    );
  }
}
