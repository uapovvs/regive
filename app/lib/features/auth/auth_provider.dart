import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/session.dart';
import '../../data/app_exception.dart';
import '../../data/regive_repository.dart';

class AuthProvider extends ChangeNotifier {
  final ReGiveRepository repository;
  final SessionProvider session;

  AuthProvider(this.repository, this.session);

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<bool> login({required String email, required String password}) {
    return _run(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _run(() async {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      await repository.createProfile(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
      );
    });
  }

  Future<bool> _run(Future<void> Function() authAction) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await authAction();
      await session.loadProfile();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _describe(e);
      return false;
    } on AppException catch (e) {
      _error = e.message;
      await FirebaseAuth.instance.signOut();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  static String _describe(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'email-already-in-use':
        return 'Пользователь с таким email уже зарегистрирован';
      case 'weak-password':
        return 'Слишком простой пароль (минимум 6 символов)';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'too-many-requests':
        return 'Слишком много попыток. Повторите позже';
      case 'network-request-failed':
        return 'Нет подключения к интернету';
      default:
        return 'Ошибка авторизации: ${e.message ?? e.code}';
    }
  }
}
