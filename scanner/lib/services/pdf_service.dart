import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/filter_option.dart';

class PdfService {
  static Future<String> generate({
    required List<String> imagePaths,
    required String title,
    FilterType filter = FilterType.original,
  }) async {
    final doc = pw.Document();

    for (final path in imagePaths) {
      final bytes = await _processedBytes(path, filter);
      final img = pw.MemoryImage(bytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
        ),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = title.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final filePath = '${dir.path}/${safeName}_$ts.pdf';

    await File(filePath).writeAsBytes(await doc.save());
    return filePath;
  }

  static Future<Uint8List> _processedBytes(
    String path,
    FilterType filter,
  ) async {
    final bytes = await File(path).readAsBytes();
    if (filter == FilterType.original) return bytes;

    var decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    switch (filter) {
      case FilterType.auto:
        decoded = img.adjustColor(decoded, contrast: 1.06, saturation: 1.06);
      case FilterType.magic:
        decoded = img.adjustColor(
          decoded,
          contrast: 1.28,
          brightness: 1.08,
          saturation: 1.12,
        );
      case FilterType.gray:
        decoded = img.grayscale(decoded);
      case FilterType.bw:
        decoded = img.grayscale(decoded);
        decoded = img.adjustColor(decoded, contrast: 1.65);
      case FilterType.original:
        break;
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
  }
}
