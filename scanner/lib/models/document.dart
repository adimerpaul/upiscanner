class Document {
  final String id;
  final String title;
  final String date;
  final int pages;
  final String kind; // contract | invoice | notes | receipt | id

  const Document({
    required this.id,
    required this.title,
    required this.date,
    required this.pages,
    required this.kind,
  });
}
