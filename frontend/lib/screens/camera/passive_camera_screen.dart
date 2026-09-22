import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/kirana_colors.dart';

class PassiveCameraScreen extends StatefulWidget {
  const PassiveCameraScreen({super.key});

  @override
  State<PassiveCameraScreen> createState() => _PassiveCameraScreenState();
}

class _PassiveCameraScreenState extends State<PassiveCameraScreen> {
  late final MobileScannerController _scannerController;

  bool _isPaused = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.aztec,
        BarcodeFormat.pdf417,
      ],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      await _scannerController.start();
    } else {
      await _scannerController.stop();
    }
    if (!mounted) return;

    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flashlight is not available on this camera.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to switch camera.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_isProcessing) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value == null || value.isEmpty) {
        continue;
      }

      _isProcessing = true;

      HapticFeedback.mediumImpact();

      _scannerController.stop();

      _showScanResult(value);

      break;
    }
  }

  Future<void> _showScanResult(String value) async {
    final upiData = _parseUpi(value);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: KiranaColors.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: KiranaColors.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        upiData != null
                            ? Icons.account_balance_wallet_rounded
                            : Icons.qr_code_rounded,
                        color: KiranaColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upiData != null
                                ? 'UPI QR DETECTED'
                                : 'QR CODE DETECTED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'RobotoMono',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            upiData != null
                                ? 'Payment information found'
                                : 'Code scanned successfully',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (upiData != null) ...[
                  _ResultField(
                    label: 'UPI ID',
                    value: upiData.vpa ?? 'Not available',
                  ),
                  if (upiData.name != null) ...[
                    const SizedBox(height: 10),
                    _ResultField(
                      label: 'PAYEE',
                      value: upiData.name!,
                    ),
                  ],
                  if (upiData.amount != null) ...[
                    const SizedBox(height: 10),
                    _ResultField(
                      label: 'AMOUNT',
                      value: 'â‚¹${upiData.amount}',
                    ),
                  ],
                  if (upiData.note != null) ...[
                    const SizedBox(height: 10),
                    _ResultField(
                      label: 'NOTE',
                      value: upiData.note!,
                    ),
                  ],
                ] else
                  _ResultField(
                    label: 'SCANNED DATA',
                    value: value,
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: value),
                          );

                          if (!sheetContext.mounted) return;

                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Scanned data copied'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('COPY'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('DONE'),
                        style: FilledButton.styleFrom(
                          backgroundColor: KiranaColors.secondaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    _isProcessing = false;
    _isPaused = false;

    await _scannerController.start();

    if (!mounted) return;

    setState(() {});
  }

  _UpiData? _parseUpi(String value) {
    final normalized = value.trim();
    if (!normalized.toLowerCase().startsWith('upi://pay')) {
      return null;
    }

    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      return null;
    }

    final parameters = uri.queryParameters;

    return _UpiData(
      vpa: parameters['pa'],
      name: parameters['pn'],
      amount: parameters['am'],
      note: parameters['tn'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetection,
            errorBuilder: (context, error) {
              return _buildCameraError();
            },
          ),
          _buildCameraOverlay(),
          _buildTopBar(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_rounded,
            color: Colors.white70,
            size: 56,
          ),
          const SizedBox(height: 18),
          const Text(
            'CAMERA UNAVAILABLE',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'RobotoMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Allow camera permission and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _scannerController.start(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('RETRY CAMERA'),
            style: FilledButton.styleFrom(
              backgroundColor: KiranaColors.secondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  const _ScanCorner(
                    alignment: Alignment.topLeft,
                    rotation: 0,
                  ),
                  const _ScanCorner(
                    alignment: Alignment.topRight,
                    rotation: 90,
                  ),
                  const _ScanCorner(
                    alignment: Alignment.bottomRight,
                    rotation: 180,
                  ),
                  const _ScanCorner(
                    alignment: Alignment.bottomLeft,
                    rotation: 270,
                  ),
                  Center(
                    child: Container(
                      width: 240,
                      height: 2,
                      color: KiranaColors.secondaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            _CircleButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: KiranaColors.secondaryContainer,
                      size: 8,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'VISION QR SCANNER',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'RobotoMono',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    Text(
                      'ON-DEVICE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'RobotoMono',
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CircleButton(
              icon: Icons.flashlight_on_rounded,
              onPressed: _toggleTorch,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: KiranaColors.secondary,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'ALIGN QR CODE INSIDE THE FRAME',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ControlButton(
                      icon: _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      label: _isPaused ? 'RESUME' : 'PAUSE',
                      onPressed: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ControlButton(
                      icon: Icons.flip_camera_android_rounded,
                      label: 'SWITCH',
                      onPressed: _switchCamera,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultField extends StatelessWidget {
  final String label;
  final String value;

  const _ResultField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontFamily: 'RobotoMono',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 5),
          SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'RobotoMono',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ScanCorner extends StatelessWidget {
  final Alignment alignment;
  final double rotation;

  const _ScanCorner({
    required this.alignment,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: rotation * 3.1415926535 / 180,
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: KiranaColors.secondaryContainer,
                width: 4,
              ),
              left: BorderSide(
                color: KiranaColors.secondaryContainer,
                width: 4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpiData {
  final String? vpa;
  final String? name;
  final String? amount;
  final String? note;

  const _UpiData({
    this.vpa,
    this.name,
    this.amount,
    this.note,
  });
}
