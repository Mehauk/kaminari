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

  Future<void> clearCacheForOrigin(String origin) async {
    print("[ExtractorCache] Attempting to clear cache for origin: '$origin'");
    final bookKey = "$_bookKey$origin";
    final pageKey = "$_pageKey$origin";

    print("[ExtractorCache] Looking for keys: '$bookKey' and '$pageKey'");
    print("[ExtractorCache] All storage keys: ${_localStorage.getAllKeys()}");

    final removed1 = await _localStorage.removeData(bookKey);
    final removed2 = await _localStorage.removeData(pageKey);

    print("[ExtractorCache] Removed book cache: $removed1");
    print("[ExtractorCache] Removed page cache: $removed2");
    print(
      "[ExtractorCache] Remaining keys after clear: ${_localStorage.getAllKeys()}",
    );
  }

  /// Get all cached extractors as a map of {origin: {type: extractor}}
  Map<String, Map<String, String>> getAllCachedExtractors() {
    final allKeys = _localStorage.getAllKeys();
    print(
      "[ExtractorCache] getAllCachedExtractors - Total keys in storage: ${allKeys.length}",
    );
    print("[ExtractorCache] All keys: $allKeys");

    final result = <String, Map<String, String>>{};

    for (final key in allKeys) {
      if (key.startsWith(_bookKey)) {
        final origin = key.substring(_bookKey.length);
        final extractor = _localStorage.getData(key);
        print("[ExtractorCache] Found book cache for origin: '$origin'");
        if (extractor != null) {
          result.putIfAbsent(origin, () => {})['book'] = extractor;
        }
      } else if (key.startsWith(_pageKey)) {
        final origin = key.substring(_pageKey.length);
        final extractor = _localStorage.getData(key);
        print("[ExtractorCache] Found page cache for origin: '$origin'");
        if (extractor != null) {
          result.putIfAbsent(origin, () => {})['page'] = extractor;
        }
      }
    }

    print("[ExtractorCache] Returning ${result.length} cached origins");
    return result;
  }
}
