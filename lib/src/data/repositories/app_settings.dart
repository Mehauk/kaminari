// lib/src/data/repositories/app_settings.dart
import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';

class AppSettings {
  final LocalStorageService _storage;

  AppSettings(this._storage);

  static const _dictOrientationKey = 'pref_dict_orientation';

  DictOrientation getDictOrientation() {
    final val = _storage.getData(_dictOrientationKey);
    // Default to bottom if not set
    return val == 'top' ? DictOrientation.top : DictOrientation.bottom;
  }

  Future<void> setDictOrientation(DictOrientation orientation) async {
    await _storage.saveData(_dictOrientationKey, orientation.name);
  }
}
