import 'package:kaminari/src/data/models/book.dart';

String buildDiscoveryAIPrompt(String miniTree) {
  return """
Analyze this minified DOM tree and identify the most likely CSS selectors for book metadata.
I will use these selectors to run querySelector or querySelectorAll in a browser context.

Guidelines:
1. `individualChapterDetails.base` must select the individual chapter rows or container elements (e.g., `li` or chapter wrapper divs), NOT the parent container (like the entire `ul` or list wrapper `div`).
2. You MUST identify the `nextPageUrl` selector if there is pagination (e.g., next page buttons, page numbers, or dropdown select options). The selector must target the link to the *immediate next page* sequentially (e.g. page 2, then page 3). Do NOT target the "Last" page or "First" page links. If no pagination exists, return "N/A".
3. `coverUrl` must select the image tag or link containing the book cover image.

Tree: $miniTree

Return ONLY a single JSON object matching the schema.
${BookDetailsExtractor.schema}
${ChapterInfoExtractor.schema}

JSON:
""";
}

String buildChapterExtractionAIPrompt(String miniTree) {
  return """
Analyze this minified DOM tree and identify the most likely CSS selectors in proper format for the chapter's content. 
Ensure that no data is lost form choosing too narrow.
Ensure that nothing is added because you were not specigfic enough.

Tree: $miniTree

Return ONLY a single JSON object for the following schema:
${ChapterExtractor.schema}

JSON:
""";
}

String chaptersLoadingIIFE(
  ChapterInfoExtractor detailsSelector,
  String nextPageSelector,
  int startIndex,
) {
  return """
  (async () => {
    console.log("[JS-Extractor] Initializing chapter extraction starting at index $startIndex...");
    let chapters = [];
    let i = $startIndex - 1;
    let nextUrl = document.location.href;
    let lastSuccessfulUrl = nextUrl;
    let pagesParsed = 0;
    
    while (nextUrl) {
      console.log("[JS-Extractor] Processing URL: " + nextUrl);
      let doc;
      
      if (i === $startIndex - 1) {
        console.log("[JS-Extractor] Using initial document DOM.");
        doc = document;
      } else {
        try {
          // Non-blocking pacing delay to mitigate rate limiting on remote fetches
          await new Promise(resolve => setTimeout(resolve, 300));

          const response = await fetch(nextUrl, {
            method: 'GET',
            credentials: 'include',
            headers: { 'Accept': 'text/html' },
          });
          
          if (!response.ok) throw new Error("HTTP Status " + response.status);
          
          let html = await response.text();
          doc = new DOMParser().parseFromString(html, 'text/html');
          console.log("[JS-Extractor] Successfully fetched and parsed remote page.");
        } catch (e) {
          console.error("[JS-Extractor] Fetch failed for: " + nextUrl, e);
          // Return what we successfully fetched along with the failed URL so Dart can continue via Webview navigation
          return {
            chapters: chapters,
            failedUrl: nextUrl,
            lastSuccessfulUrl: lastSuccessfulUrl,
            pagesParsed: pagesParsed
          };
        }
      }
      
      const elements = doc.querySelectorAll('${detailsSelector.base}');
      console.log("[JS-Extractor] Found " + elements.length + " chapter elements on page.");
      
      const pageChapters = Array.from(elements).map(e => {
        i += 1;
        return ({
          url: e.querySelector('${detailsSelector.url}')?.href,
          title: e.querySelector('${detailsSelector.title}')?.textContent.trim(),
          updatedDate: e.querySelector('${detailsSelector.updatedDate}')?.textContent.trim(),
          number: i
        })
      });
      
      chapters = chapters.concat(pageChapters);
      lastSuccessfulUrl = nextUrl;
      pagesParsed++;
      
      // Dispatch immediate chapter accumulation progress to the Dart UI context
      if (typeof ProgressChannel !== 'undefined') {
        ProgressChannel.postMessage(JSON.stringify({ "count": chapters.length }));
      }
      
      let currentUrl = nextUrl;
      nextUrl = null;
      
      try {
        // Look for the next button in 'doc' (the current page context)
        const nextBtn = doc.querySelector('$nextPageSelector');
        if (nextBtn && nextBtn.href && nextBtn.href !== currentUrl && nextBtn.href !== 'javascript:;') {
          nextUrl = nextBtn.href;
          console.log("[JS-Extractor] Next page found: " + nextUrl);
        } else {
          console.log("[JS-Extractor] No next page link detected. Finishing.");
        }
      } catch (e) {
        console.warn("[JS-Extractor] Error parsing next selector '$nextPageSelector':", e);
        nextUrl = null;
      }
    }
    
    console.log("[JS-Extractor] Extraction complete. Total chapters: " + chapters.length);
    return {
      chapters: chapters,
      failedUrl: null,
      lastSuccessfulUrl: lastSuccessfulUrl,
      pagesParsed: pagesParsed
    };
  })()
""";
}

