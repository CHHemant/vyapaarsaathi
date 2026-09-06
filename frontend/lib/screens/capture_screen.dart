// frontend/lib/screens/capture_screen.dart

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/transaction.dart';
import '../providers/core_providers.dart';
import '../services/api_service.dart';
import '../theme/kirana_colors.dart';
import '../widgets/rupee_button.dart';
import '../widgets/kirana_card.dart';
import '../widgets/entrance_animation.dart';

sealed class _CaptureStage {
  const _CaptureStage();
}

class _StageLive extends _CaptureStage {
  const _StageLive();
}

class _StageProcessing extends _CaptureStage {
  const _StageProcessing();
}

class _StageReview extends _CaptureStage {
  final TransactionCaptureResponse response;
  final TransactionCategory selectedCategory;
  const _StageReview(this.response, this.selectedCategory);

  Transaction get transaction => switch (response) {
        ConfirmedCapture(:final transaction) => transaction,
        LowConfidenceCapture(:final transaction) => transaction,
      };

  int get confidence => switch (response) {
        ConfirmedCapture(:final confidence) => confidence,
        LowConfidenceCapture(:final confidence) => confidence,
      };
}

class _StagePermissionDenied extends _CaptureStage {
  const _StagePermissionDenied();
}

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  _CaptureStage _stage = const _StageProcessing();
  Uint8ListLike? _lastCapturedBytes;
  bool _isFlashOn = false;
  AnimationController? _shutterAnimation;

  @override
  void initState() {
    super.initState();
    _shutterAnimation = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _init();
  }

  Future<void> _init() async {
    final camPermission = await Permission.camera.request();
    final micPermission = await Permission.microphone.request();

    if (!camPermission.isGranted || !micPermission.isGranted) {
      setState(() => _stage = const _StagePermissionDenied());
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _showSnack('No cameras found');
        setState(() => _stage = const _StagePermissionDenied());
        return;
      }
      
      _currentCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _startCamera(_cameras[_currentCameraIndex]);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not start camera: $e');
      setState(() => _stage = const _StagePermissionDenied());
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _stage = const _StageLive();
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    
    setState(() => _stage = const _StageProcessing());
    await _controller?.dispose();
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_currentCameraIndex]);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shutterAnimation?.dispose();
    super.dispose();
  }

  Future<void> _captureAndSend() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    _shutterAnimation!.forward().then((_) => _shutterAnimation!.reverse());

    setState(() => _stage = const _StageProcessing());

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      _lastCapturedBytes = Uint8ListLike(bytes);
      await _sendForCapture(bytes);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not capture photo: $e');
      setState(() => _stage = const _StageLive());
    }
  }

  Future<void> _sendForCapture(List<int> imageBytes) async {
    final api = ref.read(apiServiceProvider);
    try {
      final response = await api.captureTransaction(
          imageBase64: base64Encode(imageBytes));

      final transaction = switch (response) {
        ConfirmedCapture(:final transaction) => transaction,
        LowConfidenceCapture(:final transaction) => transaction,
      };

      if (!mounted) return;

      if (response is LowConfidenceCapture) {
        final shouldVerify = await _showLowConfidenceDialog();
        if (!mounted) return;
        if (!shouldVerify) {
          setState(() => _stage = const _StageLive());
          return;
        }
      }

      setState(() => _stage = _StageReview(response, transaction.category));
    } on ApiException catch (e) {
      if (!mounted) return;
      final shouldRetry = await _showErrorRetryDialog(e.message);
      if (!mounted) return;
      if (shouldRetry && _lastCapturedBytes != null) {
        await _sendForCapture(_lastCapturedBytes!.bytes);
      } else {
        setState(() => _stage = const _StageLive());
      }
    }
  }

  Future<bool> _showLowConfidenceDialog() async {
    return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Verify manually?'),
                content: const Text(
                    'The detected amount has low confidence. Please check it before saving.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Retake'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Review'),
                  ),
                ],
              ),
            ) ??
        false;
  }

  Future<bool> _showErrorRetryDialog(String message) async {
    return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Network slow, retry?'),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ) ??
        false;
  }

  Future<void> _confirm(_StageReview stage) async {
    final cache = ref.read(cacheServiceProvider);
    final finalTransaction =
        stage.selectedCategory == stage.transaction.category
            ? stage.transaction
            : Transaction(
                id: stage.transaction.id,
                amount: stage.transaction.amount,
                category: stage.selectedCategory,
                timestamp: stage.transaction.timestamp,
                confidence: stage.transaction.confidence,
                customerName: stage.transaction.customerName,
                customerId: stage.transaction.customerId,
                isSynced: true,
              );

    await cache.addTransaction(finalTransaction);
    if (!mounted) return;
    _showSnack('Transaction saved!');
    context.goNamed('home');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (_stage) {
        _StagePermissionDenied() =>
          _PermissionDeniedView(onOpenSettings: openAppSettings),
        _StageProcessing() when _controller == null => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        _StageLive() => _LiveCameraView(
            controller: _controller!,
            onCapture: _captureAndSend,
            isFlashOn: _isFlashOn,
            onToggleFlash: _toggleFlash,
            onSwitchCamera: _switchCamera,
            shutterAnimation: _shutterAnimation!,
          ),
        _StageProcessing() => const _ProcessingOverlay(),
        final _StageReview stage => _ReviewPanel(
            stage: stage,
            onCategoryChanged: (category) =>
                setState(() => _stage = _StageReview(stage.response, category)),
            onConfirm: () => _confirm(stage),
            onRetake: () => setState(() => _stage = const _StageLive()),
          ),
      },
    );
  }

  void _toggleFlash() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _controller!.setFlashMode(_isFlashOn ? FlashMode.off : FlashMode.always);
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }
}

