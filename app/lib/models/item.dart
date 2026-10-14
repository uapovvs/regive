import 'package:cloud_firestore/cloud_firestore.dart';

import 'category.dart';

class ItemCondition {
  static const String newItem = 'new';
  static const String used = 'used';
}

class ItemStatus {
  static const String available = 'available';
  static const String claimed = 'claimed';
}

class ThingItem {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final int categoryId;
  final String condition;
  final String city;
  final String status;
  final String imageUrl;
  final DateTime createdAt;

  const ThingItem({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.condition,
    required this.city,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
  });

  ItemCategory get category => ItemCategory.byId(categoryId);
  String get categoryName => category.name;
  bool get isAvailable => status == ItemStatus.available;

  factory ThingItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ThingItem(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      ownerName: data['ownerName'] as String? ?? '',
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      categoryId: data['categoryId'] as int,
      condition: data['condition'] as String? ?? ItemCondition.used,
      city: data['city'] as String? ?? '',
      status: data['status'] as String? ?? ItemStatus.available,
      imageUrl: data['imageUrl'] as String? ?? '',
      // Сразу после записи serverTimestamp ещё не пришёл с сервера — берём текущее время.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
