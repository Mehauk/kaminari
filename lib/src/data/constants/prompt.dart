import 'dart:convert';

import 'package:kaminari/src/data/models/book.dart';

String buildDiscoveryAIPrompt(
  String miniTree, {
  Map<String, String> avoidSelectors = const {},
}) {
  String avoid = '';
  if (avoidSelectors.isNotEmpty) {
    final buffer = StringBuffer(
      '\n6. PREVIOUSLY FAILED SELECTORS (DO NOT REUSE):',
    );
    avoidSelectors.forEach((field, selector) {
      buffer.write(
        '\n   - For "$field", do NOT use any "$selector" (they were tested and failed or produced incorrect results). Choose an alternative selector.',
      );
    });
    avoid = buffer.toString();
  }

  return """
Analyze this minified DOM tree and identify the most likely CSS selectors for book metadata.
I will use these selectors to run querySelector or querySelectorAll in a browser context.

Guidelines:
1. `individualChapterDetails.base` must select the individual chapter rows or container elements (e.g., `li` or chapter wrapper divs), NOT the parent container (like the entire `ul` or list wrapper `div`).
2. You MUST identify the `nextPageUrl` selector if there is pagination (e.g., next page buttons, page numbers, or dropdown select options). The selector must target the link to the *immediate next page* sequentially (e.g. page 2, then page 3). Do NOT target the "Last" page or "First" page links. If no pagination exists, return "N/A".
3. `coverUrl` must select the image tag or link containing the book cover image.
4. All selectors MUST be standard valid CSS selectors compatible with document.querySelector. Do NOT use non-standard jQuery pseudo-classes like :contains(), :eq(), :first, or :last. To target pagination links, use standard class, attribute, or structural selectors (e.g. `.pagination .next`, `a.next`, `div.page > a:last-of-type`, etc.).
5. The synopsis field is collected with querySelectorAll and ALL matched elements are joined together, so one selector must match every part of it. If the synopsis spans multiple sibling elements (e.g. several consecutive `<p>` tags), return a selector scoped to exactly those elements and nothing else (e.g. parent-scoped like `#content > p.summary`). Prefer a shared class or attribute over positional counting: `:nth-of-type(...)` counts per parent among siblings of the same tag, so it silently misses paragraphs when the parent mixes element types or the count is off — never use `:nth-of-type()` ranges to pick a subset of the synopsis. Make sure the matched elements contain ONLY synopsis text — never metadata labels, buttons, navigation or chapter lists.$avoid

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
Ensure that no data is lost from choosing too narrow.
Ensure that nothing is added because you were not specific enough.
Selectors MUST be standard valid CSS selectors suitable for document.querySelectorAll (do NOT use :contains or other jQuery pseudo-classes).

Tree: $miniTree

Return ONLY a single JSON object for the following schema:
${ChapterExtractor.schema}

JSON:
""";
}

