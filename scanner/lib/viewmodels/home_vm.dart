import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/document.dart';
import '../services/database_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<Document> _dbDocs = [];
  String _query = '';

  String get query => _query;

  HomeViewModel() {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final rows = await DatabaseService.instance.getAll();
      _dbDocs = rows
          .map(
            (r) => Document(
              id: r['id'].toString(),
              title: r['title'] as String,
              date: _fmtDate(r['created_at'] as String),
              pages: r['page_count'] as int,
              kind: 'contract',
              pdfPath: _nullableText(r['pdf_path']),
              thumbnailPath: r['thumbnail_path'] as String?,
              imagePaths: _imagePaths(r['image_paths']),
            ),
          )
          .toList();
    } catch (_) {
      _dbDocs = [];
    }
    notifyListeners();
  }

  List<Document> get documents {
    if (_query.isEmpty) return _dbDocs;
    final needle = _query.toLowerCase();
    return _dbDocs
        .where((d) => d.title.toLowerCase().contains(needle))
        .toList();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  static String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Hoy, ${_pad(dt.hour)}:${_pad(dt.minute)}';
      if (diff.inDays == 1) return 'Ayer, ${_pad(dt.hour)}:${_pad(dt.minute)}';
      final months = [
        'ene',
        'feb',
        'mar',
        'abr',
        'may',
        'jun',
        'jul',
        'ago',
        'sep',
        'oct',
        'nov',
        'dic',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static String? _nullableText(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static List<String> _imagePaths(Object? value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().where((p) => p.isNotEmpty).toList();
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }
}