class Uint8ListLike {
  final List<int> bytes;
  const Uint8ListLike(this.bytes);
}

class _LiveCameraView extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onCapture;
  final bool isFlashOn;
  final VoidCallback onToggleFlash;
  final VoidCallback onSwitchCamera;
  final AnimationController shutterAnimation;

  const _LiveCameraView({
    required this.controller,
    required this.onCapture,
    required this.isFlashOn,
    required this.onToggleFlash,
    required this.onSwitchCamera,
    required this.shutterAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            ),
          ),
        ),

        // Shutter Animation Overlay
        AnimatedBuilder(
          animation: shutterAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: shutterAnimation.value,
              child: Container(color: Colors.white),
            );
          },
        ),

        // Controls
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                isActive: isFlashOn,
                onTap: onToggleFlash,
              ),
              _buildControlButton(
                icon: Icons.flip_camera_ios_rounded,
                onTap: onSwitchCamera,
              ),
            ],
          ),
        ),

        // Alignment Guide
        IgnorePointer(
          child: CustomPaint(
            painter: _AlignmentGuidePainter(),
            child: const SizedBox.expand(),
          ),
        ),

        // Bottom UI
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text(
                'Align bill within the box',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onCapture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive ? KiranaColors.tertiary : Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _AlignmentGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.3,
    );
    final paint = Paint()
      ..color = KiranaColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerLength = 30.0;
    
    // Top Left
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLength), paint);
    
    // Top Right
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLength), paint);
    
    // Bottom Left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLength), paint);
    
    // Bottom Right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _AlignmentGuidePainter oldDelegate) => false;
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: KiranaColors.primary),
            const SizedBox(height: 24),
            Text(
              'Analyzing Receipt...',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  final _StageReview stage;
  final ValueChanged<TransactionCategory> onCategoryChanged;
  final VoidCallback onConfirm;
  final VoidCallback onRetake;

  const _ReviewPanel({
    required this.stage,
    required this.onCategoryChanged,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Review Entry', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 32),
              KiranaCard(
                child: Column(
                  children: [
                    Text(
                      'Detected Amount',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${stage.transaction.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: KiranaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: KiranaColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${stage.confidence}% CONFIDENCE',
                        style: TextStyle(color: KiranaColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Transaction Category', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              DropdownButtonFormField<TransactionCategory>(
                value: stage.selectedCategory,
                items: TransactionCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.name}')))
                    .toList(),
                onChanged: (c) => c != null ? onCategoryChanged(c) : null,
              ),
              const Spacer(),
              RupeeButton(
                label: 'Confirm Entry',
                icon: Icons.check_circle_rounded,
                showRupeePrefix: false,
                onPressed: onConfirm,
                fullWidth: true,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retake Photo'),
                style: TextButton.styleFrom(foregroundColor: KiranaColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionDeniedView({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white38, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Camera access is required to capture bills.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 32),
              RupeeButton(
                label: 'Enable in Settings',
                showRupeePrefix: false,
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
