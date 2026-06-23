import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'data/storage/storage_service.dart';
import 'data/storage/secure_storage_service.dart';
import 'providers/app_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/security_provider.dart';
import 'widgets/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.create();
  final secureStorage = SecureStorageService();

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider(storageService)),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => SecurityProvider(secureStorage)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final security = context.read<SecurityProvider>();
    if (state == AppLifecycleState.paused) {
      security.lock();
    } else if (state == AppLifecycleState.resumed) {
      security.resumeLock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final isLocked = context.watch<SecurityProvider>().isLocked;

    return MaterialApp.router(
      title: 'Birr Track',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        if (isLocked) {
          return const AppLockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
