// frontend/lib/services/local_speech_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

/// Fully offline, on-device speech-to-text service.
///
/// Model:
///   sherpa-onnx-dolphin-base-ctc-multi-lang-int8-2025-04-02
///
/// Runtime configuration:
///   - CPU inference
///   - 2 inference threads
///   - 16 kHz audio
///   - 80-dimensional features
///   - Greedy decoding
///
/// The model and tokenizer are bundled with the application and copied to
/// the application's support directory on first use.
///
/// No HTTP request or Internet connection is required for transcription.
class LocalSpeechService {
  // ---------------------------------------------------------------------------
  // Bundled Flutter assets
  // ---------------------------------------------------------------------------

  static const String _modelAsset = 'assets/asr/dolphin/model.int8.onnx';

  static const String _tokensAsset = 'assets/asr/dolphin/tokens.txt';

  // ---------------------------------------------------------------------------
  // ASR configuration
  // ---------------------------------------------------------------------------

  static const int _sampleRate = 16000;
  static const int _featureDim = 80;

  // Two CPU threads provide a reasonable balance between performance and
  // memory/CPU usage on the target low-RAM Android device.
  static const int _numThreads = 2;

  // Minimum model size used to detect an incomplete/corrupt extraction.
  static const int _minimumModelSizeBytes = 50 * 1024 * 1024;

  // ---------------------------------------------------------------------------
  // Runtime state
  // ---------------------------------------------------------------------------

  sherpa_onnx.OfflineRecognizer? _recognizer;

  bool _initialized = false;
  bool _initializing = false;

