import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/constants/ad_constants.dart';
import 'core/navigation/app_navigator.dart';
import 'core/services/ad_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/storage_service.dart';
import 'models/app_theme_preset.dart';
import 'core/turn/turn_engine.dart';
import 'providers/shop_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/turn_provider.dart';
import 'screens/home/settings_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/coin_reward_listener.dart';

late final ThemeProvider appThemeProvider;
late final ShopProvider appShopProvider;
late final TurnProvider appTurnProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await StorageService.instance.init();

  appThemeProvider = ThemeProvider();
  await appThemeProvider.init();

  appShopProvider = ShopProvider();
  await appShopProvider.init(remote: false);

  appTurnProvider = TurnProvider();
  await appTurnProvider.init();
  const demoIds = {'lunch', 'drive', 'meeting'};
  if (appTurnProvider.groups.any((group) => demoIds.contains(group.id))) {
    await appTurnProvider.adopt(
      TurnBook(
        groups: [
          for (final group in appTurnProvider.groups)
            if (!demoIds.contains(group.id)) group,
        ],
        assignments: [
          for (final item in appTurnProvider.history)
            if (!demoIds.contains(item.groupId)) item,
        ],
        absent: {
          for (final entry in appTurnProvider.absent.entries)
            if (!demoIds.contains(entry.key)) entry.key: entry.value.toList(),
        },
      ),
    );
  }

  runApp(const FairTurnApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(appShopProvider.connectRemote());
    if (AdConstants.isConfigured) unawaited(AdService.init());
  });
}

class FairTurnApp extends StatelessWidget {
  const FairTurnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appThemeProvider),
        ChangeNotifierProvider.value(value: appShopProvider),
        ChangeNotifierProvider.value(value: appTurnProvider),
      ],
      child: const _ThemedApp(),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<ThemeProvider, ThemeMode>((t) => t.themeMode);
    final themeId =
        context.select<ShopProvider, String>((s) => s.activeThemeId);
    final preset = AppThemePresets.get(themeId);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'FairTurn',
      debugShowCheckedModeBanner: false,
      theme: preset.lightTheme(),
      darkTheme: preset.darkTheme(),
      themeMode: themeMode,
      locale: const Locale('en'),
      builder: (context, child) =>
          CoinRewardListener(child: child ?? const SizedBox.shrink()),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: const SplashScreen(),
      routes: {
        '/shop': (_) => const ShopScreen(),
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
