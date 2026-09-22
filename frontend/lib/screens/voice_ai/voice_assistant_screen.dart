import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/core_providers.dart';
import '../../services/offline_voice_intent_service.dart';
import '../../theme/kirana_colors.dart';
import 'voice_orb.dart';

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() =>
      _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  VoiceOrbState _state = VoiceOrbState.idle;

  String _status = 'READY';
  String _transcript = '';
  String _answer = '';

  bool _busy = false;

  Future<void> _listen() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _state = VoiceOrbState.listening;
      _status = 'LISTENING';
      _transcript = '';
      _answer = '';
    });

    try {
      // ---------------------------------------------------------------------
      // STEP 1: Local speech recognition
      // ---------------------------------------------------------------------

      final voiceService = ref.read(voiceServiceProvider);

      final transcript = await voiceService.listenForTranscript();

      if (!mounted) return;

      if (transcript == null || transcript.trim().isEmpty) {
        setState(() {
          _busy = false;
          _state = VoiceOrbState.error;
          _status = 'NO SPEECH DETECTED';
          _answer = 'I could not hear you. Please try again.';
        });

        return;
      }

      // ---------------------------------------------------------------------
      // STEP 2: Show transcript
      // ---------------------------------------------------------------------

      setState(() {
        _transcript = transcript;
        _state = VoiceOrbState.thinking;
        _status = 'UNDERSTANDING';
      });

      debugPrint(
        '[VoiceAssistantScreen] Local transcript: $transcript',
      );

      // ---------------------------------------------------------------------
      // STEP 3: Local offline intent processing
      // ---------------------------------------------------------------------

      final cacheService = ref.read(cacheServiceProvider);

      final offlineVoiceService = OfflineVoiceIntentService(
        cacheService: cacheService,
      );

      final result = await offlineVoiceService.process(
        transcript,
      );

      if (!mounted) return;

      debugPrint(
        '[VoiceAssistantScreen] '
        'Action: ${result.action}',
      );

      debugPrint(
        '[VoiceAssistantScreen] '
        'Response: ${result.response}',
      );

      // ---------------------------------------------------------------------
      // STEP 4: Execute local navigation action
      // ---------------------------------------------------------------------

      setState(() {
        _busy = false;
        _state = result.success ? VoiceOrbState.success : VoiceOrbState.error;
        _status = result.success ? 'RESPONSE READY' : 'COMMAND NOT UNDERSTOOD';
        _answer = result.response;
      });

      await _executeAction(result.action);
    } catch (error, stackTrace) {
      if (!mounted) return;

      debugPrint(
        '[VoiceAssistantScreen] Error: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      setState(() {
        _busy = false;
        _state = VoiceOrbState.error;
        _status = 'VOICE ERROR';
        _answer = 'I could not process that request. Please try again.';
      });
    }
  }

  Future<void> _executeAction(
    OfflineVoiceAction action,
  ) async {
    if (!mounted) return;

    switch (action) {
      case OfflineVoiceAction.none:
      case OfflineVoiceAction.createSale:
      case OfflineVoiceAction.createExpense:
        // These actions are already handled locally by the intent service.
        return;

      case OfflineVoiceAction.openDashboard:
        context.goNamed('home');
        return;

      case OfflineVoiceAction.openKhata:
        context.pushNamed('party_ledger');
        return;

      case OfflineVoiceAction.openInvoice:
        context.pushNamed('invoice_list');
        return;

      case OfflineVoiceAction.openPayments:
        context.pushNamed('payments_hub');
        return;

      case OfflineVoiceAction.openHistory:
        context.pushNamed('transaction_history');
        return;

      case OfflineVoiceAction.openCreditScore:
        // Credit-score navigation will be connected after we verify
        // the exact route registered in your current router.
        _showLocalMessage(
          'Credit score is available from the dashboard.',
        );
        return;

      case OfflineVoiceAction.openSettings:
        context.pushNamed('settings');
        return;
    }
  }

  void _showLocalMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _reset() {
    setState(() {
      _state = VoiceOrbState.idle;
      _status = 'READY';
      _transcript = '';
      _answer = '';
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiranaColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final orbSize =
                      constraints.maxWidth.clamp(280.0, 420.0) * 0.82;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      24,
                    ),
                    child: Column(
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 4),
                        _buildStatus(),
                        SizedBox(
                          height: orbSize + 28,
                          child: Center(
                            child: VoiceOrb(
                              size: orbSize,
                              state: _state,
                              onTap: _busy ? null : _listen,
                            ),
                          ),
                        ),
                        _buildVoiceControl(),
                        const SizedBox(height: 20),
                        if (_transcript.isNotEmpty) _buildTranscriptCard(),
                        if (_answer.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildAnswerCard(),
                        ],
                        const SizedBox(height: 12),
                        _buildHint(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: KiranaColors.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: KiranaColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VYAPAAR SAATHI',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    height: 0.9,
                    color: KiranaColors.onSurface,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'VOICE AI',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: KiranaColors.onSurface.withValues(
                      alpha: 0.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _accent.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              'AI',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            'SPEAK. I’LL HANDLE THE REST.',
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 31,
              height: 0.95,
              letterSpacing: 0.5,
              color: KiranaColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask about your business, sales, expenses or payments.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.4,
              color: KiranaColors.onSurface.withValues(
                alpha: 0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            _status,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: KiranaColors.onSurface.withValues(
                alpha: 0.62,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _busy ? null : _listen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: _busy ? _accent : KiranaColors.onSurface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(
                    alpha: _busy ? 0.18 : 0.0,
                  ),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _busy ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _busy ? 'PROCESSING' : 'TAP TO SPEAK',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_transcript.isNotEmpty || _answer.isNotEmpty) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: _busy ? null : _reset,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: KiranaColors.outlineVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: KiranaColors.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTranscriptCard() {
    return _panel(
      label: 'YOU SAID',
      icon: Icons.graphic_eq_rounded,
      child: Text(
        _transcript,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: KiranaColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildAnswerCard() {
    return _panel(
      label: 'VOICE AI',
      icon: Icons.auto_awesome_rounded,
      accent: true,
      child: Text(
        _answer,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          height: 1.5,
          color: KiranaColors.onSurface,
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KiranaColors.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: KiranaColors.onSurface.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Speak naturally in English, Hindi or Telugu. '
              'Your voice is processed on this device.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                height: 1.45,
                color: KiranaColors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String label,
    required IconData icon,
    required Widget child,
    bool accent = false,
  }) {
    final color = accent ? _accent : KiranaColors.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent
              ? _accent.withValues(alpha: 0.25)
              : KiranaColors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Color get _accent => const Color(0xFFE84E1B);

  Color get _statusColor {
    switch (_state) {
      case VoiceOrbState.idle:
        return KiranaColors.onSurface.withValues(alpha: 0.35);

      case VoiceOrbState.listening:
        return _accent;

      case VoiceOrbState.thinking:
        return const Color(0xFFD97736);

      case VoiceOrbState.success:
        return _accent;

      case VoiceOrbState.error:
        return const Color(0xFFB3261E);
    }
  }
}