  /// Returns true when the local ASR recognizer is ready.
  bool get isInitialized => _initialized && _recognizer != null;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the local Dolphin ASR recognizer.
  ///
  /// This method is safe to call multiple times. If initialization is already
  /// in progress, subsequent calls wait for the existing initialization.
  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(
          const Duration(milliseconds: 50),
        );
      }

      if (!isInitialized) {
        throw StateError(
          'Local speech initialization failed.',
        );
      }

      return;
    }

    _initializing = true;

    try {
      debugPrint(
        '[LocalSpeech] Initializing offline ASR...',
      );

      // Initialize sherpa-onnx native bindings.
      sherpa_onnx.initBindings();

      // ---------------------------------------------------------------------
      // Prepare application support directory
      // ---------------------------------------------------------------------

      final applicationDirectory = await getApplicationSupportDirectory();

      final modelDirectory = Directory(
        '${applicationDirectory.path}/asr/dolphin',
      );

      if (!await modelDirectory.exists()) {
        await modelDirectory.create(
          recursive: true,
        );
      }

      final modelPath = '${modelDirectory.path}/model.int8.onnx';

      final tokensPath = '${modelDirectory.path}/tokens.txt';

      // ---------------------------------------------------------------------
      // Extract bundled model files
      // ---------------------------------------------------------------------

      await _copyAssetIfNeeded(
        assetPath: _modelAsset,
        outputPath: modelPath,
        minimumValidSize: _minimumModelSizeBytes,
      );

      await _copyAssetIfNeeded(
        assetPath: _tokensAsset,
        outputPath: tokensPath,
        minimumValidSize: 100,
      );

      // ---------------------------------------------------------------------
      // Validate model files
      // ---------------------------------------------------------------------

      final modelFile = File(modelPath);
      final tokensFile = File(tokensPath);

      if (!await modelFile.exists()) {
        throw StateError(
          'Offline ASR model file does not exist:\n$modelPath',
        );
      }

      if (!await tokensFile.exists()) {
        throw StateError(
          'Offline ASR token file does not exist:\n$tokensPath',
        );
      }

      final modelSize = await modelFile.length();
      final tokensSize = await tokensFile.length();

      if (modelSize < _minimumModelSizeBytes) {
        throw StateError(
          'Offline ASR model appears incomplete. '
          'Expected at least $_minimumModelSizeBytes bytes, '
          'but found $modelSize bytes.',
        );
      }

      if (tokensSize < 100) {
        throw StateError(
          'Offline ASR token file appears incomplete. '
          'Found only $tokensSize bytes.',
        );
      }

      debugPrint(
        '[LocalSpeech] Model size: $modelSize bytes',
      );

      debugPrint(
        '[LocalSpeech] Tokens size: $tokensSize bytes',
      );

      // ---------------------------------------------------------------------
      // Configure Dolphin model
      // ---------------------------------------------------------------------

      final dolphinConfig = sherpa_onnx.OfflineDolphinModelConfig(
        model: modelPath,
      );

      final modelConfig = sherpa_onnx.OfflineModelConfig(
        dolphin: dolphinConfig,
        tokens: tokensPath,
        numThreads: _numThreads,
        debug: false,
        provider: 'cpu',
      );

      // ---------------------------------------------------------------------
      // Configure audio features
      // ---------------------------------------------------------------------

      const featureConfig = sherpa_onnx.FeatureConfig(
        sampleRate: _sampleRate,
        featureDim: _featureDim,
      );

      final recognizerConfig = sherpa_onnx.OfflineRecognizerConfig(
        feat: featureConfig,
        model: modelConfig,
        decodingMethod: 'greedy_search',
      );

      // ---------------------------------------------------------------------
      // Create recognizer
      // ---------------------------------------------------------------------

      final recognizer = sherpa_onnx.OfflineRecognizer(
        recognizerConfig,
      );

      _recognizer = recognizer;
      _initialized = true;

      debugPrint(
        '[LocalSpeech] Offline ASR ready.',
      );

      debugPrint(
        '[LocalSpeech] Configuration: '
        'CPU / $_numThreads threads / '
        '$_sampleRate Hz / '
        '$_featureDim features / '
        'greedy decoding',
      );
    } catch (error, stackTrace) {
      _initialized = false;

      // Prevent a partially initialized native recognizer from remaining alive.
      _recognizer?.free();
      _recognizer = null;

      debugPrint(
        '[LocalSpeech] Initialization failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      _initializing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Transcription
  // ---------------------------------------------------------------------------

  /// Transcribes a local WAV file completely offline.
  ///
  /// Returns the recognized text, or null if:
  ///   - the WAV file does not exist,
  ///   - the WAV contains no samples,
  ///   - the file is too small,
  ///   - recognition produces no text, or
  ///   - transcription fails.
  Future<String?> transcribeFile(String wavPath) async {
    if (!isInitialized) {
      await initialize();
    }

    final file = File(wavPath);

    if (!await file.exists()) {
      debugPrint(
        '[LocalSpeech] WAV file does not exist: $wavPath',
      );

      return null;
    }

    final fileSize = await file.length();

    if (fileSize < 1000) {
      debugPrint(
        '[LocalSpeech] WAV file is too small: '
        '$fileSize bytes',
      );

      return null;
    }

    try {
      // Read the local WAV file using sherpa-onnx.
      final waveData = sherpa_onnx.readWave(wavPath);

      if (waveData.samples.isEmpty) {
        debugPrint(
          '[LocalSpeech] WAV contains no audio samples.',
        );

        return null;
      }

      debugPrint(
        '[LocalSpeech] Decoding '
        '${waveData.samples.length} samples '
        'at ${waveData.sampleRate} Hz...',
      );

      // VoiceService records at 16 kHz. Keep this check so an incorrect
      // recording configuration is visible during device testing.
      if (waveData.sampleRate != _sampleRate) {
        debugPrint(
          '[LocalSpeech] Warning: expected '
          '$_sampleRate Hz audio but received '
          '${waveData.sampleRate} Hz.',
        );
      }

      final recognizer = _recognizer!;

      final stream = recognizer.createStream();

      try {
        stream.acceptWaveform(
          samples: waveData.samples,
          sampleRate: waveData.sampleRate,
        );

        recognizer.decode(stream);

        final result = recognizer.getResult(stream);

        final text = result.text.trim();

        if (text.isEmpty) {
          debugPrint(
            '[LocalSpeech] No speech recognized.',
          );

          return null;
        }

        debugPrint(
          '[LocalSpeech] Transcript: $text',
        );

        return text;
      } finally {
        stream.free();
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[LocalSpeech] Transcription failed: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Asset extraction
  // ---------------------------------------------------------------------------

  /// Copies a bundled Flutter asset to the application's support directory
  /// when the existing copy is missing or appears incomplete.
  Future<void> _copyAssetIfNeeded({
    required String assetPath,
    required String outputPath,
    required int minimumValidSize,
  }) async {
    final outputFile = File(outputPath);

    // Reuse a valid existing copy instead of extracting the ~99 MB model
    // every time the service starts.
    if (await outputFile.exists()) {
      final existingSize = await outputFile.length();

      if (existingSize >= minimumValidSize) {
        debugPrint(
          '[LocalSpeech] Using existing file: $outputPath',
        );

        return;
      }

      debugPrint(
        '[LocalSpeech] Existing file appears incomplete. '
        'Re-extracting: $outputPath',
      );

      try {
        await outputFile.delete();
      } catch (error) {
        debugPrint(
          '[LocalSpeech] Could not delete incomplete file: '
          '$error',
        );
      }
    }

    debugPrint(
      '[LocalSpeech] Extracting asset: $assetPath',
    );

    final data = await rootBundle.load(assetPath);

    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    if (bytes.length < minimumValidSize) {
      throw StateError(
        'Bundled asset appears incomplete: '
        '$assetPath (${bytes.length} bytes).',
      );
    }

    await outputFile.parent.create(
      recursive: true,
    );

    await outputFile.writeAsBytes(
      bytes,
      flush: true,
    );

    debugPrint(
      '[LocalSpeech] Extracted '
      '${bytes.length} bytes to $outputPath',
    );
  }

  // ---------------------------------------------------------------------------
  // Disposal
  // ---------------------------------------------------------------------------

  /// Releases the native sherpa-onnx recognizer.
  Future<void> dispose() async {
    debugPrint(
      '[LocalSpeech] Disposing offline ASR...',
    );

    _recognizer?.free();

    _recognizer = null;
    _initialized = false;
    _initializing = false;

    debugPrint(
      '[LocalSpeech] Offline ASR disposed.',
    );
  }
}
