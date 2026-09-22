// frontend/lib/providers/voice_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_api_service.dart';
import '../services/voice_service.dart';

/// Provides a singleton instance of LocalApiService.
final localApiServiceProvider = Provider<LocalApiService>((ref) {
  return LocalApiService();
});

/// Provides a singleton instance of VoiceService across the app.
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final apiService = ref.read(localApiServiceProvider);

  return VoiceService(
    apiService: apiService,
  );
});

/// Provider that exposes the current listening state.
final voiceListeningProvider = Provider<bool>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return voiceService.isListening;
});

/// Provider that exposes the always-listening state.
final voiceAlwaysListeningProvider = Provider<bool>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return voiceService.isAlwaysListening;
});

/// Tracks whether the greeting is currently playing.
final voiceGreetingPlayingProvider = StateProvider<bool>((ref) => false);

/// Provider for executing voice commands.
final voiceCommandProvider = Provider<VoiceCommandExecutor>((ref) {
  return VoiceCommandExecutor(ref);
});

/// Executor for voice commands.
class VoiceCommandExecutor {
  final Ref _ref;

  VoiceCommandExecutor(this._ref);

  /// Parses a voice command.
  ///
  /// Returns true when a recognized command was detected.
  bool execute(String commandText, {String? locale}) {
    final voiceService = _ref.read(voiceServiceProvider);
    final parsedCommand = voiceService.parseCommand(commandText);

    return parsedCommand is! UnrecognizedCommand;
  }

  /// Plays a greeting message.
  Future<void> playGreeting() async {
    final voiceService = _ref.read(voiceServiceProvider);
    await voiceService.playGreeting();
  }

  /// Starts listening for a voice command.
  Future<void> startListening({Function(String)? onResult}) async {
    final voiceService = _ref.read(voiceServiceProvider);
    final command = await voiceService.listenForCommand();

    if (command is UnrecognizedCommand) {
      onResult?.call('');
      return;
    }

    onResult?.call(command.runtimeType.toString());
  }
}

/// Provider for voice greeting state.
final voiceGreetingStateProvider =
    StateNotifierProvider<VoiceGreetingNotifier, VoiceGreetingState>(
  (ref) => VoiceGreetingNotifier(),
);

/// State for voice greeting.
class VoiceGreetingState {
  final bool hasShownToday;
  final bool isPlaying;
  final String? lastGreetingText;

  const VoiceGreetingState({
    this.hasShownToday = false,
    this.isPlaying = false,
    this.lastGreetingText,
  });

  VoiceGreetingState copyWith({
    bool? hasShownToday,
    bool? isPlaying,
    String? lastGreetingText,
  }) {
    return VoiceGreetingState(
      hasShownToday: hasShownToday ?? this.hasShownToday,
      isPlaying: isPlaying ?? this.isPlaying,
      lastGreetingText: lastGreetingText ?? this.lastGreetingText,
    );
  }
}

/// Notifier for voice greeting state.
class VoiceGreetingNotifier extends StateNotifier<VoiceGreetingState> {
  VoiceGreetingNotifier() : super(const VoiceGreetingState());

  void markShown() {
    state = state.copyWith(hasShownToday: true);
  }

  void reset() {
    state = const VoiceGreetingState();
  }

  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setLastGreetingText(String text) {
    state = state.copyWith(lastGreetingText: text);
  }
}

/// Provider for voice recognition results.
final voiceRecognitionProvider = StreamProvider<String>((ref) async* {
  yield '';
});

/// Provider for voice command history.
final voiceCommandHistoryProvider =
    StateNotifierProvider<VoiceCommandHistoryNotifier, List<String>>(
  (ref) => VoiceCommandHistoryNotifier(),
);

/// Notifier for voice command history.
class VoiceCommandHistoryNotifier extends StateNotifier<List<String>> {
  static const int _maxHistory = 10;

  VoiceCommandHistoryNotifier() : super([]);

  void addCommand(String command) {
    final newHistory = [command, ...state].take(_maxHistory).toList();
    state = newHistory;
  }

  void clear() {
    state = [];
  }

  String? get lastCommand => state.isNotEmpty ? state.first : null;
}
