import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  static Future<String> generate({
    required List<String> imagePaths,
    required String title,
  }) async {
    final doc = pw.Document();

    for (final path in imagePaths) {
      final bytes = await File(path).readAsBytes();
      final img   = pw.MemoryImage(bytes);

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin:     pw.EdgeInsets.zero,
        build:      (_) => pw.Center(child: pw.Image(img, fit: pw.BoxFit.contain)),
      ));
    }

    final dir       = await getApplicationDocumentsDirectory();
    final ts        = DateTime.now().millisecondsSinceEpoch;
    final safeName  = title.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final filePath  = '${dir.path}/${safeName}_$ts.pdf';

    await File(filePath).writeAsBytes(await doc.save());
    return filePath;
  }
}
