import 'package:flutter/foundation.dart';
import '../models/document.dart';

class HomeViewModel extends ChangeNotifier {
  static const _seed = [
    Document(id: '1', title: 'Contrato de arrendamiento', date: 'Hoy, 14:32',  pages: 4, kind: 'contract'),
    Document(id: '2', title: 'Factura — Marzo 2026',      date: 'Ayer, 09:10', pages: 1, kind: 'invoice'),
    Document(id: '3', title: 'Notas de la reunión',       date: '28 may',      pages: 2, kind: 'notes'),
    Document(id: '4', title: 'Recibo de servicios',       date: '26 may',      pages: 1, kind: 'receipt'),
    Document(id: '5', title: 'Identificación oficial',    date: '24 may',      pages: 1, kind: 'id'),
    Document(id: '6', title: 'Tarea de matemáticas',      date: '22 may',      pages: 3, kind: 'notes'),
  ];

  String _query = '';
  String get query => _query;

  List<Document> get documents => _query.isEmpty
      ? _seed
      : _seed.where((d) => d.title.toLowerCase().contains(_query.toLowerCase())).toList();

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }
}
