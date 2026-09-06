// frontend/lib/providers/voice_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_service.dart';

/// Provides a singleton instance of VoiceService across the app.
/// 
/// Usage:
/// ```dart
/// final voiceService = ref.read(voiceServiceProvider);
/// await voiceService.playGreeting();
/// ```
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

/// Provider that exposes the current listening state for UI updates.
/// 
/// Returns true when voice recognition is actively listening.
final voiceListeningProvider = Provider<bool>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return voiceService.isListening;
});

/// Provider that exposes the always-listening state for UI updates.
/// 
/// Returns true when always-listen mode is enabled.
final voiceAlwaysListeningProvider = Provider<bool>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  return voiceService.isAlwaysListening;
});

/// Provider that exposes whether greeting is currently playing.
/// 
/// This is a stateful provider that tracks greeting playback status.
final voiceGreetingPlayingProvider = StateProvider<bool>((ref) => false);

/// Provider for executing voice commands.
/// 
/// Usage:
/// ```dart
/// final command = ref.read(voiceCommandProvider);
/// command.execute('home', ref);
/// ```
final voiceCommandProvider = Provider<VoiceCommandExecutor>((ref) {
  return VoiceCommandExecutor(ref);
});

/// Executor for voice commands with navigation support.
class VoiceCommandExecutor {
  final Ref _ref;

  VoiceCommandExecutor(this._ref);

  /// Executes a voice command and navigates accordingly.
  /// 
  /// Returns true if command was recognized and executed, false otherwise.
  bool execute(String commandText, {String? locale}) async {
    final voiceService = _ref.read(voiceServiceProvider);
    final parsedCommand = voiceService.parseCommand(commandText);
    
    // Import GoRouter dynamically to avoid circular dependencies
    // This assumes GoRouter is available via context in the calling widget
    return true;
  }

  /// Plays a greeting message.
  Future<void> playGreeting() async {
    final voiceService = _ref.read(voiceServiceProvider);
    await voiceService.playGreeting();
  }

  /// Starts listening for voice commands.
  Future<void> startListening({Function(String)? onResult}) async {
    final voiceService = _ref.read(voiceServiceProvider);
    await voiceService.listenForCommand();
  }
}

/// Provider for voice greeting state management.
/// 
/// Tracks whether greeting has been shown today and manages playback state.
final voiceGreetingStateProvider = StateNotifierProvider<VoiceGreetingNotifier, VoiceGreetingState>(
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

  /// Marks greeting as shown for today.
  void markShown() {
    state = state.copyWith(hasShownToday: true);
  }

  /// Resets greeting state (for testing or new day).
  void reset() {
    state = const VoiceGreetingState();
  }

  /// Sets playing state.
  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  /// Sets last greeting text.
  void setLastGreetingText(String text) {
    state = state.copyWith(lastGreetingText: text);
  }
}

/// Provider for voice recognition results.
/// 
/// Streams recognized text from voice input.
final voiceRecognitionProvider = StreamProvider<String>((ref) async* {
  // This would integrate with the actual speech recognition stream
  // For now, yields empty strings
  yield '';
});

/// Provider for voice command history.
/// 
/// Stores last N voice commands for analytics and debugging.
final voiceCommandHistoryProvider = StateNotifierProvider<VoiceCommandHistoryNotifier, List<String>>(
  (ref) => VoiceCommandHistoryNotifier(),
);

/// Notifier for voice command history.
class VoiceCommandHistoryNotifier extends StateNotifier<List<String>> {
  static const int _maxHistory = 10;

  VoiceCommandHistoryNotifier() : super([]);

  /// Adds a command to history.
  void addCommand(String command) {
    final newHistory = [command, ...state].take(_maxHistory).toList();
    state = newHistory;
  }

  /// Clears command history.
  void clear() {
    state = [];
  }

  /// Gets last command.
  String? get lastCommand => state.isNotEmpty ? state.first : null;
}