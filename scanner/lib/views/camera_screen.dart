import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../viewmodels/scan_vm.dart';
import '../widgets/page_thumbnail.dart';
import '../widgets/app_toast.dart';
import '../models/filter_option.dart';
import 'crop_screen.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: Column(
          children: [
            _CamTopBar(),
            const _Viewfinder(),
            const _CamControls(),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _CamTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final vm     = context.watch<ScanViewModel>();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 0),
      child: Row(
        children: [
          _RoundBtn(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                vm.mode,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _FlashBtn(),
        ],
      ),
    );
  }
}

class _FlashBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();
    return GestureDetector(
      onTap: () {
        context.read<ScanViewModel>().toggleFlash();
        showAppToast(context, vm.flashOn ? 'Flash desactivado' : 'Flash activado');
      },
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: vm.flashOn ? AppColors.mint : Colors.white.withValues(alpha: 0.14),
        ),
        child: Icon(
          vm.flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          color: vm.flashOn ? const Color(0xFF062b1f) : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
}

// ─── Viewfinder ───────────────────────────────────────────────────────────────

class _Viewfinder extends StatefulWidget {
  const _Viewfinder();

  @override
  State<_Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<_Viewfinder> with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _breatheCtrl;
  late final Animation<double>   _scanAnim;
  late final Animation<double>   _breatheAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(duration: const Duration(milliseconds: 2600), vsync: this)
      ..repeat(reverse: true);
    _breatheCtrl = AnimationController(duration: const Duration(milliseconds: 2400), vsync: this)
      ..repeat(reverse: true);
    _scanAnim    = Tween<double>(begin: 0.04, end: 0.94).animate(CurvedAnimation(parent: _scanCtrl,    curve: Curves.easeInOut));
    _breatheAnim = Tween<double>(begin: 1.00, end: 1.012).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.24),
            radius: 1.0,
            colors: [Color(0xFF2b3340), Color(0xFF14181f), Color(0xFF0a0d12)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Document preview
            Transform.rotate(
              angle: -0.0524,
              child: SizedBox(
                width: sw * 0.62,
                child: AspectRatio(
                  aspectRatio: 1 / 1.32,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 60)],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: const PageThumbnail(kind: 'contract', filter: FilterType.original),
                  ),
                ),
              ),
            ),

            // Detection overlay (breathe animation)
            AnimatedBuilder(
              animation: _breatheAnim,
              builder: (c, child) => Transform.scale(
                scale: _breatheAnim.value,
                child: Transform.rotate(
                  angle: -0.0524,
                  child: SizedBox(
                    width: sw * 0.70,
                    child: AspectRatio(
                      aspectRatio: 1 / 1.34,
                      child: _DetectOverlay(scanAnim: _scanAnim),
                    ),
                  ),
                ),
              ),
            ),

            // Hint at bottom
            Positioned(
              bottom: 22,
              child: _CamHint(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectOverlay extends StatelessWidget {
  final Animation<double> scanAnim;
  const _DetectOverlay({required this.scanAnim});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final h = c.maxHeight;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          // "Documento detectado" badge
          Positioned(
            top: -30, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 5),
                    Text('Documento detectado', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),

          // Corners
          ..._cornerWidgets(),

          // Scan line
          AnimatedBuilder(
            animation: scanAnim,
            builder: (c, child) => Positioned(
              top: h * scanAnim.value,
              left: 0, right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.transparent, AppColors.mint, Colors.transparent],
                  ),
                  boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 3)],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  static List<Widget> _cornerWidgets() {
    const size   = 26.0;
    const bWidth = 3.5;
    const color  = AppColors.mint;
    const r      = Radius.circular(8);

    Widget corner(AlignmentGeometry alignment, BorderRadius radius) => Align(
      alignment: alignment,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border(
            top:    alignment == Alignment.topLeft    || alignment == Alignment.topRight    ? const BorderSide(color: color, width: bWidth) : BorderSide.none,
            left:   alignment == Alignment.topLeft    || alignment == Alignment.bottomLeft  ? const BorderSide(color: color, width: bWidth) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? const BorderSide(color: color, width: bWidth) : BorderSide.none,
            right:  alignment == Alignment.topRight   || alignment == Alignment.bottomRight ? const BorderSide(color: color, width: bWidth) : BorderSide.none,
          ),
        ),
      ),
    );

    return [
      corner(Alignment.topLeft,     const BorderRadius.only(topLeft:     r)),
      corner(Alignment.topRight,    const BorderRadius.only(topRight:    r)),
      corner(Alignment.bottomLeft,  const BorderRadius.only(bottomLeft:  r)),
      corner(Alignment.bottomRight, const BorderRadius.only(bottomRight: r)),
    ];
  }
}