const minTreeExtFn = '''
(function getTokenOptimizedTree() {
    // 1. Clone the body structure
    const clonedBody = document.body.cloneNode(true);

    // 2. Parallel DFS Tree Traversal to map clones directly to their original live nodes
    function mapParallelTrees(orig, clone) {
        if (!orig || !clone) return;
        clone._original = orig;
        
        const origChildren = Array.from(orig.children);
        const cloneChildren = Array.from(clone.children);
        const minLength = Math.min(origChildren.length, cloneChildren.length);
        
        for (let i = 0; i < minLength; i++) {
            mapParallelTrees(origChildren[i], cloneChildren[i]);
        }
    }
    mapParallelTrees(document.body, clonedBody);

    // Precise, word-boundary noise check to avoid false matches like "read" -> "ad"
    function isNoiseClassOrId(str) {
        if (!str) return false;
        const words = str.toLowerCase().split(/[-_]/);
        
        const noiseWords = new Set([
            'comment', 'comments', 'ad', 'ads', 'share', 'social', 'promo', 'sponsor', 'sponsored', 
            'related', 'sidebar', 'recommend', 'recommendation', 'sns', 'bookmark', 'announce', 
            'announcement', 'announcements', 'impression', 'reaction', 'feedback', 'cookie', 
            'cookies', 'consent', 'modal', 'popup', 'popups', 'banner', 'banners'
        ]);
        
        for (const word of words) {
            if (noiseWords.has(word)) return true;
            if (word.startsWith('advert')) return true;
        }
        return false;
    }

    const noiseTags = ['script', 'style', 'noscript', 'template', 'svg', 'iframe', 'canvas', 'footer', 'nav', 'header'];
    const contentTags = ['img', 'image', 'picture', 'video', 'audio'];

    // Standard Utility Class Checker (Tailwind, Bootstrap, etc.)
    function isUtilityClass(cls) {
        const exactUtilities = new Set([
            'flex', 'grid', 'block', 'inline', 'hidden', 'invisible', 'absolute', 'relative', 'fixed', 'sticky',
            'border', 'rounded', 'shadow', 'pointer', 'cursor-pointer', 'select-none', 'overflow-hidden', 'sr-only'
        ]);
        if (exactUtilities.has(cls)) return true;
        if (/:/.test(cls)) return true; // variant prefixes (e.g. md:, hover:)
        if (/d/.test(cls)) return true; // spacing/sizing classes with numbers (e.g. p-4, w-1/2, z-10)

        // Matches common Tailwind structural patterns with semantic utility suffixes
        const utilityPatterns = /^(p|m|pt|pb|pl|pr|mt|mb|ml|mr|w|h|min-w|max-w|min-h|max-h|gap|space|top|bottom|left|right|text|bg|border|rounded|font|leading|tracking|z|justify|items|align|self)-(auto|full|screen|white|black|transparent|center|left|right|justify|bold|semibold|normal)\$/;
        if (utilityPatterns.test(cls)) return true;

        return false;
    }

    // 3. Recursive bottom-up cleaner
    function cleanTree(el) {
        const children = Array.from(el.children);
        for (const child of children) {
            cleanTree(child);
        }

        if (el !== clonedBody) {
            const original = el._original;
            const tagName = el.tagName.toLowerCase();

            // A. Remove structural noise tags
            if (noiseTags.includes(tagName)) {
                el.remove();
                return;
            }

            // B. Remove hidden elements
            if (original) {
                const style = window.getComputedStyle(original);
                if (style.display === 'none' || style.visibility === 'hidden' || parseFloat(style.opacity) === 0) {
                    el.remove();
                    return;
                }
            }

            // C. Remove noise classes or IDs (utilizing precise boundary checker)
            const hasNoiseClassOrId = Array.from(el.classList).some(isNoiseClassOrId) || isNoiseClassOrId(el.id || '');
            if (hasNoiseClassOrId) {
                el.remove();
                return;
            }

            // D. Prune empty structural elements with no text, content, or ID
            const textSrc = original || el;
            const hasTextContent = textSrc.textContent.trim().length > 0;
            if (el.children.length === 0 && !contentTags.includes(tagName) && !hasTextContent && !el.id) {
                el.remove();
                return;
            }

            // E. Clean dynamic IDs
            if (el.id) {
                if (/^Ld+\$/.test(el.id) || /^[a-f0-9]{32,}\$/i.test(el.id)) {
                    el.removeAttribute('id');
                }
            }

            // F. Clean classes (only keep non-utility semantic classes)
            const meaningfulClasses = Array.from(el.classList).filter(cls => {
                if (isNoiseClassOrId(cls)) return false;
                if (isUtilityClass(cls)) return false;
                return true;
            });

            if (meaningfulClasses.length > 0) {
                el.className = meaningfulClasses.join(' ');
            } else {
                el.removeAttribute('class');
            }
        }
    }

    cleanTree(clonedBody);

    // 4. Serialize
    function serialize(el) {
        let label = el.tagName.toLowerCase();
        if (el.id) label += `#\${el.id}`;
        
        const classes = Array.from(el.classList).filter(c => c.trim().length > 0);
        if (classes.length > 0) {
            label += `.\${classes.join('.')}`;
        }
        return { label, children: Array.from(el.children).map(serialize) };
    }

    // 5. Build nested minified string
    function stringify(node) {
        const counts = new Map();
        const orderedKeys = [];

        for (const child of node.children) {
            const key = JSON.stringify(child);
            if (!counts.has(key)) {
                counts.set(key, { node: child, count: 0 });
                orderedKeys.push(key);
            }
            counts.get(key).count++;
        }

        return orderedKeys.map(key => {
            const entry = counts.get(key);
            let current = entry.node;
            let path = current.label;

            while (current.children.length === 1) {
                current = current.children[0];
                path += `>\${current.label}`;
            }

            const countStr = entry.count > 1 ? `*\${entry.count}` : "";
            
            if (current.children.length > 0) {
                return `\${path}\${countStr}[\${stringify(current)}]`;
            }
            return `\${path}\${countStr}`;
        }).join(',');
    }

    const root = serialize(clonedBody);
    const result = `\${root.label}[\${stringify(root)}]`;
    
    return result;
})()
''';

