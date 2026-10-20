- [ ] importing rework and simplification
  - [ ] provide the data type you are expecting
  - [ ] provide uncompressed html (with some classes/ads removed)
  - [ ] wait for an exact js script to return data and pagination
  - [ ] go to first chapter page and use the pagination form previous step as we do currently to;
  - [ ] extract all chapters in order
  - [ ] save this script per source
  - [ ] parse data into object
  
- [ ] handle book deletion properly 
  - [ ] delete from view immediately (book meta data only) (no cascade)
  - [ ] delete the chapters and other related data
  - [ ] OR
  - [ ] delete from view immediately (optimistic delete) (soft delete)
  - [ ] delete book + chapters in one go asynhronously
  - [ ] ensure that if the app closes before the full delete goes through that
    - [ ] the book does not get partially deleted
    - [ ] the book is marked for delete (soft delete) so it doesnt show
    - [ ] AND a cleanup job is triggered the next time the app is opened

- [ ] novelight (The Support Ate it All)
- [X] operation failed popup is not working proerpy (the buttons inside)
- [x] invert chapters button in the import view and the details view
- [x] retries need to send old/incorrect (all) selectors with retry
- [ ] auto-update for new chapters
- [ ] open import chapter webview on error (only for current)
- [ ] importing sources
  - [ ] creates new source card on discovery page, takes you to inner discovery page for that source.
  - [ ] ai handles figuring out how to navigate the source; tagging and searching.
  - [ ] search bar handles searching inside that source showing the books in app (not webview)
- [ ] navigation
  - [ ] reader: chapters dropdown
  - [ ] discovery: search ba
  - [ ] webview: navigation
  - [ ] going back a chapter
- [ ] discover page changes
  - [ ] the search bar functions counterintuitively
  - [ ] import epub button
  - [ ] The import webview navigation is not good (back button for example)
  - [ ] finder (wrapper around a singular source search?)
- [ ] performance
  - [ ] frozen clpi on import (https://lorenovels.com/the-support-ate-it-all/)
- [ ] icon/splash update

- [ ] manga features
  - [ ] pre download images in chapters
  - [ ] Choose to keep downloaded
  - [ ] make sure that importing both indv. and sources works

- [ ] persist linebreaks/spacing?
- [ ] find an actual place to put the archived books
- [ ] relative scrollbar otherwise its always at the bottom

- [ ] complete book features
  - [ ] eng word entymology
  - [ ] additional language features? (chinese, korean, ...)
  - [ ] paragraphg transliteration/translation?

- [ ] performance
  - [ ] reader scrolling
  - [ ] reader opening

- [ ] replace ai with heuristical analysis across the board?
- [ ] use jagger or jptransliterate?

- [ ] backend/backups
  - [ ] books (ignoring content?)
  - [ ] usersettings