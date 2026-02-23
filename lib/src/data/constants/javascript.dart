import 'package:kaminari/src/data/models/book.dart';

String buildDiscoveryPrompt(String miniTree) {
  return """
Analyze this minified DOM tree and identify the most likely CSS selectors for book metadata.
I will use these selectors to run querySelector qrquerySelectorAll.
Remember that url are most likely to be a tags.
Tree: $miniTree

Return ONLY a single JSON object for the following schema:
${BookDetailsExtractor.schema}
${ChapterInfoExtractor.schema}

JSON:
""";
}

String cheaptersLoadingIIFE(
  String chapterSelector,
  ChapterInfoExtractor detailsSelector,
  String firstPageSelector,
  String nextPageSelector,
) {
  return """
  (async () => {
    let chapters = [];
    let i = -1;
    let nextUrl = document.querySelector('$firstPageSelector').href ?? document.location.href;
    while (nextUrl) {
      const html = await (await fetch(nextUrl)).text();
      const doc = new DOMParser().parseFromString(html, 'text/html');
      const pageChapters = Array.from(doc.querySelectorAll('$chapterSelector')).map(e => {
      i += 1;
      return ({
        url: e.querySelector('${detailsSelector.url}')?.href,
        title: e.querySelector('${detailsSelector.title}')?.textContent.trim(),
        updatedDate: e.querySelector('${detailsSelector.updatedDate}')?.textContent.trim(),
        number: i
      })});
      chapters = chapters.concat(pageChapters);
      const nextBtn = doc.querySelector('$nextPageSelector');
      nextUrl = (nextBtn && nextBtn.href !== document.location.href) ? nextBtn.href : null;
    }
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
