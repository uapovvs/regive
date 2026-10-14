import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/regive_repository.dart';
import '../models/user.dart';

class SessionProvider extends ChangeNotifier {
  final ReGiveRepository repository;

  SessionProvider(this.repository);

  AppUser? _user;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Firebase Auth сам хранит сессию между запусками — подтягиваем только профиль.
  Future<void> restoreSession() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      await loadProfile();
    } catch (_) {
      await logout();
    }
  }

  Future<void> loadProfile() async {
    _user = await repository.fetchProfile();
    notifyListeners();
  }

  void updateUser(AppUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    notifyListeners();
  }
}
