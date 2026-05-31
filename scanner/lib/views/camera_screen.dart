import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_colors.dart';
import '../viewmodels/scan_vm.dart';
import '../widgets/page_thumbnail.dart';
import '../models/filter_option.dart';
import 'crop_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scanCtrl;
  late final AnimationController _breatheCtrl;
  late final Animation<double>   _scanAnim;
  late final Animation<double>   _breatheAnim;

  bool _launched = false;
  String _statusMsg = 'Preparando escáner…';

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      duration: const Duration(milliseconds: 2600), vsync: this)
      ..repeat(reverse: true);
    _breatheCtrl = AnimationController(
      duration: const Duration(milliseconds: 2400), vsync: this)
      ..repeat(reverse: true);

    _scanAnim = Tween<double>(begin: 0.04, end: 0.94).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _breatheAnim = Tween<double>(begin: 1.00, end: 1.012).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));

    // Launch the real scanner as soon as the frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchScanner());
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  // ─── Core scanning logic ─────────────────────────────────────────────────

  Future<void> _launchScanner({bool fromGallery = false}) async {
    if (_launched && !fromGallery) return;
    _launched = true;

    // Capture context-bound objects before any await
    final messenger = ScaffoldMessenger.of(context);
    final vm        = context.read<ScanViewModel>();
    final nav       = Navigator.of(context);

    // 1. Request camera permission
    setState(() => _statusMsg = 'Solicitando permiso de cámara…');
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        // Guide user to settings
        _showPermissionDialog();
        return;
      }
      _showSnack(messenger, 'Se requiere permiso de cámara');
      nav.pop();
      return;
    }

    // 2. Launch document scanner — loop to allow multi-page capture
    setState(() => _statusMsg = 'Abriendo escáner…');
    final allPictures = <String>[];

    try {
      while (true) {
        final pictures = await CunningDocumentScanner.getPictures(
          noOfPages: 1,
          isGalleryImportAllowed: fromGallery,
        );

        if (!mounted) return;
        if (pictures == null || pictures.isEmpty) break; // user tapped cancel

        allPictures.addAll(pictures);
        fromGallery = false; // gallery only on first scan

        // Ask if user wants to add another page
        final addMore = await _askAddMore(allPictures.length);
        if (!mounted) return;
        if (!addMore) break;

        setState(() => _statusMsg = 'Añade la siguiente hoja…');
      }

      if (allPictures.isEmpty) {
        nav.pop();
        return;
      }

      vm.setImagePaths(allPictures);
      nav.pushReplacement(_cropRoute());
    } catch (e) {
      if (!mounted) return;
      _showSnack(messenger, 'Error al escanear: $e');
      setState(() {
        _launched = false;
        _statusMsg = 'Toca el botón para intentar de nuevo';
      });
    }
  }

  Future<bool> _askAddMore(int count) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('$count hoja(s) escaneada(s)'),
        content: const Text('¿Deseas añadir otra página al documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, crear PDF'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, añadir página'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso de cámara'),
        content: const Text('DocScan necesita acceso a la cámara para escanear documentos. '
            'Habilítalo en Ajustes del dispositivo.'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () { openAppSettings(); Navigator.pop(ctx); },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  void _showSnack(ScaffoldMessengerState m, String msg) {
    m.clearSnackBars();
    m.showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(36, 0, 36, 40),
    ));
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: Column(children: [
          _TopBar(onClose: () => Navigator.pop(context)),
          _AnimatedViewfinder(scanAnim: _scanAnim, breatheAnim: _breatheAnim),
          _BottomControls(
            statusMsg:   _statusMsg,
            launched:    _launched,
            onScan:      () => _launchScanner(),
            onGallery:   () => _launchScanner(fromGallery: true),
          ),
        ]),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final vm     = context.watch<ScanViewModel>();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 0),
      child: Row(children: [
        _CircleBtn(icon: Icons.close_rounded, onTap: onClose),
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
      onTap: () => context.read<ScanViewModel>().toggleFlash(),
      child: _CircleContainer(
        color: vm.flashOn ? AppColors.mint : Colors.white.withValues(alpha: 0.14),
        child: Icon(
          vm.flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          color: vm.flashOn ? const Color(0xFF062b1f) : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: _CircleContainer(
      color: Colors.white.withValues(alpha: 0.14),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _CircleContainer extends StatelessWidget {
  final Color color;
  final Widget child;
  const _CircleContainer({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: child,
  );
}

// ─── Animated viewfinder ──────────────────────────────────────────────────────

class _AnimatedViewfinder extends StatelessWidget {
  final Animation<double> scanAnim;
  final Animation<double> breatheAnim;

  const _AnimatedViewfinder({required this.scanAnim, required this.breatheAnim});

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
            // Simulated document (decorativo)
            Transform.rotate(
              angle: -0.0524,
              child: SizedBox(
                width: sw * 0.62,
                child: AspectRatio(
                  aspectRatio: 1 / 1.32,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55), blurRadius: 60)],
                      ),
                      child: const PageThumbnail(kind: 'contract', filter: FilterType.original),
                    ),
                  ),
                ),
              ),
            ),

            // Breathing corners + scanline
            AnimatedBuilder(
              animation: breatheAnim,
              builder: (c, child) => Transform.scale(
                scale: breatheAnim.value,
                child: Transform.rotate(
                  angle: -0.0524,
                  child: SizedBox(
                    width: sw * 0.70,
                    child: AspectRatio(
                      aspectRatio: 1 / 1.34,
                      child: _DetectOverlay(scanAnim: scanAnim),
                    ),
                  ),
                ),
              ),
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
      return Stack(clipBehavior: Clip.none, children: [
        // "Documento detectado" badge
        Positioned(top: -30, left: 0, right: 0,
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

        // Corner brackets
        ..._cornerWidgets(),

        // Scanline
        AnimatedBuilder(
          animation: scanAnim,
          builder: (c, child) => Positioned(
            top: h * scanAnim.value, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.transparent, AppColors.mint, Colors.transparent]),
                boxShadow: [BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.6), blurRadius: 16, spreadRadius: 3)],
              ),
            ),
          ),
        ),
      ]);
    });
  }

  static List<Widget> _cornerWidgets() {
    const s = 26.0, bw = 3.5, col = AppColors.mint, r = Radius.circular(8);
    return [
      Positioned(top: -2, left: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: col, width: bw), left: BorderSide(color: col, width: bw)),
        borderRadius: BorderRadius.only(topLeft: r),
      ))),
      Positioned(top: -2, right: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: col, width: bw), right: BorderSide(color: col, width: bw)),
        borderRadius: BorderRadius.only(topRight: r),
      ))),
      Positioned(bottom: -2, left: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: col, width: bw), left: BorderSide(color: col, width: bw)),
        borderRadius: BorderRadius.only(bottomLeft: r),
      ))),
      Positioned(bottom: -2, right: -2, child: Container(width: s, height: s, decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: col, width: bw), right: BorderSide(color: col, width: bw)),
        borderRadius: BorderRadius.only(bottomRight: r),
      ))),
    ];
  }
}

