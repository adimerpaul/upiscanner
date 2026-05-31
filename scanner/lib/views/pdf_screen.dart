import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/filter_option.dart';
import '../models/share_target.dart';
import '../viewmodels/scan_vm.dart';
import '../widgets/page_thumbnail.dart';
import '../widgets/app_toast.dart';
import 'camera_screen.dart';

class PdfScreen extends StatelessWidget {
  const PdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _PdfTopBar(title: vm.pdfTitle, subtitle: vm.pdfSubtitle()),
            Expanded(child: _PdfBody(vm: vm)),
            _PdfThumbs(vm: vm),
            _PdfActions(title: vm.pdfTitle),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _PdfTopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PdfTopBar({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(18, topPad + 14, 18, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFf1f5f4),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: AppColors.ink, size: 22),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slateL, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFf1f5f4)),
            child: const Icon(Icons.more_horiz_rounded, color: AppColors.ink, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── PDF body ─────────────────────────────────────────────────────────────────

class _PdfBody extends StatelessWidget {
  final ScanViewModel vm;
  const _PdfBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    final pages = vm.pages.isEmpty ? ['contract'] : vm.pages;
    final n = pages.length;

    return Container(
      color: const Color(0xFFe7ecec),
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          // Info pills
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _Pill(icon: Icons.check_rounded, text: 'Recorte aplicado'),
              _Pill(icon: Icons.check_rounded, text: '$n hoja(s) en 1 archivo'),
            ],
          ),
          const SizedBox(height: 16),
          // Pages
          ...List.generate(n, (i) => _PdfPage(kind: pages[i], filter: vm.filter, pageNum: i + 1, total: n)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.green, size: 13),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate)),
      ],
    ),
  );
}

class _PdfPage extends StatelessWidget {
  final String kind;
  final FilterType filter;
  final int pageNum;
  final int total;
  const _PdfPage({required this.kind, required this.filter, required this.pageNum, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1 / 1.35,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.16), blurRadius: 34, offset: const Offset(0, 14))],
                ),
                child: PageThumbnail(kind: kind, filter: filter),
              ),
            ),
          ),
          Positioned(
            bottom: 8, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x990f172a),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$pageNum / $total', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Thumbnail strip ──────────────────────────────────────────────────────────

class _PdfThumbs extends StatelessWidget {
  final ScanViewModel vm;
  const _PdfThumbs({required this.vm});

  @override
  Widget build(BuildContext context) {
    final pages = vm.pages.isEmpty ? ['contract'] : vm.pages;

    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        children: [
          ...List.generate(pages.length, (i) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    width: 46, height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.green, width: 2),
                    ),
                    child: PageThumbnail(kind: pages[i], filter: vm.filter),
                  ),
                ),
                Container(
                  width: 46,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )),
          // Add page button
          GestureDetector(
            onTap: () {
              showAppToast(context, 'Añade más hojas a este PDF');
              Navigator.push(context, _camRoute());
            },
            child: Container(
              width: 46, height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.slateL, width: 2, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(7),
                color: AppColors.paper,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.slateL, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions bar ──────────────────────────────────────────────────────────────

class _PdfActions extends StatelessWidget {
  final String title;
  const _PdfActions({required this.title});

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(22, 12, 22, 30 + botPad),
      child: Row(
        children: [
          // OCR
          _ActionIcon(
            icon: Icons.text_fields_rounded,
            label: 'OCR',
            onTap: () => showAppToast(context, 'Texto reconocido (OCR)'),
          ),
          const SizedBox(width: 8),
          // Save
          _ActionIcon(
            icon: Icons.save_outlined,
            label: 'Guardar',
            onTap: () => showAppToast(context, 'Guardado en Mis documentos'),
          ),
          const SizedBox(width: 8),
          // Share
          Expanded(
            child: GestureDetector(
              onTap: () => _showShareSheet(context, title),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [AppColors.mint, AppColors.green, AppColors.greenD]),
                  boxShadow: const [BoxShadow(color: Color(0x61059669), blurRadius: 22, offset: Offset(0, 10))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ios_share_rounded, color: Colors.white, size: 19),
                    SizedBox(width: 9),
                    Text('Compartir', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.line, width: 1.5),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.slate, size: 20),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.slate)),
        ],
      ),
    ),
  );
}

// ─── Share sheet ──────────────────────────────────────────────────────────────

void _showShareSheet(BuildContext context, String title) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShareSheet(title: title),
  );
}

class _ShareSheet extends StatelessWidget {
  final String title;
  const _ShareSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grab bar
          Container(
            width: 40, height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: const Color(0xFFdfe5e6), borderRadius: BorderRadius.circular(3)),
          ),
          // Success banner
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('¡PDF creado!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('$title · listo para compartir',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Share targets grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8, mainAxisSpacing: 16,
            ),
            itemCount: ShareTarget.all.length,
            itemBuilder: (ctx, i) {
              final t = ShareTarget.all[i];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  showAppToast(context, 'Enviado por ${t.label}');
                },
                child: Column(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: t.color,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: t.color.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
                      ),
                      child: Icon(t.icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(t.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.slate)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Route helpers ────────────────────────────────────────────────────────────

PageRouteBuilder _camRoute() => PageRouteBuilder(
  pageBuilder: (c, a, sa) => const CameraScreen(),
  transitionsBuilder: (c, anim, sa, child) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
  transitionDuration: const Duration(milliseconds: 320),
);
