class Document {
  final String id;
  final String title;
  final String date;
  final int pages;
  final String kind;
  final String? pdfPath;
  final String? thumbnailPath;
  final List<String> imagePaths;

  const Document({
    required this.id,
    required this.title,
    required this.date,
    required this.pages,
    required this.kind,
    this.pdfPath,
    this.thumbnailPath,
    this.imagePaths = const [],
  });
}
