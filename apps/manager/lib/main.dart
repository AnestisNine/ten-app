import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_store.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.loadPreferences();
  await AppStore.api.init();
  runApp(const TbnManagerApp());
}

/// Lets mouse / trackpad users drag-scroll like on touch screens.
class _TbnScrollBehavior extends MaterialScrollBehavior {
  const _TbnScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class TbnManagerApp extends StatelessWidget {
  const TbnManagerApp({super.key, this.home = const StartupScreen()});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppStore.locale,
      builder: (context, locale, _) => ValueListenableBuilder<AppThemeOption>(
        valueListenable: AppStore.themeOption,
        builder: (context, themeOption, _) {
          return MaterialApp(
            title: 'TBN Manager',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: AppStore.messengerKey,
            scrollBehavior: const _TbnScrollBehavior(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: themeOption == AppThemeOption.cream ? buildCreamTheme() : buildDarkTheme(),
            builder: (context, child) {
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: home,
          );
        },
      ),
    );
  }
}
