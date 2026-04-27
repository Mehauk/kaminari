import 'package:kaminari/src/data/services/local_storage_service.dart';

class ExtractorCache {
  final LocalStorageService _localStorage;

  const ExtractorCache(this._localStorage);

  static const _bookKey = "BOOK:::";
  static const _pageKey = "PAGE:::";

  Future<void> saveBookExtractorForOrigin(
    String origin,
    String extractor,
  ) async {
    await _localStorage.saveData("$_bookKey$origin", extractor);
  }

  Future<void> savePageExtractorForOrigin(
    String origin,
    String extractor,
  ) async {
    await _localStorage.saveData("$_pageKey$origin", extractor);
  }

  Future<String?> loadBookExtractorForOrigin(String origin) async {
    return await _localStorage.getData("$_bookKey$origin");
  }

  Future<String?> loadPageExtractorForOrigin(String origin) async {
    return await _localStorage.getData("$_pageKey$origin");
  }
}