/// Shared DOM helpers injected into every extraction script:
/// - safeQuery/safeQueryAll with a polyfill for :contains() and :has(),
///   which LLMs frequently emit but querySelectorAll does not support
/// - nested-match dedupe, lazy-load-aware cover URLs and deterministic
///   per-field salvage (og: meta, h1, paragraphs adjacent to the chapter
///   list) that only runs when selector-based extraction came up empty.
const jsExtractorHelpers = r'''
        function findTopLevel(s, token) {
          let depth = 0, inQuote = null;
          for (let i = 0; i < s.length; i++) {
            const c = s[i];
            if (inQuote) { if (c === inQuote) inQuote = null; continue; }
            if (c === '"' || c === "'") { inQuote = c; continue; }
            if (c === '(' || c === '[') depth++;
            else if (c === ')' || c === ']') depth--;
            else if (depth === 0 && s.startsWith(token, i)) return i;
          }
          return -1;
        }

        function matchParen(s, openIdx) {
          let depth = 0, inQuote = null;
          for (let i = openIdx; i < s.length; i++) {
            const c = s[i];
            if (inQuote) { if (c === inQuote) inQuote = null; continue; }
            if (c === '"' || c === "'") { inQuote = c; continue; }
            if (c === '(') depth++;
            else if (c === ')' && --depth === 0) return i;
          }
          return -1;
        }

        // Resolves CSS augmented with jQuery-style :contains(), e.g.
        // 'div:has(p:contains("Title:")) h2' which native querySelectorAll rejects.
        function queryAllPoly(root, sel) {
          let s = (sel || '').trim();
          if (!root || !s) return [];
          if (/^[>+~ ]/.test(s)) s = ':scope' + s;
          const hasIdx = findTopLevel(s, ':has(');
          if (hasIdx !== -1) {
            const open = hasIdx + 4;
            const close = matchParen(s, open);
            if (close === -1) return [];
            const base = (s.slice(0, hasIdx) || '*') + s.slice(close + 1);
            const inner = s.slice(open + 1, close);
            return queryAllPoly(root, base).filter(el => queryAllPoly(el, inner).length > 0);
          }
          const cIdx = findTopLevel(s, ':contains(');
          if (cIdx !== -1) {
            const open = cIdx + 10;
            const close = matchParen(s, open);
            if (close === -1) return [];
            const base = s.slice(0, cIdx) || '*';
            const tail = s.slice(close + 1).trim();
            let text = s.slice(open + 1, close).trim();
            if ((text.startsWith('"') && text.endsWith('"')) || (text.startsWith("'") && text.endsWith("'"))) {
              text = text.slice(1, -1);
            }
            const matched = queryAllPoly(root, base).filter(el =>
              el.textContent && el.textContent.toLowerCase().includes(text.toLowerCase()));
            if (!tail) return matched;
            let out = [];
            for (const el of matched) out = out.concat(queryAllPoly(el, tail));
            return out;
          }
          return Array.from(root.querySelectorAll(s));
        }

        function safeQueryAll(root, sel) {
          if (!root || !sel || typeof sel !== 'string') return [];
          const s = sel.trim();
          if (!s || s === 'null' || s.toLowerCase() === 'n/a' || s.toLowerCase() === 'none') return [];
          try {
            return queryAllPoly(root, s);
          } catch (e) {
            console.warn("[JS-Extractor] safeQueryAll error for " + s + ":", e);
            return [];
          }
        }

        function safeQuery(root, sel) {
          return safeQueryAll(root, sel)[0] || null;
        }

        // Drops elements nested inside another matched element so overlapping
        // selectors (e.g. 'p, p > em') don't duplicate content.
        function dedupeNested(elements) {
          const kept = [];
          for (const el of elements) {
            if (!kept.some(k => k !== el && k.contains(el))) kept.push(el);
          }
          return kept;
        }

        // Text of an element with the page's own machinery stripped out. An ad
        // slot or a style rule parked inside a story paragraph contributes its
        // source code as textContent, which reads as prose nobody wrote.
        function textOf(el) {
          if (!el) return '';
          if (!el.querySelector || !el.querySelector('script, style, noscript, template')) {
            return (el.textContent || '').trim();
          }
          const clone = el.cloneNode(true);
          for (const junk of Array.from(clone.querySelectorAll('script, style, noscript, template'))) {
            junk.remove();
          }
          return (clone.textContent || '').trim();
        }

        // Resolves the real image URL even when the site lazy-loads covers
        // (placeholder data: URIs in src, real URL in data-src/srcset variants).
        function pickCoverSrc(el) {
          if (!el) return '';
          const isUsable = u => typeof u === 'string' && u.trim().length > 0 && !/^data:/i.test(u.trim());
          const attr = el.getAttribute ? (el.getAttribute('data-src') || el.getAttribute('data-lazy-src') || el.getAttribute('data-original')) : null;
          if (isUsable(attr)) return attr.trim();
          const srcset = (el.getAttribute ? (el.getAttribute('data-srcset') || el.getAttribute('srcset')) : '') || '';
          if (srcset) {
            const urls = String(srcset).split(',').map(part => part.trim().split(/\s+/)[0]).filter(isUsable);
            if (urls.length > 0) return urls[urls.length - 1];
          }
          const direct = el.currentSrc || el.src || '';
          if (isUsable(direct)) return direct.trim();
          const href = el.href || (el.getAttribute ? el.getAttribute('href') : '') || '';
          if (isUsable(href)) return href.trim();
          const imgInside = el.querySelector ? el.querySelector('img') : null;
          if (imgInside && imgInside !== el) return pickCoverSrc(imgInside);
          return (el.textContent || '').trim();
        }

        // Strips a leading "Author: / 作者：" label when the selector matched
        // a container that includes the label text.
        function cleanAuthor(s) {
          return (s || '').replace(/^[\s]*(?:作者|作家|著者|author|by)\s*[:：]\s*/i, '').trim();
        }

        function metaContent(nameOrProp) {
          const m = document.querySelector('meta[property="' + nameOrProp + '"], meta[name="' + nameOrProp + '"]');
          const v = m ? (m.content || '').trim() : '';
          return v;
        }

        // Cover with sanity fallbacks: a landscape match is usually a logo or
        // banner, so prefer og:image in that case (and when nothing resolved).
        function resolveCover(el) {
          let url = pickCoverSrc(el);
          const w = el ? (el.naturalWidth || parseInt(el.getAttribute('width') || '0', 10) || 0) : 0;
          const h = el ? (el.naturalHeight || parseInt(el.getAttribute('height') || '0', 10) || 0) : 0;
          const landscape = el && w > 0 && h > 0 && w > h * 1.5;
          if (!url || landscape) {
            const og = metaContent('og:image');
            if (/^https?:/i.test(og)) url = og;
          }
          return url;
        }

        // A value that is only the field's own label ("Title:", "作者："), which
        // happens when the AI selector lands on the label instead of the value.
        const LABEL_WORD_RE = /^(?:author|作者|作家|著者|by|title|書名|タイトル|genre|ジャンル|status|ステータス|artist|illustrator|translator|narrator|type|category|categories|tag|tags|cover)$/i;

        function isLabelValue(s) {
          const t = (s || '').replace(/\s+/g, ' ').trim().replace(/[:：]\s*$/, '').trim();
          return t.length > 0 && t.length <= 24 && LABEL_WORD_RE.test(t);
        }

        // Reads the value of a "Label: value" pair, laid out either as siblings
        // (<p>Author:</p><h2>Weekly Lupin</h2>) or inline ("Author: Weekly Lupin").
        function salvageLabelled(labelWords) {
          const exactRe = new RegExp('^(?:' + labelWords + ')\\s*[:：]?$', 'i');
          const inlineRe = new RegExp('^(?:' + labelWords + ')\\s*[:：]\\s*(.+)$', 'i');
          const nodes = Array.from(document.body.querySelectorAll('p, span, div, dt, td, th, strong, b, label, li, h1, h2, h3, h4'));
          for (const el of nodes) {
            const own = (el.textContent || '').replace(/\s+/g, ' ').trim();
            if (exactRe.test(own)) {
              const next = el.nextElementSibling;
              const v = next ? (next.textContent || '').replace(/\s+/g, ' ').trim() : '';
              if (v && v.length < 120 && !exactRe.test(v)) return v;
              const holder = el.parentElement;
              const siblingVal = holder ? holder.querySelector('h1, h2, h3, h4, a') : null;
              const sv = siblingVal && siblingVal !== el ? (siblingVal.textContent || '').replace(/\s+/g, ' ').trim() : '';
              if (sv && sv.length < 120 && !exactRe.test(sv)) return sv;
            } else if (el.children.length === 0 && inlineRe.test(own)) {
              const v = own.replace(inlineRe, '$1').trim();
              if (v && v.length < 120) return v;
            }
          }
          return '';
        }

        function salvageTitle() {
          let og = metaContent('og:title');
          const site = metaContent('og:site_name');
          if (og && site && og.length > site.length && og.toLowerCase().endsWith(site.toLowerCase())) {
            og = og.slice(0, og.length - site.length).replace(/[\s|:–—-]+$/, '').trim();
          }
          if (og) return og;
          const h1 = document.querySelector('h1');
          if (h1 && h1.textContent.trim()) return h1.textContent.trim();
          return (document.title || '').trim();
        }

        // Last-resort synopsis: consecutive <p> siblings immediately above the
        // chapter list (skipping button/widget wrappers).
        function salvageSynopsis(listAnchor) {
          if (!listAnchor) return '';
          if (/^(LI|TR|DD|DT)$/.test(listAnchor.tagName) && listAnchor.parentElement) {
            listAnchor = listAnchor.parentElement;
          }
          const widgetRe = /button|menu|nav|social|share|banner|promo/i;
          const parts = [];
          let node = listAnchor.previousElementSibling;
          while (node) {
            const cls = (typeof node.className === 'string' ? node.className : '') + ' ' + (node.id || '');
            if (node.tagName === 'P') {
              const t = node.textContent.trim();
              if (t.length > 0) parts.unshift(t);
            } else if (widgetRe.test(cls)) {
              // skip pure widget wrappers
            } else {
              break;
            }
            node = node.previousElementSibling;
          }
          return parts.join('\n\n');
        }

        // When the synopsis selector matched a single paragraph out of a longer
        // blurb, widen it to that paragraph's whole contiguous same-class run —
        // but only if the run sits above the chapter list and still contains the
        // text already extracted, so this can only ever add the missing parts.
        function widenSynopsis(listAnchor, synopsisEls, synopsisText) {
          if (!listAnchor || synopsisEls.length !== 1) return '';
          const el = synopsisEls[0];
          if (!el || el.tagName !== 'P' || !el.parentElement) return '';
          const pos = listAnchor.compareDocumentPosition(el);
          if (pos & Node.DOCUMENT_POSITION_CONTAINS) return '';
          if (!(pos & Node.DOCUMENT_POSITION_PRECEDING)) return '';
          const cls = el.getAttribute('class') || '';
          const run = [el];
          let prev = el.previousElementSibling;
          while (prev && prev.tagName === 'P' && (prev.getAttribute('class') || '') === cls) {
            run.unshift(prev);
            prev = prev.previousElementSibling;
          }
          let nextPara = el.nextElementSibling;
          while (nextPara && nextPara.tagName === 'P' && (nextPara.getAttribute('class') || '') === cls) {
            run.push(nextPara);
            nextPara = nextPara.nextElementSibling;
          }
          if (run.length < 2) return '';
          const text = run.map(p => p.textContent.trim()).filter(t => t.length > 0).join('\n\n');
          const got = (synopsisText || '').trim();
          if (got && !text.includes(got)) return '';
          return text;
        }

        // Swaps top-level child combinators for descendant ones: 'div.info > a'
        // becomes 'div.info a'. AI selectors often use '>' where the value is
        // wrapped in one more element than it looked like in the tree.
        // Returns '' when there is nothing to relax.
        function relaxChildCombinators(sel) {
          const s = (sel || '').trim();
          if (!s) return '';
          let out = '', depth = 0, inQuote = null, changed = false;
          for (let i = 0; i < s.length; i++) {
            const c = s[i];
            if (inQuote) { out += c; if (c === inQuote) inQuote = null; continue; }
            if (c === '"' || c === "'") { inQuote = c; out += c; continue; }
            if (c === '(' || c === '[') depth++;
            else if (c === ')' || c === ']') depth--;
            else if (depth === 0 && c === '>') { changed = true; out += ' '; continue; }
            out += c;
          }
          return changed ? out.replace(/\s+/g, ' ').trim() : '';
        }

        // Same lookup as safeQueryAll, but if it found nothing, tries again with
        // relaxed child combinators. Selectors that already match are untouched.
        function queryAllLoose(root, sel) {
          const hit = safeQueryAll(root, sel);
          if (hit.length > 0) return hit;
          return safeQueryAll(root, relaxChildCombinators(sel));
        }

        function queryLoose(root, sel) {
          return queryAllLoose(root, sel)[0] || null;
        }

        // Chapter lists are sometimes placed *next to* the heading the AI keyed
        // its selector on ('div#link1 ul li' where the <ul> follows #link1), so
        // no relaxation of that selector can reach them. Rebuild the list from
        // the page instead: the list whose items link one level deeper into this
        // book's own URL path, which sidebars full of other books cannot do.
        function recoverChapterList(root, pageUrl) {
          let prefix = '';
          try {
            let path = new URL(pageUrl, document.location.href).pathname.replace(/[/]+$/, '');
            // '/book/x/7' is page 7 of '/book/x', not a folder named 7: without
            // this, every page after the first looks like a path no chapter of
            // this book lives under, and the recovery quietly finds nothing.
            path = path.replace(/\/\d+$/, '');
            prefix = path + '/';
          } catch (e) {
            return [];
          }
          if (prefix.length < 2) return [];
          const isChapterLink = el => {
            const href = el.getAttribute('href') || el.href || '';
            try {
              return new URL(href, pageUrl).pathname.startsWith(prefix);
            } catch (e) {
              return false;
            }
          };
          let best = [];
          for (const list of Array.from(root.querySelectorAll('ul, ol'))) {
            const items = [];
            for (const item of Array.from(list.children)) {
              const links = item.tagName === 'A' ? [item] : Array.from(item.querySelectorAll('a[href]'));
              const inner = links.filter(isChapterLink);
              if (inner.length === 1) items.push(inner[0]);
            }
            if (items.length > best.length) best = items;
          }
          return best.length >= 3 ? best : [];
        }

        // Chapter rows of one page: exactly what the selector asks for when that
        // matches, then the relaxed selector, then a rebuilt list. Only the last
        // two can differ from today's behaviour, and only where today gives zero.
        function chapterListItems(doc, pageUrl, baseSel) {
          const strict = safeQueryAll(doc, baseSel);
          if (strict.length > 0) return strict;
          const relaxed = safeQueryAll(doc, relaxChildCombinators(baseSel));
          if (relaxed.length > 0) return relaxed;
          const recovered = recoverChapterList(doc, pageUrl);
          if (recovered.length > 0) {
            console.log('[JS-Extractor] "' + baseSel + '" matched nothing, recovered ' + recovered.length + ' chapter links from the page instead.');
          }
          return recovered;
        }

        // Whether a candidate "next page" is the page we are on or one behind
        // it. AI selectors regularly grab the wrong button out of a bar — a bare
        // ':not(:first-child)' match is page 1 whichever page you stand on — and
        // following that walks an import backwards, or round in a circle, with
        // nothing logged but success.
        function isBackwardsOrSelf(fromUrl, toUrl) {
          if (fromUrl === toUrl) return true;
          try {
            const a = new URL(fromUrl, document.location.href);
            const b = new URL(toUrl, document.location.href);
            const pa = a.pathname.replace(/[/]+$/, '');
            const pb = b.pathname.replace(/[/]+$/, '');
            const an = pa.match(/\d+$/);
            const bn = pb.match(/\d+$/);
            if (an && bn && pa.slice(0, pa.length - an[0].length) === pb.slice(0, pb.length - bn[0].length)) {
              return parseInt(bn[0], 10) <= parseInt(an[0], 10);
            }
            const keys = ['page', 'p', 'pg', 'pno'];
            const ka = keys.filter(k => a.searchParams.has(k))[0];
            const kb = keys.filter(k => b.searchParams.has(k))[0];
            if (ka && ka === kb) {
              const av = parseInt(a.searchParams.get(ka), 10);
              const bv = parseInt(b.searchParams.get(kb), 10);
              if (isFinite(av) && isFinite(bv)) return bv <= av;
            }
          } catch (e) {}
          return false;
        }

        // A missed next-page link is the costliest miss in the whole extractor:
        // the import silently ends after one page and the reader never learns
        // the rest exists. nth-of-type counts and '>' chains go stale as soon as
        // a bar renders one button more or fewer than the tree suggested, so
        // fall back to the numeric sibling of the page's own address
        // ('/book/x/2' -> '/book/x/3', or ?page=2), which is what a paginated
        // chapter directory nearly always is.
        function nextPageLink(doc, pageUrl, sel) {
          const el = queryLoose(doc, sel);
          if (el) {
            const href = el.href || el.getAttribute('href');
            if (href && href !== 'javascript:;' && !href.startsWith('#')) {
              try {
                const u = new URL(href, pageUrl);
                if (!isBackwardsOrSelf(pageUrl, u.href)) return u.href;
              } catch (e) {}
            }
          }
          const recovered = recoverNextPage(doc, pageUrl);
          if (recovered) {
            console.log('[JS-Extractor] "' + sel + '" gave no next page, recovered ' + recovered);
          }
          return recovered;
        }

        // Whether an anchor sits in something that reads as a page bar. Numeric
        // sibling links are ambiguous on their own — '/novel/9/2' is the second
        // chapter as often as it is the second page — so recovery only trusts
        // numbers a pagination widget actually offered.
        function inPageBar(el) {
          let node = el;
          for (let depth = 0; node && depth < 3; depth++, node = node.parentElement) {
            const tokens = [];
            if (typeof node.className === 'string') tokens.push(...node.className.split(/\s+/));
            if (node.id) tokens.push(node.id);
            if (tokens.some(t => /(^|[-_])(page|pages|pagination|pager|pageno|next|prev)([-_]|$)/i.test(t))) return true;
          }
          return false;
        }

        function recoverNextPage(doc, pageUrl) {
          let cur;
          try { cur = new URL(pageUrl, document.location.href); } catch (e) { return null; }
          const segs = cur.pathname.split('/').filter(s => s.length > 0);
          const paged = segs.length > 0 && /^\d+$/.test(segs[segs.length - 1]);
          const paramKey = ['page', 'p', 'pg', 'pno'].filter(k => cur.searchParams.has(k))[0];
          // An un-numbered directory ('/book/x') is page 1 of whatever follows it.
          const currentNo = paged
            ? parseInt(segs[segs.length - 1], 10)
            : paramKey
              ? parseInt(cur.searchParams.get(paramKey) || '1', 10)
              : 1;
          if (!isFinite(currentNo)) return null;
          const base = paged ? segs.slice(0, segs.length - 1).join('/') : segs.join('/');
          const numbers = {};
          for (const a of Array.from(doc.querySelectorAll('a[href]'))) {
            let u;
            try { u = new URL(a.getAttribute('href'), pageUrl); } catch (e) { continue; }
            // A mirror's redirect target is not something to infer from a bare
            // number; the selector's job is cross-origin, this one is not.
            if (u.host !== cur.host) continue;
            let no;
            if (paramKey && u.searchParams.has(paramKey)) {
              if (u.pathname !== cur.pathname) continue;
              no = parseInt(u.searchParams.get(paramKey), 10);
            } else {
              const parts = u.pathname.split('/').filter(s => s.length > 0);
              if (parts.length !== base.split('/').filter(s => s.length > 0).length + 1) continue;
              if (parts.slice(0, parts.length - 1).join('/') !== base) continue;
              if (!/^\d+$/.test(parts[parts.length - 1])) continue;
              // Chapter rows are not a page bar, however they are numbered.
              if (!inPageBar(a)) continue;
              no = parseInt(parts[parts.length - 1], 10);
            }
            if (isFinite(no)) numbers[no] = u.href;
          }
          // A single numeric sibling is a coincidence; a bar lists its pages.
          if (Object.keys(numbers).length < 2) return null;
          return numbers[currentNo + 1] || null;
        }
''';

