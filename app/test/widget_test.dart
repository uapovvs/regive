import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:regive/core/session.dart';
import 'package:regive/data/regive_repository.dart';
import 'package:regive/features/auth/auth_provider.dart';
import 'package:regive/features/auth/login_screen.dart';
import 'package:regive/features/auth/register_screen.dart';

Widget _wrap(Widget screen) {
  final repository = ReGiveRepository();
  final session = SessionProvider(repository);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: session),
      ChangeNotifierProvider(create: (_) => AuthProvider(repository, session)),
    ],
    child: MaterialApp(home: screen),
  );
}

void main() {
  testWidgets('Вход: пустые поля показывают ошибки валидации', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
    await tester.pump();

    expect(find.text('Введите email'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);
  });

  testWidgets('Вход: некорректный email отклоняется', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Войти'));
    await tester.pump();

    expect(find.text('Некорректный email'), findsOneWidget);
  });

  testWidgets('Регистрация: короткие имя и пароль отклоняются', (tester) async {
    await tester.pumpWidget(_wrap(const RegisterScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'А');
    await tester.enterText(find.byType(TextFormField).at(1), 'user@mail.kz');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Зарегистрироваться'));
    await tester.pump();

    expect(find.text('Имя должно содержать минимум 2 символа'), findsOneWidget);
    expect(
      find.text('Пароль должен содержать минимум 6 символов'),
      findsOneWidget,
    );
  });
}
