import 'dart:convert';

import 'package:kaminari/src/data/repositories/app_settings.dart';
import 'package:kaminari/src/data/services/webview_assets_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewExtensionService {
  final AppSettings _settings;

  WebviewExtensionService(this._settings);

  /// Injects a high-priority early CSS stylesheet to prevent white flashes while loading.
  Future<void> applyEarlyDarkStyle(WebViewController controller) async {
    if (!_settings.getDarkReader()) return;
    try {
      const earlyDarkScript = r'''
        (function() {
          if (document.getElementById('kaminari-early-dark-style')) return;
          const style = document.createElement('style');
          style.id = 'kaminari-early-dark-style';
          style.textContent = 'html, body { background-color: #15130B !important; color: #E8E2D4 !important; }';
          if (document.documentElement) {
            document.documentElement.appendChild(style);
          } else {
            document.addEventListener('DOMContentLoaded', () => {
              document.documentElement.appendChild(style);
            });
          }
        })();
      ''';
      await controller.runJavaScript(earlyDarkScript);
    } catch (e) {
      print('[WebviewExtensionService] Failed to inject early dark style: $e');
    }
  }

  /// Builds the ad-blocking script using cached domains if available, with a fallback.
  Future<String> buildAdblockScript() async {
    final domains = await WebviewAssetsService().getAdblockDomains();

    if (domains.isEmpty) {
      return _fallbackAdblockScript;
    }

    final domainsJson = jsonEncode(domains);

    return '''
      (function() {
        if (window.__kaminariAdblockInstalled) return;
        window.__kaminariAdblockInstalled = true;
        console.log('[Kaminari-Adblock] Extension initializing with cached CDN host list...');

        const blockedDomains = new Set($domainsJson);

        function shouldBlock(url) {
          if (!url) return false;
          try {
            const parsedUrl = new URL(url, window.location.href);
            const host = parsedUrl.hostname.toLowerCase();
            
            let domain = host;
            while (domain) {
              if (blockedDomains.has(domain)) {
                console.log('[Kaminari-Adblock] Blocked network request to:', url);
                return true;
              }
              const parts = domain.split('.');
              if (parts.length <= 2) break;
              domain = parts.slice(1).join('.');
            }
          } catch (e) {}
          return false;
        }

        // 1. Intercept standard fetch API calls
        const originalFetch = window.fetch;
        window.fetch = function(...args) {
          const url = args[0];
          if (typeof url === 'string' && shouldBlock(url)) {
            return Promise.reject(new TypeError('Adblocked request'));
          }
          if (url instanceof Request && shouldBlock(url.url)) {
            return Promise.reject(new TypeError('Adblocked request'));
          }
          return originalFetch.apply(this, args);
        };

        // 2. Intercept standard legacy XMLHttpRequest calls
        const originalXHR = window.XMLHttpRequest.prototype.open;
        window.XMLHttpRequest.prototype.open = function(method, url, ...args) {
          if (shouldBlock(url)) {
            this.open = function() {}; 
            this.send = function() {}; 
            return;
          }
          return originalXHR.call(this, method, url, ...args);
        };

        // 3. Intercept document.createElement script/iframe/image injections
        const originalCreateElement = document.createElement;
        document.createElement = function(tagName, ...args) {
          const el = originalCreateElement.call(this, tagName, ...args);
          const tag = tagName.toLowerCase();
          
          if (tag === 'script' || tag === 'iframe' || tag === 'img') {
            const prototypeObj = tag === 'img' 
                ? HTMLImageElement.prototype 
                : (tag === 'script' ? HTMLScriptElement.prototype : HTMLIFrameElement.prototype);
            const setter = Object.getOwnPropertyDescriptor(prototypeObj, 'src');
            if (setter) {
              Object.defineProperty(el, 'src', {
                set: function(val) {
                  if (shouldBlock(val)) {
                    console.log('[Kaminari-Adblock] Blocked dynamic element src:', val);
                    setter.set.call(el, 'about:blank');
                  } else {
                    setter.set.call(el, val);
                  }
                },
                get: setter.get,
                configurable: true
              });
            }
          }
          return el;
        };

        // 4. Inject standard element-hiding CSS definitions (Expanded)
        const style = document.createElement('style');
        style.id = 'kaminari-adblock-styles';
        style.textContent = `
          [id*="google_ads"], [class*="google_ads"], [id*="ad_wrapper"], [class*="ad_wrapper"],
          [class*="ad-banner"], [class*="ad_banner"], [id*="ad-banner"], [id*="ad_banner"],
          [class*="-ad-"], [class*="_ad_"], [class*="adsby"], [id*="adsby"],
          .ads, .ad-box, .advertisement, .ad-placement, .ad_container, .ad-header, .sponsored-post,
          iframe[src*="ads"], iframe[src*="doubleclick"], iframe[src*="googleads"],
          div[class*="ad-placement"], div[class*="sponsors"], div[class*="ad-banner"],
          .floating-ad, .popup-ad, .interstitial-ad, .bottom-ad, .top-ad-banner,
          [class*="sticky-ad"], [id*="sticky-ad"] {
            display: none !important;
            visibility: hidden !important;
            height: 0 !important;
            width: 0 !important;
            opacity: 0 !important;
            pointer-events: none !important;
          }
        `;
        document.documentElement.appendChild(style);

        // 5. Setup live DOM scrub cycles via MutationObserver to prevent ad/script/iframe spawning
        const adSelectors = [
          'iframe[src*="doubleclick"]', 'iframe[src*="googleads"]', 'iframe[id*="google_ads"]',
          'div[class*="adsbygoogle"]', 'ins.adsbygoogle', 'div[id*="google_ads"]',
          'div[class*="ad-box"]', 'div[class*="advertisement"]'
        ];

        function cleanAds() {
          adSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => {
              el.remove();
            });
          });
        }

        cleanAds();
        const observer = new MutationObserver(mutations => {
          for (const mutation of mutations) {
            for (const node of mutation.addedNodes) {
              if (node.nodeType === Node.ELEMENT_NODE) {
                const tag = node.tagName.toLowerCase();
                
                // Block matching scripts/iframes/images added dynamically
                if (tag === 'script' || tag === 'iframe' || tag === 'img') {
                  const src = node.src || node.getAttribute('src');
                  if (shouldBlock(src)) {
                    console.log('[Kaminari-Adblock] Observer blocked node with src:', src);
                    node.remove();
                    continue;
                  }
                }

                // Block matching children added dynamically
                node.querySelectorAll?.('script, iframe, img').forEach(el => {
                  const src = el.src || el.getAttribute('src');
                  if (shouldBlock(src)) {
                    console.log('[Kaminari-Adblock] Observer blocked nested node with src:', src);
                    el.remove();
                  }
                });

                // Clear inline script text for tracker libraries
                if (tag === 'script') {
                  const text = node.textContent || node.text || '';
                  if (text.includes('adsbygoogle') || text.includes('amazon-adsystem') || text.includes('googlesyndication')) {
                    console.log('[Kaminari-Adblock] Nullified inline tracking script.');
                    node.textContent = '';
                  }
                }
              }
            }
          }
          cleanAds();
        });
        observer.observe(document.documentElement, { childList: true, subtree: true });
      })();
    ''';
  }

  /// Builds the DarkReader enabling script utilizing cached DarkReader if available.
  Future<String> buildDarkReaderScript() async {
    final darkReaderCode = await WebviewAssetsService().getDarkReaderScript();

    if (darkReaderCode == null) {
      return _fallbackDarkReaderScript;
    }

    return '''
      (function() {
        if (window.DarkReader) {
          console.log('[Kaminari-DarkReader] DarkReader library already loaded. Enabling...');
          DarkReader.setFetchMethod(window.fetch);
          DarkReader.enable({ brightness: 100, contrast: 90, sepia: 10 });
          return;
        }
        
        console.log('[Kaminari-DarkReader] Loading cached CDN DarkReader library...');
        try {
          $darkReaderCode
          DarkReader.setFetchMethod(window.fetch);
          DarkReader.enable({ brightness: 100, contrast: 90, sepia: 10 });
        } catch (e) {
          console.error('[Kaminari-DarkReader] Error executing DarkReader script:', e);
        }
      })();
    ''';
  }

  /// Builds the DarkReader disabling script utilizing cached DarkReader if available.
  Future<String> buildRemoveDarkReaderScript() async {
    final darkReaderCode = await WebviewAssetsService().getDarkReaderScript();
    if (darkReaderCode == null) {
      return _fallbackRemoveDarkReaderScript;
    }
    return '''
      (function() {
        if (window.DarkReader) {
          console.log('[Kaminari-DarkReader] Disabling DarkReader library...');
          DarkReader.disable();
        }
      })();
    ''';
  }

  /// Evaluates preference configs and applies extensions dynamically
  Future<void> applyExtensions(WebViewController controller) async {
    try {
      // 1. Run Adblock (always enabled)
      final adblock = await buildAdblockScript();
      await controller.runJavaScript(adblock);

      // 2. Evaluate DarkReader toggle state
      if (_settings.getDarkReader()) {
        final darkReader = await buildDarkReaderScript();
        await controller.runJavaScript(darkReader);
      } else {
        final removeDarkReader = await buildRemoveDarkReaderScript();
        await controller.runJavaScript(removeDarkReader);
      }
    } catch (e) {
      print('[WebviewExtensionService] Extension run failed: $e');
    }
  }

  /// Fallback scripts when local files are not downloaded yet
  String get _fallbackAdblockScript => r'''
    (function() {
      if (window.__kaminariAdblockInstalled) return;
      window.__kaminariAdblockInstalled = true;
      console.log('[Kaminari-Adblock] Extension initializing with fallback patterns...');

      const adBlockPatterns = [
        'doubleclick.net', 'googleads', 'googlesyndication', 'pagead', 'adservice',
        'analytics.google.com', 'adnxs', 'amazon-adsystem', 'criteo.com', 'pubmatic.com',
        'rubiconproject.com', 'popads', 'popunder', 'trafficjunky', 'ad-score', 'exoclick',
        'mgid.com', 'outbrain', 'taboola', 'adcolony', 'applovin', 'unityads'
      ];

      function shouldBlock(url) {
        if (!url) return false;
        const urlStr = String(url).toLowerCase();
        return adBlockPatterns.some(pattern => urlStr.includes(pattern));
      }

      // 1. Intercept standard fetch API calls
      const originalFetch = window.fetch;
      window.fetch = function(...args) {
        const url = args[0];
        if (typeof url === 'string' && shouldBlock(url)) {
          return Promise.reject(new TypeError('Adblocked request'));
        }
        if (url instanceof Request && shouldBlock(url.url)) {
          return Promise.reject(new TypeError('Adblocked request'));
        }
        return originalFetch.apply(this, args);
      };

      // 2. Intercept standard legacy XMLHttpRequest calls
      const originalXHR = window.XMLHttpRequest.prototype.open;
      window.XMLHttpRequest.prototype.open = function(method, url, ...args) {
        if (shouldBlock(url)) {
          this.open = function() {}; 
          this.send = function() {}; 
          return;
        }
        return originalXHR.call(this, method, url, ...args);
      };

      // 3. Intercept document.createElement script/iframe/image injections
      const originalCreateElement = document.createElement;
      document.createElement = function(tagName, ...args) {
        const el = originalCreateElement.call(this, tagName, ...args);
        const tag = tagName.toLowerCase();
        
        if (tag === 'script' || tag === 'iframe' || tag === 'img') {
          const prototypeObj = tag === 'img' 
              ? HTMLImageElement.prototype 
              : (tag === 'script' ? HTMLScriptElement.prototype : HTMLIFrameElement.prototype);
          const setter = Object.getOwnPropertyDescriptor(prototypeObj, 'src');
          if (setter) {
            Object.defineProperty(el, 'src', {
              set: function(val) {
                if (shouldBlock(val)) {
                  console.log('[Kaminari-Adblock] Blocked element src:', val);
                  setter.set.call(el, 'about:blank');
                } else {
                  setter.set.call(el, val);
                }
              },
              get: setter.get,
              configurable: true
            });
          }
        }
        return el;
      };

      // 4. Inject standard element-hiding CSS definitions
      const style = document.createElement('style');
      style.id = 'kaminari-adblock-styles';
      style.textContent = `
        [id*="google_ads"], [class*="google_ads"], [id*="ad_wrapper"], [class*="ad_wrapper"],
        [class*="ad-banner"], [class*="ad_banner"], [id*="ad-banner"], [id*="ad_banner"],
        [class*="-ad-"], [class*="_ad_"], [class*="adsby"], [id*="adsby"],
        .ads, .ad-box, .advertisement, .ad-placement, .ad_container, .ad-header,
        iframe[src*="ads"], iframe[src*="doubleclick"] {
          display: none !important;
          visibility: hidden !important;
          height: 0 !important;
          width: 0 !important;
          opacity: 0 !important;
          pointer-events: none !important;
        }
      `;
      document.documentElement.appendChild(style);

      // 5. Setup live DOM scrub cycles via MutationObserver
      const adSelectors = [
        'iframe[src*="doubleclick"]', 'iframe[src*="googleads"]', 'iframe[id*="google_ads"]',
        'div[class*="adsbygoogle"]', 'ins.adsbygoogle', 'div[id*="google_ads"]',
        'div[class*="ad-box"]', 'div[class*="advertisement"]'
      ];

      function cleanAds() {
        adSelectors.forEach(selector => {
          document.querySelectorAll(selector).forEach(el => {
            el.remove();
          });
        });
      }

      cleanAds();
      const observer = new MutationObserver(cleanAds);
      observer.observe(document.documentElement, { childList: true, subtree: true });
    })();
  ''';

  String get _fallbackDarkReaderScript => r'''
    (function() {
      console.log('[Kaminari-DarkReader] Applying fallback invert darkening...');
      let style = document.getElementById('kaminari-darkreader-styles');
      if (!style) {
        style = document.createElement('style');
        style.id = 'kaminari-darkreader-styles';
        document.documentElement.appendChild(style);
      }
      
      style.textContent = `
        html {
          background-color: #121212 !important;
          filter: invert(0.92) contrast(0.95) hue-rotate(180deg) !important;
        }
        body {
          background-color: #121212 !important;
        }
        img, video, canvas, svg, iframe, [style*="background-image"], .kaminari-word-highlight {
          filter: invert(1) hue-rotate(180deg) !important;
        }
        ::-webkit-scrollbar {
          background-color: #1a1a1a !important;
          color: #888 !important;
        }
        ::-webkit-scrollbar-thumb {
          background-color: #333 !important;
        }
      `;
    })();
  ''';

  String get _fallbackRemoveDarkReaderScript => r'''
    (function() {
      console.log('[Kaminari-DarkReader] Disabling fallback invert darkening...');
      const style = document.getElementById('kaminari-darkreader-styles');
      if (style) {
        style.remove();
      }
    })();
  ''';
}