String generateBookExtrationJSPrompt(
  BookDetailsExtractor selectors,
  int startIndex,
) {
  final selectorsJson = jsonEncode(selectors.toJson());
  return """
  (async () => {
    try {
      const selectors = $selectorsJson;
      const startIndex = $startIndex;

      $jsExtractorHelpers

      const chDetails = selectors.individualChapterDetails || {};

      const titleEl = queryLoose(document.body, selectors.title);
      const authorEl = queryLoose(document.body, selectors.author);
      const synopsisEls = dedupeNested(queryAllLoose(document.body, selectors.synopsis));
      const coverEl = queryLoose(document.body, selectors.coverUrl);
      const jlptEl = safeQuery(document.body, selectors.jlptLevel);

      const docLang = document.documentElement.lang ||
        document.querySelector('meta[http-equiv="content-language"]')?.content ||
        document.querySelector('meta[name="language"]')?.content ||
        document.querySelector('meta[name="lang"]')?.content ||
        'en';

      const data = {
        url: document.location.href,
        source: document.location.origin,
        language: docLang,
        title: titleEl ? titleEl.textContent.trim() : '',
        author: authorEl ? authorEl.textContent.trim() : '',
        synopsis: synopsisEls.map(el => el.textContent.trim()).filter(t => t.length > 0).join('\\n\\n'),
        coverUrl: resolveCover(coverEl),
        jlptLevel: jlptEl ? jlptEl.textContent.trim() : '',
      };

      // Deterministic salvage for fields the AI selectors missed or mis-aimed.
      const listAnchorEl = chapterListItems(document, document.location.href, chDetails.base)[0] || null;

      if (!data.title || isLabelValue(data.title)) {
        const alt = salvageLabelled('title|書名|タイトル') || salvageTitle();
        if (alt && !isLabelValue(alt)) data.title = alt;
      }
      data.author = cleanAuthor(data.author);
      if (!data.author || isLabelValue(data.author)) {
        const byline = metaContent('article:author') || metaContent('author') || salvageLabelled('author|作者|作家|著者|by');
        if (byline && !isLabelValue(byline)) data.author = byline;
      }
      if (!data.synopsis) {
        data.synopsis = salvageSynopsis(listAnchorEl);
      } else {
        const wider = widenSynopsis(listAnchorEl, synopsisEls, data.synopsis);
        if (wider) data.synopsis = wider;
      }

      const nextPageSelector = selectors.nextPageUrl;

      console.log("[JS-Extractor] Initializing chapter extraction starting at index " + startIndex + "...");
      let chapters = [];
      let i = startIndex - 1;
      let nextUrl = document.location.href;
      let lastSuccessfulUrl = nextUrl;
      let pagesParsed = 0;
      // Only the address we are actually standing on may be read from `document`.
      // Keying that off `i` goes wrong whenever a page yields no rows: `i` never
      // moved, so the next address got parsed out of the previous page's DOM
      // while the log claimed it was being processed.
      let usingLiveDoc = true;

      while (nextUrl) {
        console.log("[JS-Extractor] Processing URL: " + nextUrl);
        let doc;

        if (usingLiveDoc) {
          console.log("[JS-Extractor] Using initial document DOM.");
          doc = document;
          usingLiveDoc = false;
        } else {
          try {
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
            data.chapters = chapters;
            data.failedUrl = nextUrl;
            data.lastSuccessfulUrl = lastSuccessfulUrl;
            data.pagesParsed = pagesParsed;
            ExtractionChannel.postMessage(JSON.stringify(data));
            return;
          }
        }

        const elements = chapterListItems(doc, nextUrl, chDetails.base);
        console.log("[JS-Extractor] Found " + elements.length + " chapter elements on page.");

        const pageChapters = [];
        for (const e of elements) {
          i += 1;
          const urlEl = safeQuery(e, chDetails.url);
          const titleEl = safeQuery(e, chDetails.title);
          const dateEl = safeQuery(e, chDetails.updatedDate);

          let chUrl = urlEl ? (urlEl.href || urlEl.getAttribute('href')) : null;
          if (!chUrl && e.tagName && e.tagName.toLowerCase() === 'a') {
            chUrl = e.href || e.getAttribute('href');
          }
          if (chUrl && !chUrl.startsWith('http://') && !chUrl.startsWith('https://')) {
            try {
              chUrl = new URL(chUrl, nextUrl).href;
            } catch (_) {}
          }

          const chTitle = (titleEl ? titleEl.textContent : (e ? e.textContent : ''))?.trim() || ('Chapter ' + (i + 1));
          const chDate = dateEl ? dateEl.textContent.trim() : null;

          pageChapters.push({
            url: chUrl,
            title: chTitle,
            updatedDate: chDate,
            number: i
          });
        }

        chapters = chapters.concat(pageChapters);
        lastSuccessfulUrl = nextUrl;
        pagesParsed++;

        if (typeof ProgressChannel !== 'undefined') {
          ProgressChannel.postMessage(JSON.stringify({ "count": chapters.length }));
        }

        let currentUrl = nextUrl;
        nextUrl = null;

        try {
          nextUrl = nextPageLink(doc, currentUrl, nextPageSelector);
          if (nextUrl) {
            console.log("[JS-Extractor] Next page found: " + nextUrl);
          } else {
            console.log("[JS-Extractor] No next page link detected. Finishing.");
          }
        } catch (e) {
          console.warn("[JS-Extractor] Error parsing next selector:", e);
          nextUrl = null;
        }
      }

      console.log("[JS-Extractor] Extraction complete. Total chapters: " + chapters.length);
      data.chapters = chapters;
      data.failedUrl = null;
      data.lastSuccessfulUrl = lastSuccessfulUrl;
      data.pagesParsed = pagesParsed;
      ExtractionChannel.postMessage(JSON.stringify(data));
    } catch (e) {
      ExtractionChannel.postMessage(JSON.stringify({ "error": e.toString() }));
    }
  })()
  """;
}

