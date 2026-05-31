import 'package:flutter/foundation.dart';
import '../models/document.dart';
import '../services/database_service.dart';

class HomeViewModel extends ChangeNotifier {
  // Seed documents shown until the user has their own scans
  static const _seed = [
    Document(id: 'seed1', title: 'Contrato de arrendamiento', date: 'Hoy, 14:32',  pages: 4, kind: 'contract'),
    Document(id: 'seed2', title: 'Factura — Marzo 2026',      date: 'Ayer, 09:10', pages: 1, kind: 'invoice'),
    Document(id: 'seed3', title: 'Notas de la reunión',       date: '28 may',      pages: 2, kind: 'notes'),
    Document(id: 'seed4', title: 'Recibo de servicios',       date: '26 may',      pages: 1, kind: 'receipt'),
    Document(id: 'seed5', title: 'Identificación oficial',    date: '24 may',      pages: 1, kind: 'id'),
    Document(id: 'seed6', title: 'Tarea de matemáticas',      date: '22 may',      pages: 3, kind: 'notes'),
  ];

  List<Document> _dbDocs = [];
  String         _query  = '';

  String get query => _query;

  HomeViewModel() {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final rows = await DatabaseService.instance.getAll();
      _dbDocs = rows.map((r) => Document(
        id:      r['id'].toString(),
        title:   r['title'] as String,
        date:    _fmtDate(r['created_at'] as String),
        pages:   r['page_count'] as int,
        kind:    'contract',
        pdfPath: r['pdf_path'] as String?,
      )).toList();
    } catch (_) {
      _dbDocs = [];
    }
    notifyListeners();
  }

  List<Document> get documents {
    final all = [..._dbDocs, ..._seed];
    if (_query.isEmpty) return all;
    return all.where((d) => d.title.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  static String _fmtDate(String iso) {
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Hoy, ${_pad(dt.hour)}:${_pad(dt.minute)}';
      if (diff.inDays == 1) return 'Ayer, ${_pad(dt.hour)}:${_pad(dt.minute)}';
      final months = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
