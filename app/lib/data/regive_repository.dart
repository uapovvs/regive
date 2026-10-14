import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/deal.dart';
import '../models/item.dart';
import '../models/user.dart';
import 'app_exception.dart';

/// Доступ к данным приложения в Cloud Firestore.
///
/// Структура БД: users/{uid}, users/{uid}/favorites/{itemId}, items/{id}, deals/{id}.
class ReGiveRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const AppException('Сессия истекла, войдите снова');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');
  CollectionReference<Map<String, dynamic>> get _deals =>
      _db.collection('deals');
  CollectionReference<Map<String, dynamic>> get _favorites =>
      _users.doc(_uid).collection('favorites');

  // ---------- Профиль ----------

  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
  }) {
    return _guard(
      () => _users.doc(uid).set({
        'name': name,
        'email': email,
        'phone': null,
        'city': null,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<AppUser> fetchProfile() {
    return _guard(() async {
      final uid = _uid;
      final doc = await _users.doc(uid).get();
      if (!doc.exists) throw const AppException('Профиль не найден');
      return AppUser.fromMap(uid, doc.data()!);
    });
  }

  Future<AppUser> updateProfile({
    required String name,
    required String phone,
    required String city,
  }) {
    return _guard(() async {
      await _users.doc(_uid).update({
        'name': name,
        'phone': phone,
        'city': city,
      });
      return fetchProfile();
    });
  }

  Future<AppUser> updateProfilePhoto(Uint8List bytes) {
    return _guard(() async {
      final uid = _uid;
      await _users.doc(uid).update({'photoUrl': _encodeImage(bytes)});
      return fetchProfile();
    });
  }

  // ---------- Вещи (CRUD) ----------

  /// Firestore не умеет поиск по подстроке, поэтому поиск и фильтр
  /// выполняются на клиенте поверх списка, отсортированного по дате.
  Future<List<ThingItem>> fetchItems({String search = '', int? categoryId}) {
    return _guard(() async {
      final snapshot = await _items
          .orderBy('createdAt', descending: true)
          .get();
      final query = search.trim().toLowerCase();
      return snapshot.docs
          .map(ThingItem.fromDoc)
          .where((item) => categoryId == null || item.categoryId == categoryId)
          .where(
            (item) => query.isEmpty || item.title.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<ThingItem> fetchItem(String id) {
    return _guard(() async {
      final doc = await _items.doc(id).get();
      if (!doc.exists) throw const AppException('Вещь не найдена');
      return ThingItem.fromDoc(doc);
    });
  }

  Future<void> createItem({
    required String ownerName,
    required String title,
    required String description,
    required int categoryId,
    required String condition,
    required String city,
    required Uint8List imageBytes,
  }) {
    return _guard(() async {
      final uid = _uid;
      final docRef = _items.doc();
      final imageUrl = _encodeImage(imageBytes);
      await docRef.set({
        'ownerId': uid,
        'ownerName': ownerName,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'condition': condition,
        'city': city,
        'status': ItemStatus.available,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateItem(
    String id, {
    required String title,
    required String description,
    required int categoryId,
    required String condition,
    required String city,
    Uint8List? imageBytes,
  }) {
    return _guard(() async {
      final data = <String, dynamic>{
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'condition': condition,
        'city': city,
      };
      if (imageBytes != null) {
        data['imageUrl'] = _encodeImage(imageBytes);
      }
      await _items.doc(id).update(data);
    });
  }

  // Firebase Storage в проекте не включён, поэтому сжатое фото хранится
  // прямо в документе Firestore как data URI (лимит документа — 1 МБ).
  static String _encodeImage(Uint8List bytes) {
    if (bytes.length > 700 * 1024) {
      throw const AppException('Фото слишком большое, выберите другое');
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> deleteItem(String id) {
    return _guard(() async {
      await _items.doc(id).delete();
      await _favorites.doc(id).delete();
    });
  }

  /// Забрать вещь: в одной транзакции меняем статус и создаём запись в истории,
  /// чтобы два пользователя не смогли забрать одну вещь одновременно.
  Future<void> claimItem(String itemId, {required String receiverName}) {
    return _guard(
      () => _db.runTransaction((tx) async {
        final ref = _items.doc(itemId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) throw const AppException('Вещь не найдена');

        final item = ThingItem.fromDoc(snapshot);
        if (!item.isAvailable) throw const AppException('Эту вещь уже забрали');
        if (item.ownerId == _uid) {
          throw const AppException('Нельзя забрать собственное объявление');
        }

        tx.update(ref, {'status': ItemStatus.claimed});
        tx.set(_deals.doc(), {
          'itemId': item.id,
          'itemTitle': item.title,
          'giverId': item.ownerId,
          'giverName': item.ownerName,
          'receiverId': _uid,
          'receiverName': receiverName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }),
    );
  }

  // ---------- Избранное ----------

  Future<Set<String>> fetchFavoriteIds() {
    return _guard(() async {
      final snapshot = await _favorites.get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<List<ThingItem>> fetchFavoriteItems() {
    return _guard(() async {
      final ids = await fetchFavoriteIds();
      final docs = await Future.wait(ids.map((id) => _items.doc(id).get()));
      final items =
          docs.where((doc) => doc.exists).map(ThingItem.fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<void> addFavorite(String itemId) {
    return _guard(
      () => _favorites.doc(itemId).set({
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<void> removeFavorite(String itemId) {
    return _guard(() => _favorites.doc(itemId).delete());
  }

  // ---------- История сделок ----------

  Future<List<DealRecord>> fetchHistory() {
    return _guard(() async {
      final uid = _uid;
      final results = await Future.wait([
        _deals.where('giverId', isEqualTo: uid).get(),
        _deals.where('receiverId', isEqualTo: uid).get(),
      ]);
      final deals =
          results
              .expand((snapshot) => snapshot.docs)
              .map((doc) => DealRecord.fromDoc(doc, uid))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return deals;
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException(_describe(e));
    }
  }

  static String _describe(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Недостаточно прав для этого действия';
      case 'unavailable':
        return 'Нет соединения с сервером. Проверьте интернет';
      case 'not-found':
        return 'Запись не найдена';
      default:
        return 'Ошибка базы данных: ${e.message ?? e.code}';
    }
  }
}
