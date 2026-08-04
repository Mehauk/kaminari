import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';

class AppSettings {
  final LocalStorageService _storage;

  AppSettings(this._storage);

  static const _dictOrientationKey = 'pref_dict_orientation';
  static const _kanjiAlignmentKey = 'pref_kanji_alignment';
  static const _downloadOverMobileKey = 'pref_download_over_mobile';
  static const _darkReaderKey = 'pref_dark_reader';

  DictOrientation getDictOrientation() {
    final val = _storage.getData(_dictOrientationKey);
    return DictOrientation.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DictOrientation.dynamic,
    );
  }

  Future<void> setDictOrientation(DictOrientation orientation) async {
    await _storage.saveData(_dictOrientationKey, orientation.name);
  }

  KanjiAlignment getKanjiAlignment() {
    final val = _storage.getData(_kanjiAlignmentKey);
    return KanjiAlignment.values.firstWhere(
      (e) => e.name == val,
      orElse: () => KanjiAlignment.left,
    );
  }

  Future<void> setKanjiAlignment(KanjiAlignment alignment) async {
    await _storage.saveData(_kanjiAlignmentKey, alignment.name);
  }

  bool getDownloadOverMobile() {
    return _storage.getData(_downloadOverMobileKey) == true;
  }

  Future<void> setDownloadOverMobile(bool value) async {
    await _storage.saveData(_downloadOverMobileKey, value);
  }

  bool getDarkReader() {
    final val = _storage.getData(_darkReaderKey);
    return val == null ? true : val == true;
  }

  Future<void> setDarkReader(bool value) async {
    await _storage.saveData(_darkReaderKey, value);
  }
}
