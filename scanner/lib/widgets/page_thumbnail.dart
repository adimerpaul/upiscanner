import 'package:flutter/material.dart';
import '../models/filter_option.dart';

class PageThumbnail extends StatelessWidget {
  final String kind;
  final FilterType filter;

  const PageThumbnail({
    super.key,
    required this.kind,
    this.filter = FilterType.original,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _colorFilter(),
      child: CustomPaint(
        painter: _PagePainter(kind: kind),
        child: const SizedBox.expand(),
      ),
    );
  }

  ColorFilter _colorFilter() {
    switch (filter) {
      case FilterType.auto:
        return const ColorFilter.matrix([
          1.06, 0, 0, 0, -7.65,
          0, 1.06, 0, 0, -7.65,
          0, 0, 1.06, 0, -7.65,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.magic:
        return const ColorFilter.matrix([
          1.284, 0, 0, 0, -25.5,
          0, 1.284, 0, 0, -25.5,
          0, 0, 1.284, 0, -25.5,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.gray:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.bw:
        return const ColorFilter.matrix([
          0.404, 1.359, 0.137, 0, -114.75,
          0.404, 1.359, 0.137, 0, -114.75,
          0.404, 1.359, 0.137, 0, -114.75,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.original:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}

class _PagePainter extends CustomPainter {
  final String kind;
  const _PagePainter({required this.kind});

  @override
  void paint(Canvas canvas, Size s) {
    // White background
    canvas.drawRect(Offset.zero & s, Paint()..color = Colors.white);

    final px = s.width  * 0.13;
    final py = s.height * 0.12;
    final w  = s.width  - 2 * px;
    double y = py;

    switch (kind) {
      case 'invoice':
        y = _title(canvas, px, y, w, s.height);
        y = _accent(canvas, px, y, w, s.height, const Color(0xFFbfdbfe));
        y += s.height * 0.04;
        y = _line(canvas, px, y, w, 0.88, s.height);
        y = _line(canvas, px, y, w, 0.70, s.height);
        y = _block(canvas, px, y, w, s.height);
        y = _line(canvas, px, y, w, 0.88, s.height);
        _line(canvas, px, y, w, 0.46, s.height);
      case 'notes':
        y = _title(canvas, px, y, w, s.height);
        for (final f in [0.88, 0.70, 0.88, 0.46, 0.70, 0.88, 0.46]) {
          y = _line(canvas, px, y, w, f, s.height);
        }
      case 'receipt':
        final aw = w * 0.46;
        _rect(canvas, (s.width - aw) / 2, y, aw, s.height * 0.06, const Color(0xFFcbd5dc));
        y += s.height * 0.06 + s.height * 0.04;
        for (final f in [0.88, 0.70, 0.88, 0.46, 0.70, 0.88]) {
          y = _line(canvas, px, y, w, f, s.height);
        }
      case 'id':
        y = _title(canvas, px, y, w, s.height);
        _rect(canvas, px, y, w, s.height * 0.30, const Color(0xFFdbe7ec));
        y += s.height * 0.30 + s.height * 0.06;
        for (final f in [0.70, 0.46, 0.88]) {
          y = _line(canvas, px, y, w, f, s.height);
        }
      default: // contract
        y = _title(canvas, px, y, w, s.height);
        y = _accent(canvas, px, y, w, s.height, const Color(0xFFa7f3d0));
        y += s.height * 0.04;
        for (final f in [0.88, 0.70, 0.88, 0.88, 0.46, 0.70, 0.88]) {
          y = _line(canvas, px, y, w, f, s.height);
        }
    }
  }

  double _title(Canvas c, double x, double y, double w, double sh) {
    _rect(c, x, y, w * 0.62, sh * 0.08, const Color(0xFFcbd5dc));
    return y + sh * 0.08 + sh * 0.03;
  }

  double _accent(Canvas c, double x, double y, double w, double sh, Color color) {
    _rect(c, x, y, w * 0.34, sh * 0.06, color);
    return y + sh * 0.06;
  }

  double _line(Canvas c, double x, double y, double w, double wf, double sh) {
    final h = sh * 0.045;
    _rect(c, x, y, w * wf, h, const Color(0xFFe2e8ec));
    return y + h + sh * 0.06;
  }

  double _block(Canvas c, double x, double y, double w, double sh) {
    final h = sh * 0.22;
    _rect(c, x, y, w, h, const Color(0xFFeef3f5));
    return y + h + sh * 0.06;
  }

  void _rect(Canvas c, double x, double y, double w, double h, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(3)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.kind != kind;
}
