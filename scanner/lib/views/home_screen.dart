import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/document.dart';
import '../viewmodels/home_vm.dart';
import '../viewmodels/scan_vm.dart';
import '../widgets/doc_card.dart';
import '../widgets/app_toast.dart';
import 'camera_screen.dart';
import 'pdf_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.green,
                onRefresh: () => context.read<HomeViewModel>().refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderSection(),
                      const _SectionHeader(),
                      const _DocumentGrid(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const _BottomNav(),
          ],
        ),
      ),
    );
  }
}

// ─── Header + Quick Actions ──────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  // quick action row height ≈ 101px, overlap = 34px → spacer = 67
  static const _spacer = 67.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(children: [
          _GradientHeader(),
          const SizedBox(height: _spacer),
        ]),
        Positioned(
          bottom: 0, left: 22, right: 22,
          child: _QuickActionsRow(),
        ),
      ],
    );
  }
}

class _GradientHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final vm     = context.watch<HomeViewModel>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.5, 1),
          colors: [AppColors.green, AppColors.greenD, AppColors.greenDD],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circle
          Positioned(
            right: -40, top: -30,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, topPad + 14, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand row
                Row(children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: const Icon(Icons.document_scanner_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('DocScan',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => showAppToast(context, 'Sin notificaciones nuevas'),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ]),
                const SizedBox(height: 22),
                const Text('Escanea lo que sea,\nal instante',
                    style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15)),
                const SizedBox(height: 4),
                Text('Toca el botón verde para empezar a escanear',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 18),
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Color(0x2E04503C), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, color: AppColors.slateL, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: context.read<HomeViewModel>().setQuery,
                        style: const TextStyle(fontSize: 14, color: AppColors.ink),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Buscar documentos…',
                          hintStyle: TextStyle(color: AppColors.slateL),
                        ),
                      ),
                    ),
                    if (vm.query.isNotEmpty)
                      GestureDetector(
                        onTap: () => context.read<HomeViewModel>().setQuery(''),
                        child: const Icon(Icons.close_rounded, color: AppColors.slateL, size: 18),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _QA(icon: Icons.photo_camera_outlined, label: 'Escanear',
          bg: AppColors.tint, fg: AppColors.green,
          onTap: () => _goScan(context, 'Documento')),
      const SizedBox(width: 11),
      _QA(icon: Icons.image_outlined, label: 'Importar',
          bg: const Color(0xFFe0f2fe), fg: const Color(0xFF0284c7),
          onTap: () => _goScan(context, 'Galería')),
      const SizedBox(width: 11),
      _QA(icon: Icons.description_outlined, label: 'Crear PDF',
          bg: const Color(0xFFf3e8ff), fg: const Color(0xFF7c3aed),
          onTap: () => _goScan(context, 'Documento')),
    ]);
  }

  void _goScan(BuildContext ctx, String mode) {
    ctx.read<ScanViewModel>().startScan(newMode: mode);
    Navigator.push(ctx, _route(const CameraScreen()));
  }
}

class _QA extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _QA({required this.icon, required this.label, required this.bg, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 15, 8, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 9),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ]),
      ),
    ),
  );
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recientes',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        GestureDetector(
          onTap: () => showAppToast(context, 'Mostrando todos los documentos'),
          child: const Text('Ver todo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
        ),
      ],
    ),
  );
}

// ─── Document grid ───────────────────────────────────────────────────────────

class _DocumentGrid extends StatelessWidget {
  const _DocumentGrid();

  @override
  Widget build(BuildContext context) {
    final docs = context.watch<HomeViewModel>().documents;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.58,
        ),
        itemCount: docs.length,
        itemBuilder: (ctx, i) => DocCard(
          doc: docs[i],
          onTap: () => _openDoc(ctx, docs[i]),
        ),
      ),
    );
  }

  void _openDoc(BuildContext ctx, Document doc) {
    ctx.read<ScanViewModel>().loadDocument(
      kinds: List.generate(doc.pages, (_) => doc.kind),
      existingPdfPath: doc.pdfPath,
    );
    Navigator.push(ctx, _route(const PdfScreen()));
  }
}

// ─── Bottom nav ──────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: EdgeInsets.fromLTRB(0, 11, 0, botPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Inicio
          Expanded(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.home_rounded, size: 22, color: AppColors.green),
                SizedBox(height: 4),
                Text('Inicio', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.green)),
                SizedBox(height: 26),
              ]),
            ),
          ),
          // FAB camera button (elevated above nav)
          GestureDetector(
            onTap: () {
              context.read<ScanViewModel>().startScan();
              Navigator.push(context, _route(const CameraScreen()));
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 62, height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21),
                gradient: const LinearGradient(
                  begin: Alignment(-1, -1),
                  end: Alignment(1, 1),
                  colors: [AppColors.mint, AppColors.green, AppColors.greenD],
                ),
                boxShadow: const [BoxShadow(color: Color(0x6A059669), blurRadius: 24, offset: Offset(0, 12))],
              ),
              child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 28),
            ),
          ),
          // Archivos
          Expanded(
            child: GestureDetector(
              onTap: () => showAppToast(context, 'Mostrando tus archivos'),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.folder_outlined, size: 22, color: AppColors.slateL),
                  SizedBox(height: 4),
                  Text('Archivos', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.slateL)),
                  SizedBox(height: 26),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Route helper ────────────────────────────────────────────────────────────

PageRouteBuilder _route(Widget page) => PageRouteBuilder(
  pageBuilder: (c, a, sa) => page,
  transitionsBuilder: (c, anim, sa, child) => FadeTransition(
    opacity: anim,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
  transitionDuration: const Duration(milliseconds: 320),
);
