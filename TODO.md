- [x] cache selector scripts to reuse -> fallback to gemini on fail
- [x] cache last read book and chapter
- [x] cache/restore scroll position
- [x] clickable kanji cards (more info)
- [x] h-b-p, t-d, k-g, s-z/j
- [x] implement history
- [ ] implement favoriting and favorites tab on history page
- [ ] download missing chapter using the cached chapter/page extractor (handle error by oepning the import webview at the pages location and manually clicking the import button) (note that the import button this time only targets the indivudal chapter and not the entire book.). also make sure that one chapter before and after are imported.


- [ ] Images?
- [ ] Empty States (favorites, history, discover (filtered/unfiltered))
- [ ] confirmation step to set booktype and whatnot
- [ ] extractAsShortStory on failure? (https://ncode.syosetu.com/n9674md/)
- [ ] BUG: you dont get all the chapters if you dont start on the first page.
- [ ] handle reimport same book
- [ ] use jagger?
- [ ] BUG: inf linearprog on import webview