import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

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
      child: Row(children: [
        _RoundBtn(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
        Expanded(
          child: Center(
            child: Text(vm.mode,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        _FlashBtn(),
      ]),
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

// ─── Viewfinder (decorativo) ──────────────────────────────────────────────────

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
    _scanCtrl    = AnimationController(duration: const Duration(milliseconds: 2600), vsync: this)..repeat(reverse: true);
    _breatheCtrl = AnimationController(duration: const Duration(milliseconds: 2400), vsync: this)..repeat(reverse: true);
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
            // Document preview (decorativo)
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

            // Detection overlay (breathe)
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

            // Hint
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
    return LayoutBuilder(builder: (ctx, c) {
      final h = c.maxHeight;
      return Stack(
        clipBehavior: Clip.none,
        children: [
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
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 5),
                  Text('Documento detectado',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          ..._corners(),
          AnimatedBuilder(
            animation: scanAnim,
            builder: (c, child) => Positioned(
              top: h * scanAnim.value,
              left: 0, right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.transparent, AppColors.mint, Colors.transparent]),
                  boxShadow: [BoxShadow(color: AppColors.mint.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 3)],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  static List<Widget> _corners() {
    const s = 26.0, bw = 3.5, c = AppColors.mint, r = Radius.circular(8);

    return [
      Positioned(top: -2, left: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: c, width: bw), left: BorderSide(color: c, width: bw)),
        borderRadius: BorderRadius.only(topLeft: r),
      ))),
      Positioned(top: -2, right: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: c, width: bw), right: BorderSide(color: c, width: bw)),
        borderRadius: BorderRadius.only(topRight: r),
      ))),
      Positioned(bottom: -2, left: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: c, width: bw), left: BorderSide(color: c, width: bw)),
        borderRadius: BorderRadius.only(bottomLeft: r),
      ))),
      Positioned(bottom: -2, right: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: c, width: bw), right: BorderSide(color: c, width: bw)),
        borderRadius: BorderRadius.only(bottomRight: r),
      ))),
    ];
  }
}

class _CamHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lightbulb_outline_rounded, color: AppColors.mint, size: 14),
        SizedBox(width: 7),
        Text('Toca el botón para escanear el documento',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
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
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<ScanViewModel>();
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      color: AppColors.dark,
      padding: EdgeInsets.fromLTRB(0, 18, 0, 30 + botPad),
      child: Column(children: [
        // Mode pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: ScanViewModel.modes.map((m) {
              final active = vm.mode == m;
              return GestureDetector(
                onTap: () => context.read<ScanViewModel>().setMode(m),
                child: Padding(
                  padding: const EdgeInsets.only(right: 22),
                  child: Column(children: [
                    Text(m, style: TextStyle(
                      color: active ? AppColors.mint : Colors.white.withValues(alpha: 0.5),
                      fontSize: 13, fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: 6),
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? AppColors.mint : Colors.transparent,
                      ),
                    ),
                  ]),
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
              // Gallery import
              GestureDetector(
                onTap: _scanning ? null : () => _startScan(context, fromGallery: true),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    color: AppColors.dark3,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                ),
              ),

              // Shutter button
              GestureDetector(
                onTap: _scanning ? null : () => _startScan(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _scanning
                          ? AppColors.mint.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 5,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _scanning ? AppColors.mint : Colors.white,
                    ),
                    child: _scanning
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark),
                          )
                        : null,
                  ),
                ),
              ),

              // Done / placeholder
              Container(
                height: 52, width: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.mint, size: 22),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Future<void> _startScan(BuildContext context, {bool fromGallery = false}) async {
    // Capture context-dependent objects before any await
    final messenger = ScaffoldMessenger.of(context);
    final vm        = context.read<ScanViewModel>();
    final nav       = Navigator.of(context);

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(_buildSnack('Se requiere permiso de cámara'));
      return;
    }

    setState(() => _scanning = true);
    try {
      final pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 20,
        isGalleryImportAllowed: fromGallery,
      );

      if (pictures == null || pictures.isEmpty) return;
      if (!mounted) return;

      vm.setImagePaths(pictures);
      nav.push(_cropRoute());
    } catch (e) {
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(_buildSnack('Error al escanear: $e'));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  SnackBar _buildSnack(String msg) => SnackBar(
    content: Row(children: [
      const Icon(Icons.check_circle, color: AppColors.mint, size: 16),
      const SizedBox(width: 9),
      Flexible(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
    backgroundColor: AppColors.ink,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    duration: const Duration(milliseconds: 1900),
    margin: const EdgeInsets.fromLTRB(36, 0, 36, 110),
  );
}

// ─── Route helper ─────────────────────────────────────────────────────────────

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