String generateContentExtractionJSPrompt(String selector) =>
    """
      (async () => {
        try {
          const selector = $selector;
          const results = [];

          $jsExtractorHelpers

          let doc = document;
          // Drop elements nested inside another match (e.g. 'p, p > em')
          // so overlapping selectors don't duplicate text lines.
          const containers = dedupeNested(safeQueryAll(doc, selector));
          let lines = [];

          for (const el of containers) {
            const children = Array.from(el.children);
            if (children.length > 0) {
              const childrenLines = children
                .map(function(c) {
                  let text = textOf(c);
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
              const text = textOf(el);
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
        if (/\\d/.test(cls)) return true; // spacing/sizing classes with numbers (e.g. p-4, w-1/2, z-10)

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
                if (/^\\d+\$/.test(el.id) || /^[a-f0-9]{32,}\$/i.test(el.id)) {
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

        // Direct text extraction (collapses whitespace, max 40 characters + ellipsis if longer)
        const directText = Array.from(el.childNodes)
            .filter(n => n.nodeType === 3)
            .map(n => n.nodeValue)
            .join(' ')
            .replace(/\\s+/g, ' ')
            .trim();

        if (directText.length > 0) {
            const truncated = directText.length > 40
                ? directText.slice(0, 40) + '...'
                : directText;
            label += `"\${truncated.replace(/"/g, '\\"')}"`;
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
