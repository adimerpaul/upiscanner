import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/filter_utils.dart';
import '../models/filter_option.dart';
import '../viewmodels/scan_vm.dart';
import '../widgets/page_thumbnail.dart';
import '../widgets/app_toast.dart';
import 'pdf_screen.dart';

class CropScreen extends StatelessWidget {
  const CropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: Column(children: [
          _CropTopBar(),
          const Expanded(child: _CropStage()),
          const _ToolRow(),
          const _FilterStrip(),
          const _CropFooter(),
        ]),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _CropTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.dark,
      padding: EdgeInsets.fromLTRB(18, topPad + 14, 18, 14),
      child: Row(children: [
        _RoundBtn(icon: Icons.chevron_left_rounded, onTap: () => Navigator.pop(context)),
        const Expanded(
          child: Center(
            child: Text('Recortar y ajustar',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Repetir',
              style: TextStyle(color: AppColors.mint, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.14),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ─── Crop stage ───────────────────────────────────────────────────────────────

class _CropStage extends StatelessWidget {
  const _CropStage();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();
    final n  = vm.pages.length;
    final i  = vm.cropIdx;

    return Container(
      color: AppColors.dark,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Page counter badge
          Positioned(
            top: 18, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Página ${i + 1} de ${n > 0 ? n : 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),

          // Prev arrow
          if (i > 0)
            Positioned(
              left: 14,
              child: _PagerArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => context.read<ScanViewModel>().setCropIndex(i - 1),
              ),
            ),

          // Crop image (real or simulated)
          Center(
            child: SizedBox(
              width: 280,
              child: AspectRatio(
                aspectRatio: 1 / 1.3,
                child: _CropImage(
                  kind:      vm.currentKind,
                  filter:    vm.filter,
                  rotation:  vm.rotation,
                  imagePath: vm.hasRealImages ? vm.imagePaths[i] : null,
                ),
              ),
            ),
          ),

          // Next arrow
          if (n > 1 && i < n - 1)
            Positioned(
              right: 14,
              child: _PagerArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => context.read<ScanViewModel>().setCropIndex(i + 1),
              ),
            ),
        ],
      ),
    );
  }
}

class _PagerArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _PagerArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

class _CropImage extends StatelessWidget {
  final String kind;
  final FilterType filter;
  final int rotation;
  final String? imagePath;

  const _CropImage({
    required this.kind,
    required this.filter,
    required this.rotation,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (imagePath != null) {
      content = ColorFiltered(
        colorFilter: filterMatrix(filter),
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stk) => PageThumbnail(kind: kind, filter: filter),
        ),
      );
    } else {
      content = PageThumbnail(kind: kind, filter: filter);
    }

    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Transform.rotate(
          angle: rotation * 3.14159 / 180,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 50)],
            ),
            child: content,
          ),
        ),
      ),
      // Crop overlay
      Positioned(
        top: 8, left: 8, right: 8, bottom: 8,
        child: _CropOverlay(),
      ),
    ]);
  }
}

class _CropOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.mint, width: 2)),
        ),
      ),
      const _GridLines(),
      ..._handles(),
    ]);
  }

  static List<Widget> _handles() {
    Widget h(double? t, double? l, double? b, double? r) => Positioned(
      top: t, left: l, bottom: b, right: r,
      child: Container(
        width: 16, height: 16,
        decoration: BoxDecoration(
          color: AppColors.mint,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
        ),
      ),
    );
    return [h(-8, -8, null, null), h(-8, null, null, -8), h(null, -8, -8, null), h(null, null, -8, -8)];
  }
}

class _GridLines extends StatelessWidget {
  const _GridLines();

  @override
  Widget build(BuildContext context) {
    const color = Color(0x66059669);
    return Stack(children: [
      Positioned.fill(child: Column(children: [
        const Expanded(child: SizedBox()),
        Container(height: 1, color: color),
        const Expanded(child: SizedBox()),
        Container(height: 1, color: color),
        const Expanded(child: SizedBox()),
      ])),
      Positioned.fill(child: Row(children: [
        const Expanded(child: SizedBox()),
        Container(width: 1, color: color),
        const Expanded(child: SizedBox()),
        Container(width: 1, color: color),
        const Expanded(child: SizedBox()),
      ])),
    ]);
  }
}

// ─── Tool row ─────────────────────────────────────────────────────────────────

class _ToolRow extends StatelessWidget {
  const _ToolRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Tool(
            icon: Icons.crop_free_rounded,
            label: 'Auto-detectar',
            onTap: () => showAppToast(context, 'Bordes detectados'),
          ),
          const SizedBox(width: 14),
          _Tool(
            icon: Icons.rotate_left_rounded,
            label: 'Girar',
            onTap: () => context.read<ScanViewModel>().rotatePage(),
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tool({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// ─── Filter strip ─────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  const _FilterStrip();

  @override
  Widget build(BuildContext context) {
    final vm      = context.watch<ScanViewModel>();
    final current = vm.filter;

    return Container(
      color: AppColors.dark2,
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        children: FilterOption.all.map((f) {
          final active = f.type == current;
          return GestureDetector(
            onTap: () => context.read<ScanViewModel>().setFilter(f.type),
            child: Padding(
              padding: const EdgeInsets.only(right: 13),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50, height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: active ? AppColors.mint : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: vm.hasRealImages
                      ? ColorFiltered(
                          colorFilter: filterMatrix(f.type),
                          child: Image.file(
                            File(vm.imagePaths[vm.cropIdx]),
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stk) => PageThumbnail(kind: 'contract', filter: f.type),
                          ),
                        )
                      : PageThumbnail(kind: 'contract', filter: f.type),
                ),
                const SizedBox(height: 7),
                Text(
                  f.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.mint : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _CropFooter extends StatelessWidget {
  const _CropFooter();

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<ScanViewModel>();
    final n      = vm.pages.isEmpty ? 1 : vm.pages.length;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.dark,
      padding: EdgeInsets.fromLTRB(22, 14, 22, 30 + botPad),
      child: GestureDetector(
        onTap: () => Navigator.push(context, _pdfRoute()),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [AppColors.mint, AppColors.green, AppColors.greenD]),
            boxShadow: const [BoxShadow(color: Color(0x66059669), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              n > 1 ? 'Crear PDF · $n págs' : 'Crear PDF',
              style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 9),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ]),
        ),
      ),
    );
  }
}

PageRouteBuilder _pdfRoute() => PageRouteBuilder(
  pageBuilder: (c, a, sa) => const PdfScreen(),
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