// ─── Bottom controls ──────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final String statusMsg;
  final bool launched;
  final VoidCallback onScan;
  final VoidCallback onGallery;

  const _BottomControls({
    required this.statusMsg,
    required this.launched,
    required this.onScan,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final vm     = context.watch<ScanViewModel>();

    return Container(
      color: AppColors.dark,
      padding: EdgeInsets.fromLTRB(30, 18, 30, 24 + botPad),
      child: Column(children: [
        // Mode tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
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
                    Container(width: 5, height: 5, decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? AppColors.mint : Colors.transparent,
                    )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 22),

        // Shutter row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gallery button
            GestureDetector(
              onTap: onGallery,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  color: AppColors.dark3,
                ),
                child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
              ),
            ),

            // Main shutter — launches scanner
            GestureDetector(
              onTap: launched ? null : onScan,
              child: Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: launched ? 0.4 : 0.85),
                    width: 5,
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: launched ? AppColors.mint.withValues(alpha: 0.6) : Colors.white,
                  ),
                  child: launched
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark),
                        )
                      : null,
                ),
              ),
            ),

            // Retry / placeholder
            GestureDetector(
              onTap: launched ? null : onScan,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Icon(
                  launched ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                  color: AppColors.mint, size: 22,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Status message
        Text(
          statusMsg,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
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

// ─── Re-export constant for other screens ─────────────────────────────────────

const dark3Color = AppColors.dark3;
