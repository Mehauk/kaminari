enum BookType {
  all("All"),
  webNovel("Web Novels"),
  lightNovel("Light Novels"),
  shortStory("Short Stories");

  final String text;
  const BookType(this.text);

  String get short => switch (this) {
    BookType.all => text,
    BookType.webNovel => "WEB",
    BookType.lightNovel => "LN",
    BookType.shortStory => "SS",
  };
}
