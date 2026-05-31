import 'package:flutter/foundation.dart';
import '../models/filter_option.dart';

class ScanViewModel extends ChangeNotifier {
  static const _kinds = ['contract', 'invoice', 'notes', 'receipt', 'id'];
  static const modes  = ['Documento', 'Tarjeta ID', 'Libro', 'Pizarra'];

  List<String> pages   = [];       // list of doc kinds captured this session
  int         cropIdx  = 0;
  FilterType  filter   = FilterType.magic;
  bool        flashOn  = false;
  String      mode     = 'Documento';
  int         _rotation = 0;       // degrees, for the current crop page

  int get rotation => _rotation;

  // ----- camera -----
  void startScan({String newMode = 'Documento'}) {
    pages    = [];
    cropIdx  = 0;
    filter   = FilterType.magic;
    mode     = newMode;
    flashOn  = false;
    _rotation = 0;
    notifyListeners();
  }

  void captureShot() {
    pages.add(_kinds[pages.length % _kinds.length]);
    notifyListeners();
  }

  void setMode(String m) {
    mode = m;
    notifyListeners();
  }

  void toggleFlash() {
    flashOn = !flashOn;
    notifyListeners();
  }

  // ----- crop -----
  void setCropIndex(int i) {
    if (i >= 0 && i < pages.length) {
      cropIdx   = i;
      _rotation = 0;
      notifyListeners();
    }
  }

  void rotatePage() {
    _rotation = (_rotation - 90) % 360;
    notifyListeners();
  }

  void setFilter(FilterType f) {
    filter = f;
    notifyListeners();
  }

  // ----- open existing doc -----
  void loadDocument(List<String> kinds) {
    pages     = List.from(kinds);
    cropIdx   = 0;
    filter    = FilterType.magic;
    _rotation = 0;
    notifyListeners();
  }

  // ----- helpers -----
  String get currentKind => pages.isEmpty ? 'contract' : pages[cropIdx];

  String get pdfTitle {
    final n = DateTime.now();
    final month = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'][n.month - 1];
    return 'Escaneo_${n.day}$month.pdf';
  }

  String pdfSubtitle({String? title}) {
    final n    = pages.isEmpty ? 1 : pages.length;
    final size = n == 1 ? '480 KB' : '${(n * 0.42).toStringAsFixed(1)} MB';
    return 'PDF · $n ${n == 1 ? 'página' : 'páginas'} · $size';
  }
}
