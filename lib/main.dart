import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:device_preview/device_preview.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/database/database.dart';
import 'package:lunasea/router/router.dart';
import 'package:lunasea/system/cache/image/image_cache.dart';
import 'package:lunasea/system/cache/memory/memory_store.dart';
import 'package:lunasea/system/network/network.dart';
import 'package:lunasea/system/recovery_mode/main.dart';
import 'package:lunasea/system/window_manager/window_manager.dart';
import 'package:lunasea/system/platform.dart';

/// LunaSea Entry Point: Bootstrap & Run Application
///
/// Runs app in guarded zone to attempt to capture fatal (crashing) errors
Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await bootstrap();
        runApp(const LunaBIOS());
      } catch (error) {
        runApp(const LunaRecoveryMode());
      }
    },
    (error, stack) => LunaLogger().critical(error, stack),
  );
}

/// Bootstrap the core
///
Future<void> bootstrap() async {
  await LunaDatabase().initialize();
  LunaLogger().initialize();
  LunaTheme().initialize();
  if (LunaWindowManager.isSupported) await LunaWindowManager().initialize();
  if (LunaNetwork.isSupported) LunaNetwork().initialize();
  if (LunaImageCache.isSupported) LunaImageCache().initialize();
  LunaRouter().initialize();
  await LunaMemoryStore().initialize();
}

class LunaBIOS extends StatelessWidget {
  const LunaBIOS({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LunaTheme();
    final router = LunaRouter.router;

    return LunaState.providers(
      child: DevicePreview(
        enabled: kDebugMode && LunaPlatform.isDesktop,
        builder: (context) => EasyLocalization(
          supportedLocales: [Locale('en')],
          path: 'assets/localization',
          fallbackLocale: Locale('en'),
          startLocale: Locale('en'),
          useFallbackTranslations: true,
          child: LunaBox.lunasea.listenableBuilder(
            selectItems: [
              LunaSeaDatabase.THEME_AMOLED,
              LunaSeaDatabase.THEME_AMOLED_BORDER,
            ],
            builder: (context, _) {
              return MaterialApp.router(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: DevicePreview.appBuilder,
                darkTheme: theme.activeTheme(),
                theme: theme.activeTheme(),
                title: 'LunaSea',
                routeInformationProvider: router.routeInformationProvider,
                routeInformationParser: router.routeInformationParser,
                routerDelegate: router.routerDelegate,
              );
            },
          ),
        ),
      ),
    );
  }
}
