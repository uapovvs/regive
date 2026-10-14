import 'package:flutter/material.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/home/home_shell.dart';
import '../features/item_detail/item_detail_screen.dart';
import '../features/item_form/item_form_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/splash/splash_screen.dart';
import '../models/item.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeShell());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case '/item-detail':
        final itemId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ItemDetailScreen(itemId: itemId),
        );
      case '/item-form':
        final existingItem = settings.arguments as ThingItem?;
        return MaterialPageRoute(
          builder: (_) => ItemFormScreen(existingItem: existingItem),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
