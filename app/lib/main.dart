import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_router.dart';
import 'core/session.dart';
import 'core/theme.dart';
import 'data/regive_repository.dart';
import 'features/auth/auth_provider.dart';
import 'features/home/items_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  await initializeDateFormatting('ru');
  runApp(const ReGiveApp());
}

class ReGiveApp extends StatelessWidget {
  const ReGiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ReGiveRepository>(create: (_) => ReGiveRepository()),
        ChangeNotifierProvider<SessionProvider>(
          create: (context) =>
              SessionProvider(context.read<ReGiveRepository>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<ReGiveRepository>(),
            context.read<SessionProvider>(),
          ),
        ),
        ChangeNotifierProvider<ItemsProvider>(
          create: (context) => ItemsProvider(context.read<ReGiveRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'ReGive',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: '/splash',
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
