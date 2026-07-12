import 'package:kaminari/src/data/models/book.dart';

String buildDiscoveryAIPrompt(String miniTree) {
  return """
Analyze this minified DOM tree and identify the most likely CSS selectors for book metadata.
I will use these selectors to run querySelector or querySelectorAll.
Remember that url are most likely to be a tags.
Tree: $miniTree

Return ONLY a single JSON object for the following schema:
${BookDetailsExtractor.schema}
${ChapterInfoExtractor.schema}

JSON:
""";
}

String buildChapterExtractionAIPrompt(String miniTree) {
  return """
Analyze this minified DOM tree and identify the most likely CSS selectors in proper format for the chapter's content.

Tree: $miniTree

Return ONLY a single JSON object for the following schema:
${ChapterExtractor.schema}

JSON:
""";
}

String cheaptersLoadingIIFE(
  ChapterInfoExtractor detailsSelector,
  String nextPageSelector,
) {
  return """
  (async () => {
    console.log("[JS-Extractor] Initializing chapter extraction...");
    let chapters = [];
    let i = -1;
    let nextUrl = document.location.href;
    
    while (nextUrl) {
      console.log("[JS-Extractor] Processing URL: " + nextUrl);
      let doc;
      
      if (i === -1) {
        console.log("[JS-Extractor] Using initial document DOM.");
        doc = document;
      } else {
        try {
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
          break;
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
      
      let currentUrl = nextUrl;
      nextUrl = null;
      
      try {
        // Look for the next button in 'doc' (the current page context)
        const nextBtn = doc.querySelector('$nextPageSelector');
        if (nextBtn && nextBtn.href && nextBtn.href !== currentUrl) {
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
    return chapters;
  })()
""";
}

const minTreeExtFn = '''
(function getTokenOptimizedTree() {
    // 1. Identify hidden elements from the live DOM before cloning
    const hiddenElements = new Set();
    document.body.querySelectorAll('*').forEach(el => {
        if (window.getComputedStyle(el).display === 'none') {
            hiddenElements.add(el);
        }
    });

    // 2. Clone the body structure
    const element = document.body.cloneNode(true);
    
    // Noise keyword matching regex
    const noiseClassRegex = /(comment|ad|share|social|promo|sponsor|related|sidebar|recommend|sns|bookmark|announce|announcement|impression|reaction|feedback)s?(_|-|([A-Z]))?/i;

    // 3. Map cloned elements back to their original state to check visibility and filters
    const allCloned = element.querySelectorAll('*');
    const allOriginal = document.body.querySelectorAll('*');

    allCloned.forEach((el, index) => {
        const originalEl = allOriginal[index];
        const tagName = el.tagName.toLowerCase();
        const noiseTags = ['script', 'style', 'footer', 'nav', 'header'];
        
        // Remove structural noise tags
        if (noiseTags.includes(tagName)) {
            el.remove();
            return;
        }

        // Remove elements hidden with display: none
        if (originalEl && hiddenElements.has(originalEl)) {
            el.remove();
            return;
        }

        // Remove elements matching class regex patterns
        const matchesNoiseClass = Array.from(el.classList).some(cls => noiseClassRegex.test(cls));
        if (matchesNoiseClass) {
            el.remove();
        }
    });

    element.querySelectorAll('[id^="L"]').forEach(el => {
      if (/^L\\d+\$/.test(el.id)) {
        el.removeAttribute('id');
      }
    });
    function serialize(el) {
        let label = el.tagName.toLowerCase();
        if (el.id) label += `#\${el.id}`;
        if (el.classList.length > 0) {
            label += `.\${el.classList}`;
        }
        return { label, children: Array.from(el.children).map(serialize) };
    }

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

    const root = serialize(element);
    const result = `\${root.label}[\${stringify(root)}]`;
    
    return result;
})()



''';

String generateBookExtrationJSPrompt(Map reMap, String iIFE) =>
    """
    (async () => {
      try {
        const data = $reMap;
        data.chapters = await $iIFE;
        ExtractionChannel.postMessage(JSON.stringify(data));
      } catch (e) {
        ExtractionChannel.postMessage(JSON.stringify({ "error": e.toString() }));
      }
    })()
  """;

String generateContentExtractionJSPrompt(String urls, String selector) =>
    """
      (async () => {
        try {
          const urls = $urls;
          const selector = $selector;
          const results = [];
          for (const url of urls) {
            const res = await fetch(url);
            const html = await res.text();
            const doc = new DOMParser().parseFromString(html, 'text/html');
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
              }
              
              if (lines.length === 0 && el.textContent.trim().length > 0) {
                lines.push(el.textContent.trim());
              }
            }
            results.push(lines);
          }
          ExtractionChannel.postMessage(JSON.stringify({ "contents": results }));
        } catch (e) {
          ExtractionChannel.postMessage(JSON.stringify({ "error": e.toString() }));
        }
      })()
    """;
