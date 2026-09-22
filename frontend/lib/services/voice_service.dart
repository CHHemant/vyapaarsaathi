// frontend/lib/services/voice_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'local_api_service.dart';

/// Represents a parsed voice command.
sealed class VoiceCommand {
  const VoiceCommand();
}

class NavigateHome extends VoiceCommand {
  const NavigateHome();
}

class NavigateCreditScore extends VoiceCommand {
  const NavigateCreditScore();
}

class NavigateInvoice extends VoiceCommand {
  const NavigateInvoice();
}

class NavigateHeatmap extends VoiceCommand {
  const NavigateHeatmap();
}

class NavigateCapture extends VoiceCommand {
  const NavigateCapture();
}

class UnrecognizedCommand extends VoiceCommand {
  final String transcript;

  const UnrecognizedCommand(this.transcript);
}

/// Represents an invoice item extracted from voice input.
class ParsedInvoiceItem {
  final String? name;
  final double? quantity;
  final double? unitPrice;

  const ParsedInvoiceItem({
    this.name,
    this.quantity,
    this.unitPrice,
  });

  bool get isComplete => name != null && quantity != null && unitPrice != null;
}

/// Core voice service.
///
/// Responsibilities:
/// - Record short voice clips.
/// - Send recorded audio to LocalApiService.
/// - Return real backend transcripts.
/// - Parse legacy navigation commands.
/// - Support wake-word mode.
/// - Parse invoice information.
/// - Send voice questions to the tax assistant.
class VoiceService {
  final LocalApiService _apiService;
  final AudioRecorder _recorder;

  bool _isListening = false;
  bool _isAlwaysListening = false;

  StreamController<VoiceCommand>? _alwaysListenController;

  static const String _wakeWord = 'vyapaarsaathi';
  static const Duration _clipDuration = Duration(seconds: 5);

  static const Map<String, VoiceCommand> _commandKeywords = {
    'home le raa': NavigateHome(),
    'home': NavigateHome(),
    'credit score chudu': NavigateCreditScore(),
    'credit score': NavigateCreditScore(),
    'bill banao': NavigateInvoice(),
    'bill': NavigateInvoice(),
    'invoice': NavigateInvoice(),
    'kalalu chudu': NavigateHeatmap(),
    'heatmap': NavigateHeatmap(),
    'transaction capture cheyi': NavigateCapture(),
    'capture': NavigateCapture(),
  };

  VoiceService({
    required LocalApiService apiService,
    AudioRecorder? recorder,
  })  : _apiService = apiService,
        _recorder = recorder ?? AudioRecorder();

  bool get isListening => _isListening;
  bool get isAlwaysListening => _isAlwaysListening;

  Future<void> playGreeting() async {
    debugPrint('[VoiceService] Greeting triggered.');
  }

