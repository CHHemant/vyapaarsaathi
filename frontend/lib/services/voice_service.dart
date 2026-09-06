// frontend/lib/services/voice_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_api_service.dart'; // ✅ Changed from api_service.dart

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

class ParsedInvoiceItem {
  final String? name;
  final double? quantity;
  final double? unitPrice;
  const ParsedInvoiceItem({this.name, this.quantity, this.unitPrice});

  bool get isComplete => name != null && quantity != null && unitPrice != null;
}

class VoiceService {
  final LocalApiService _apiService; // ✅ Changed from ApiService to LocalApiService
  final AudioRecorder _recorder;

  VoiceService({required LocalApiService apiService, AudioRecorder? recorder}) // ✅ Changed constructor
      : _apiService = apiService,
        _recorder = recorder ?? AudioRecorder();

  static const String _wakeWord = 'vyapaarsaathi';
  static const Duration _clipDuration = Duration(seconds: 3);

  static final Map<String, VoiceCommand> _commandKeywords = {
    'home le raa': const NavigateHome(),
    'home': const NavigateHome(),
    'credit score chudu': const NavigateCreditScore(),
    'credit score': const NavigateCreditScore(),
    'bill banao': const NavigateInvoice(),
    'bill': const NavigateInvoice(),
    'invoice': const NavigateInvoice(),
    'kalalu chudu': const NavigateHeatmap(),
    'heatmap': const NavigateHeatmap(),
    'transaction capture cheyi': const NavigateCapture(),
    'capture': const NavigateCapture(),
  };

  StreamController<VoiceCommand>? _alwaysListenController;
  bool _isAlwaysListening = false;
  bool get isAlwaysListening => _isAlwaysListening;

  Future<void> playGreeting() async {
    debugPrint('[VoiceService] Greeting triggered (visual only)');
  }

  String _getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Namaste! Subah ki pehli sale kitni hui?';
    } else if (hour < 17) {
      return 'Namaste! Aaj ka business kaisa chal raha hai?';
    } else {
      return 'Namaste! Shaam tak kitna collection hua?';
    }
  }

  Future<VoiceCommand> listenForCommand() async {
    final audioBase64 = await _recordClip();
    if (audioBase64 == null) return const UnrecognizedCommand('');

    final transcript = await _apiService.transcribeAudio(audioBase64);
    if (transcript == null || transcript.trim().isEmpty) {
      return const UnrecognizedCommand('');
    }

    final command = parseCommand(transcript);
    if (command is! UnrecognizedCommand) {
      await _hapticSuccess();
    }
    return command;
  }

  VoiceCommand parseCommand(String transcript) {
    final normalized = transcript.toLowerCase().trim();
    for (final entry in _commandKeywords.entries) {
      if (normalized.contains(entry.key)) return entry.value;
    }
    return UnrecognizedCommand(transcript);
  }

  bool execute(VoiceCommand command, GoRouter router) {
    switch (command) {
      case NavigateHome():
        router.goNamed('home');
      case NavigateCreditScore():
        router.goNamed('creditScore');
      case NavigateInvoice():
        router.goNamed('invoice');
      case NavigateHeatmap():
        router.goNamed('heatmap');
      case NavigateCapture():
        router.goNamed('capture');
      case UnrecognizedCommand():
        return false;
    }
    return true;
  }

  Stream<VoiceCommand> startAlwaysListening() {
    _isAlwaysListening = true;
    _alwaysListenController = StreamController<VoiceCommand>.broadcast();
    _pollLoop();
    return _alwaysListenController!.stream;
  }

  Future<void> stopAlwaysListening() async {
    _isAlwaysListening = false;
    await _recorder.stop();
    await _alwaysListenController?.close();
    _alwaysListenController = null;
  }

  Future<void> _pollLoop() async {
    while (_isAlwaysListening) {
      try {
        final audioBase64 = await _recordClip();
        if (audioBase64 == null) continue;

        final transcript = await _apiService.transcribeAudio(audioBase64);
        if (transcript == null) continue;

        final normalized = transcript.toLowerCase();
        if (!normalized.contains(_wakeWord)) continue;

        final withoutWakeWord = normalized.replaceFirst(_wakeWord, '').trim();
        final command = parseCommand(withoutWakeWord);
        if (command is! UnrecognizedCommand) {
          await _hapticSuccess();
          _alwaysListenController?.add(command);
        }
      } catch (e) {
        debugPrint('[VoiceService] always-listen poll error: $e');
      }
    }
  }

  Future<ParsedInvoiceItem> listenForInvoiceItem() async {
    final audioBase64 = await _recordClip();
    if (audioBase64 == null) return const ParsedInvoiceItem();

    final transcript = await _apiService.transcribeAudio(audioBase64);
    if (transcript == null) return const ParsedInvoiceItem();

    return parseInvoiceItem(transcript);
  }

  ParsedInvoiceItem parseInvoiceItem(String transcript) {
    final normalized = transcript.toLowerCase().trim();

    final qtyNameMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:kg|g|l|ml|pcs|pieces)?\s*([a-z\u0900-\u097F\u0C00-\u0C7F]+)',
    ).firstMatch(normalized);

    final priceMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:rupay|rupaya|rupees|rs|₹)',
    ).firstMatch(normalized);

    final quantity = qtyNameMatch != null ? double.tryParse(qtyNameMatch.group(1)!) : null;
    final name = qtyNameMatch?.group(2)?.trim();
    final unitPrice = priceMatch != null ? double.tryParse(priceMatch.group(1)!) : null;

    return ParsedInvoiceItem(
      name: (name == null || name.isEmpty) ? null : name,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  Future<String?> _recordClip() async {
    if (!await _recorder.hasPermission()) return null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    final clipPath = await _tempClipPath();
    await _recorder.start(const RecordConfig(), path: clipPath);
    await Future.delayed(_clipDuration);
    final recordedPath = await _recorder.stop();
    if (recordedPath == null) return null;

    final file = File(recordedPath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    unawaited(file.delete());

    return base64Encode(bytes);
  }

  Future<String> _tempClipPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/voice_clip_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _hapticSuccess() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 80);
    }
  }

  Future<bool> shouldShowGreetingToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGreetingDate = prefs.getString('last_greeting_date');
    final today = DateTime.now().toIso8601String().split('T')[0];
    return lastGreetingDate != today;
  }

  Future<void> markGreetingShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_greeting_date', today);
  }

  void stopSpeaking() {
    // No-op
  }

  Future<void> initialize() async {
    // No-op
  }
}