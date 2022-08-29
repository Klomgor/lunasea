import 'package:lunasea/database/box.dart';
import 'package:lunasea/database/models/profile.dart';
import 'package:lunasea/database/table.dart';
import 'package:lunasea/database/tables/bios.dart';
import 'package:lunasea/database/tables/lunasea.dart';
import 'package:lunasea/system/filesystem/filesystem.dart';
import 'package:lunasea/system/logger.dart';
import 'package:lunasea/system/platform.dart';
import 'package:lunasea/vendor.dart';

class LunaDatabase {
  static const String _DATABASE_LEGACY_PATH = 'database';
  static const String _DATABASE_PATH = 'LunaSea/database';

  String get path {
    if (LunaPlatform.isWindows || LunaPlatform.isLinux) return _DATABASE_PATH;
    return _DATABASE_LEGACY_PATH;
  }

  Future<void> initialize() async {
    await Hive.initFlutter(path);
    LunaTable.register();
    await open();
  }

  Future<void> open() async {
    try {
      await LunaBox.open();
      if (LunaBox.profiles.isEmpty) await bootstrap();
    } catch (error, stack) {
      await nuke();
      await LunaBox.open();
      await bootstrap(databaseCorruption: true);

      LunaLogger().error(
        'Database corruption detected',
        error,
        stack,
      );
    }
  }

  Future<void> nuke() async {
    await Hive.close();

    for (final box in LunaBox.values) {
      await Hive.deleteBoxFromDisk(box.key, path: path);
    }

    if (LunaFileSystem.isSupported) {
      await LunaFileSystem().nuke();
    }
  }

  Future<void> bootstrap({
    bool databaseCorruption = false,
  }) async {
    const defaultProfile = LunaProfile.DEFAULT_PROFILE;
    await clear();

    LunaBox.profiles.update(defaultProfile, LunaProfile());
    LunaSeaDatabase.ENABLED_PROFILE.update(defaultProfile);
    BIOSDatabase.DATABASE_CORRUPTION.update(databaseCorruption);
  }

  Future<void> clear() async {
    for (final box in LunaBox.values) await box.clear();
  }

  Future<void> deinitialize() async {
    await Hive.close();
  }
}