class _CamHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScanViewModel>();
    final n  = vm.pages.length;
    final text = n > 0
        ? '$n hoja(s) capturada(s) · sigue tomando o pulsa Listo'
        : 'Toca el obturador para capturar cada hoja';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.mint, size: 14),
          const SizedBox(width: 7),
          Flexible(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ─── Controls ─────────────────────────────────────────────────────────────────

class _CamControls extends StatefulWidget {
  const _CamControls();

  @override
  State<_CamControls> createState() => _CamControlsState();
}

class _CamControlsState extends State<_CamControls> {
  bool _flashing = false;

  @override
  Widget build(BuildContext context) {
    final vm       = context.watch<ScanViewModel>();
    final n        = vm.pages.length;
    final hasPages = n > 0;
    final botPad   = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.dark,
      padding: EdgeInsets.fromLTRB(0, 18, 0, 30 + botPad),
      child: Column(
        children: [
          // Mode pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: ScanViewModel.modes.map((m) {
                final active = vm.mode == m;
                return GestureDetector(
                  onTap: () {
                    context.read<ScanViewModel>().setMode(m);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: Column(
                      children: [
                        Text(
                          m,
                          style: TextStyle(
                            color: active ? AppColors.mint : Colors.white.withValues(alpha: 0.5),
                            fontSize: 13, fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? AppColors.mint : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Shutter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Stack preview button
                GestureDetector(
                  onTap: hasPages ? () => _finish(context) : null,
                  child: SizedBox(
                    width: 52, height: 52,
                    child: hasPages
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      const BoxShadow(color: Colors.white, offset: Offset(4, -4), blurRadius: 0, spreadRadius: -1),
                                      const BoxShadow(color: Color(0x66FFFFFF), offset: Offset(7, -7), blurRadius: 0, spreadRadius: -2),
                                    ],
                                  ),
                                  width: 46, height: 54,
                                  child: const PageThumbnail(kind: 'contract', filter: FilterType.original),
                                ),
                              ),
                              Positioned(
                                top: -6, right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.dark, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                              color: AppColors.dark3,
                            ),
                            child: const Icon(Icons.image_outlined, color: Colors.white, size: 20),
                          ),
                  ),
                ),

                // Shutter
                GestureDetector(
                  onTap: () => _capture(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 74, height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _flashing ? AppColors.mint : Colors.white,
                      ),
                    ),
                  ),
                ),

                // Done button
                GestureDetector(
                  onTap: hasPages ? () => _finish(context) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: hasPages
                          ? const LinearGradient(colors: [AppColors.mint, AppColors.green])
                          : null,
                      color: hasPages ? null : Colors.white.withValues(alpha: 0.12),
                      boxShadow: hasPages
                          ? [const BoxShadow(color: Color(0x66059669), blurRadius: 18, offset: Offset(0, 8))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasPages ? 'Listo · $n' : 'Listo',
                          style: TextStyle(
                            color: hasPages ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            fontSize: 13, fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _capture(BuildContext context) async {
    setState(() => _flashing = true);
    HapticFeedback.lightImpact();
    final vm        = context.read<ScanViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    vm.captureShot();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _flashing = false);
    final n = vm.pages.length;
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.mint, size: 16),
        const SizedBox(width: 9),
        Text('Hoja $n añadida', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      duration: const Duration(milliseconds: 1900),
      margin: const EdgeInsets.fromLTRB(36, 0, 36, 110),
      elevation: 12,
    ));
  }

  void _finish(BuildContext context) {
    final vm = context.read<ScanViewModel>();
    if (vm.pages.isEmpty) {
      showAppToast(context, 'Captura al menos una hoja');
      return;
    }
    Navigator.push(context, _cropRoute());
  }
}

PageRouteBuilder _cropRoute() => PageRouteBuilder(
  pageBuilder: (c, a, sa) => const CropScreen(),
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