String generateBookExtrationJSPrompt(Map reMap, String iIFE) =>
    """
    (async () => {
      try {
        const data = $reMap;
        const result = await $iIFE;
        data.chapters = result.chapters;
        data.failedUrl = result.failedUrl;
        data.lastSuccessfulUrl = result.lastSuccessfulUrl;
        data.pagesParsed = result.pagesParsed;
        ExtractionChannel.postMessage(JSON.stringify(data));
      } catch (e) {
        ExtractionChannel.postMessage(JSON.stringify({ "error": e.toString() }));
      }
    })()
  """;

String generateContentExtractionJSPrompt(String selector) =>
    """
      (async () => {
        try {
          const selector = $selector;
          const results = [];
          
          const normUrl = (u) => {
            let s = u.toLowerCase().trim();
            if (s.endsWith("/")) s = s.slice(0, -1);
            return s;
          };

          let doc = document;
          
          const containers = Array.from(doc.querySelectorAll(selector));
          let lines = [];
          
          for (const el of containers) {
            const children = Array.from(el.children);
            if (children.length > 0) {
              const childrenLines = children
                .map(function(c) {
                  let text = c.textContent.trim();
                  if ((text?.length ?? 0) > 0) return text;
                  try {
                    return c.querySelector('img')?.src ?? "";
                  } catch {
                    return "";
                  }
                })
                .filter(t => t.length > 0);
              lines = lines.concat(childrenLines);
            } else {
              const text = el.textContent.trim();
              if (text.length > 0) {
                lines.push(text);
              }
            }
          }
          results.push(lines);
          ExtractionChannel.postMessage(JSON.stringify({ "contents": results }));
        } catch (e) {
          ExtractionChannel.postMessage(JSON.stringify({ "error": e.toString() }));
        }
      })()
    """;