  /// Records a short clip and returns the raw backend transcript.
  ///
  /// This is the method used by the new Voice Agent UI. It intentionally
  /// returns text instead of converting it into a legacy navigation command.
  Future<String?> listenForTranscript() async {
    if (_isListening) {
      return null;
    }

    _isListening = true;

    try {
      final audioBase64 = await _recordClip();

      if (audioBase64 == null) {
        return null;
      }

      final transcript = await _apiService.transcribeAudio(audioBase64);

      if (transcript == null || transcript.trim().isEmpty) {
        return null;
      }

      return transcript.trim();
    } catch (error, stackTrace) {
      debugPrint(
        '[VoiceService] listenForTranscript error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    } finally {
      _isListening = false;
    }
  }

  Future<VoiceCommand> listenForCommand() async {
    if (_isListening) {
      return const UnrecognizedCommand('');
    }

    _isListening = true;

    try {
      final audioBase64 = await _recordClip();

      if (audioBase64 == null) {
        return const UnrecognizedCommand('');
      }

      final transcript = await _apiService.transcribeAudio(audioBase64);

      if (transcript == null || transcript.trim().isEmpty) {
        return const UnrecognizedCommand('');
      }

      final command = parseCommand(transcript);

      if (command is! UnrecognizedCommand) {
        await _hapticSuccess();
      }

      return command;
    } catch (error, stackTrace) {
      debugPrint('[VoiceService] listenForCommand error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return const UnrecognizedCommand('');
    } finally {
      _isListening = false;
    }
  }

  VoiceCommand parseCommand(String transcript) {
    final normalized = transcript.toLowerCase().trim();

    if (normalized.isEmpty) {
      return const UnrecognizedCommand('');
    }

    for (final entry in _commandKeywords.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return UnrecognizedCommand(transcript);
  }

  bool execute(VoiceCommand command, GoRouter router) {
    switch (command) {
      case NavigateHome():
        router.goNamed('home');
      case NavigateCreditScore():
        router.goNamed('credit_score');
      case NavigateInvoice():
        router.goNamed('create_invoice');
      case NavigateHeatmap():
        router.goNamed('heatmap');
      case NavigateCapture():
        router.goNamed('passive_camera');
      case UnrecognizedCommand():
        return false;
    }

    return true;
  }

  Stream<VoiceCommand> startAlwaysListening() {
    if (_isAlwaysListening && _alwaysListenController != null) {
      return _alwaysListenController!.stream;
    }

    _isAlwaysListening = true;

    final controller = StreamController<VoiceCommand>.broadcast();
    _alwaysListenController = controller;

    unawaited(_pollLoop());

    return controller.stream;
  }

  Future<void> stopAlwaysListening() async {
    _isAlwaysListening = false;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (error) {
      debugPrint(
        '[VoiceService] recorder stop error: $error',
      );
    }

    final controller = _alwaysListenController;
    _alwaysListenController = null;

    await controller?.close();
  }

  Future<void> _pollLoop() async {
    while (_isAlwaysListening) {
      try {
        final audioBase64 = await _recordClip();

        if (!_isAlwaysListening) {
          break;
        }

        if (audioBase64 == null) {
          continue;
        }

        final transcript = await _apiService.transcribeAudio(audioBase64);

        if (transcript == null || transcript.trim().isEmpty) {
          continue;
        }

        final normalized = transcript.toLowerCase().trim();

        if (!normalized.contains(_wakeWord)) {
          continue;
        }

        final withoutWakeWord = normalized.replaceFirst(_wakeWord, '').trim();

        final command = parseCommand(withoutWakeWord);

        if (command is! UnrecognizedCommand) {
          await _hapticSuccess();
          _alwaysListenController?.add(command);
        }
      } catch (error, stackTrace) {
        debugPrint('[VoiceService] always-listen error: $error');
        debugPrintStack(stackTrace: stackTrace);

        if (_isAlwaysListening) {
          await Future<void>.delayed(
            const Duration(milliseconds: 500),
          );
        }
      }
    }
  }

  Future<ParsedInvoiceItem> listenForInvoiceItem() async {
    try {
      final audioBase64 = await _recordClip();

      if (audioBase64 == null) {
        return const ParsedInvoiceItem();
      }

      final transcript = await _apiService.transcribeAudio(audioBase64);

      if (transcript == null || transcript.trim().isEmpty) {
        return const ParsedInvoiceItem();
      }

      return parseInvoiceItem(transcript);
    } catch (error, stackTrace) {
      debugPrint(
        '[VoiceService] invoice listening error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      return const ParsedInvoiceItem();
    }
  }

  ParsedInvoiceItem parseInvoiceItem(String transcript) {
    final normalized = transcript.toLowerCase().trim();

    if (normalized.isEmpty) {
      return const ParsedInvoiceItem();
    }

    final qtyNameMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*'
      r'(?:kg|g|l|ml|pcs|pieces)?\s*'
      r'([a-z\u0900-\u097F\u0C00-\u0C7F]+)',
    ).firstMatch(normalized);

    final priceMatch = RegExp(
      r'(?:₹|rs\.?|rupay|rupaya|rupees)\s*'
      r'(\d+(?:\.\d+)?)',
    ).firstMatch(normalized);

    final quantity =
        qtyNameMatch == null ? null : double.tryParse(qtyNameMatch.group(1)!);

    final name = qtyNameMatch?.group(2)?.trim();

    final unitPrice =
        priceMatch == null ? null : double.tryParse(priceMatch.group(1)!);

    return ParsedInvoiceItem(
      name: name == null || name.isEmpty ? null : name,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  Future<String?> _recordClip() async {
    try {
      if (!await _recorder.hasPermission()) {
        debugPrint(
          '[VoiceService] Microphone permission denied.',
        );
        return null;
      }

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final clipPath = await _tempClipPath();

      await _recorder.start(
        const RecordConfig(),
        path: clipPath,
      );

      await Future<void>.delayed(_clipDuration);

      final recordedPath = await _recorder.stop();

      if (recordedPath == null || recordedPath.isEmpty) {
        return null;
      }

      final file = File(recordedPath);

      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();

      try {
        await file.delete();
      } catch (error) {
        debugPrint(
          '[VoiceService] Temporary audio cleanup failed: $error',
        );
      }

      if (bytes.isEmpty) {
        return null;
      }

      return base64Encode(bytes);
    } catch (error, stackTrace) {
      debugPrint('[VoiceService] recording error: $error');
      debugPrintStack(stackTrace: stackTrace);

      try {
        if (await _recorder.isRecording()) {
          await _recorder.stop();
        }
      } catch (_) {
        // Ignore recorder cleanup errors.
      }

      return null;
    }
  }

  Future<String> _tempClipPath() async {
    final directory = await getTemporaryDirectory();

    return '${directory.path}/'
        'voice_clip_${DateTime.now().microsecondsSinceEpoch}.m4a';
  }

  Future<void> _hapticSuccess() async {
    try {
      if (await Vibration.hasVibrator()) {
        await Vibration.vibrate(duration: 80);
      }
    } catch (error) {
      debugPrint('[VoiceService] vibration error: $error');
    }
  }

  Future<bool> shouldShowGreetingToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGreetingDate = prefs.getString('last_greeting_date');
    final today = DateTime.now().toIso8601String().split('T').first;

    return lastGreetingDate != today;
  }

  Future<void> markGreetingShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;

    await prefs.setString(
      'last_greeting_date',
      today,
    );
  }

  void stopSpeaking() {}

  Future<void> initialize() async {
    // AudioRecorder is initialized lazily when recording starts.
  }

  Future<String?> listenAndAsk() async {
    try {
      final audioBase64 = await _recordClip();

      if (audioBase64 == null) {
        return null;
      }

      final transcript = await _apiService.transcribeAudio(audioBase64);

      if (transcript == null || transcript.trim().isEmpty) {
        return null;
      }

      return await _apiService.askTaxAssistant(transcript);
    } catch (error, stackTrace) {
      debugPrint('[VoiceService] listenAndAsk error: $error');
      debugPrintStack(stackTrace: stackTrace);

      return null;
    }
  }

  /// Releases the recorder and any active always-listening stream.
  Future<void> dispose() async {
    await stopAlwaysListening();

    try {
      await _recorder.dispose();
    } catch (error) {
      debugPrint(
        '[VoiceService] recorder dispose error: $error',
      );
    }
  }
}
