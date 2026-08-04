import 'dart:convert';
import 'dart:io';

import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WebviewAssetsService {
  static final WebviewAssetsService _instance =
      WebviewAssetsService._internal();
  factory WebviewAssetsService() => _instance;
  WebviewAssetsService._internal();

  static const String _darkReaderUrl =
      'https://cdn.jsdelivr.net/npm/darkreader@4.9.109/darkreader.min.js';
  static const String _adblockUrl =
      'https://v.firebog.net/hosts/AdguardDNS.txt';

  // Incrementing this triggers a silent local file purge and fresh download
  static const int _currentAssetsVersion = 2;
  static const String _versionKey = 'pref_webview_assets_version';

  bool _isInitialized = false;
  List<String> _cachedAdblockDomains = [];
  String? _cachedDarkReaderScript;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Programmatically check if we need to migrate/force-upgrade the cache
    await _migrateOutdatedCache();

    // Load local cache into memory
    await _loadLocalCache();

    // Download fresh assets if missing
    _downloadAssetsSilently();
  }

  Future<void> _migrateOutdatedCache() async {
    try {
      final storage = LocalStorageService();
      final localVersion = storage.getData(_versionKey) as int? ?? 1;

      if (localVersion < _currentAssetsVersion) {
        print(
          '[WebviewAssetsService] Outdated cache version ($localVersion). Purging old files...',
        );

        final appDir = await getApplicationDocumentsDirectory();
        final assetsDir = Directory(p.join(appDir.path, 'webview_assets'));

        if (await assetsDir.exists()) {
          await assetsDir.delete(recursive: true);
        }

        // Save the new version number
        await storage.saveData(_versionKey, _currentAssetsVersion);
        print(
          '[WebviewAssetsService] Purge complete. Cache marked for update.',
        );
      }
    } catch (e) {
      print('[WebviewAssetsService] Cache migration failed: $e');
    }
  }

  Future<void> _loadLocalCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(p.join(appDir.path, 'webview_assets'));
      if (!await assetsDir.exists()) return;

      final darkReaderFile = File(p.join(assetsDir.path, 'darkreader.min.js'));
      final adblockFile = File(p.join(assetsDir.path, 'adblock_domains.txt'));

      if (await darkReaderFile.exists()) {
        _cachedDarkReaderScript = await darkReaderFile.readAsString();
      }

      if (await adblockFile.exists()) {
        final content = await adblockFile.readAsString();
        _cachedAdblockDomains = _parseDomains(content);
      }
    } catch (e) {
      print('[WebviewAssetsService] Error loading local webview cache: $e');
    }
  }

  List<String> _parseDomains(String content) {
    return content
        .split('\n')
        .map((e) {
          var line = e.trim();
          // Strip loopback/null routing prefixes if present in host lists
          if (line.startsWith('0.0.0.0 ')) {
            line = line.substring(8).trim();
          } else if (line.startsWith('127.0.0.1 ')) {
            line = line.substring(10).trim();
          }
          // Remove comments
          final commentIdx = line.indexOf('#');
          if (commentIdx != -1) {
            line = line.substring(0, commentIdx).trim();
          }
          return line;
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _downloadAssetsSilently() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory(p.join(appDir.path, 'webview_assets'));
      if (!await assetsDir.exists()) {
        await assetsDir.create(recursive: true);
      }

      final darkReaderFile = File(p.join(assetsDir.path, 'darkreader.min.js'));
      final adblockFile = File(p.join(assetsDir.path, 'adblock_domains.txt'));

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      if (!await darkReaderFile.exists()) {
        print('[WebviewAssetsService] Fetching DarkReader from CDN...');
        final request = await client.getUrl(Uri.parse(_darkReaderUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final content = await response.transform(utf8.decoder).join();
          await darkReaderFile.writeAsString(content);
          _cachedDarkReaderScript = content;
          print('[WebviewAssetsService] Cached DarkReader locally.');
        }
      }

      if (!await adblockFile.exists()) {
        print(
          '[WebviewAssetsService] Fetching Adblock Domain list from CDN...',
        );
        final request = await client.getUrl(Uri.parse(_adblockUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final content = await response.transform(utf8.decoder).join();
          await adblockFile.writeAsString(content);
          _cachedAdblockDomains = _parseDomains(content);
          print('[WebviewAssetsService] Cached Adblock domain list locally.');
        }
      }
    } catch (e) {
      print('[WebviewAssetsService] Silent asset caching failed: $e');
    }
  }

  Future<String?> getDarkReaderScript() async {
    if (_cachedDarkReaderScript != null) return _cachedDarkReaderScript;
    await _loadLocalCache();
    return _cachedDarkReaderScript;
  }

  Future<List<String>> getAdblockDomains() async {
    if (_cachedAdblockDomains.isNotEmpty) return _cachedAdblockDomains;
    await _loadLocalCache();
    return _cachedAdblockDomains;
  }
}
