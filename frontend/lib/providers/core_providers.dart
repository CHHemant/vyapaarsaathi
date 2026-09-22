// frontend/lib/providers/core_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_api_service.dart';
import '../services/cache_service.dart';
import '../services/voice_service.dart';
import '../services/office_kit_service.dart';

/// Provides singleton instance of LocalApiService.
/// All API calls go through this for offline-first experience.
final apiServiceProvider =
    Provider<LocalApiService>((ref) => LocalApiService());

/// Provides singleton instance of CacheService.
/// Handles local Hive database operations.
final cacheServiceProvider = Provider<CacheService>((ref) => CacheService());

/// Provides singleton instance of VoiceService.
/// Depends on LocalApiService for audio transcription.
final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService(apiService: ref.read(apiServiceProvider));
});

/// Provides singleton instance of OfficeKitService.
/// iQOO Hackathon 2026 SDK integration.
final officeKitServiceProvider =
    Provider<OfficeKitService>((ref) => OfficeKitService());

/// Provides combined app state for quick access.
/// Use this in widgets that need multiple services.
final appServicesProvider = Provider<AppServices>((ref) {
  return AppServices(
    api: ref.watch(apiServiceProvider),
    cache: ref.watch(cacheServiceProvider),
    voice: ref.watch(voiceServiceProvider),
    officeKit: ref.watch(officeKitServiceProvider),
  );
});

/// Combined app services for convenience.
class AppServices {
  final LocalApiService api;
  final CacheService cache;
  final VoiceService voice;
  final OfficeKitService officeKit;

  AppServices({
    required this.api,
    required this.cache,
    required this.voice,
    required this.officeKit,
  });
}

/// Provider for app initialization state.
final appInitializationProvider =
    FutureProvider<AppInitializationState>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final cache = ref.watch(cacheServiceProvider);

  try {
    // Initialize cache
    await cache.initialize();

    // Pre-load essential data
    await api.getHeatmap(days: 1);

    return AppInitializationState(
      isSuccess: true,
      message: 'App initialized successfully',
    );
  } catch (e) {
    return AppInitializationState(
      isSuccess: false,
      message: 'Initialization error: $e',
    );
  }
});

/// State of app initialization.
class AppInitializationState {
  final bool isSuccess;
  final String message;

  const AppInitializationState({
    required this.isSuccess,
    required this.message,
  });
}

/// Provider for offline mode status.
final offlineModeProvider = Provider<bool>((ref) {
  // Always true for offline-first app
  return true;
});

/// Provider for sync status.
final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatusState>(
  (ref) => SyncStatusNotifier(),
);

/// Notifier for sync status.
class SyncStatusNotifier extends StateNotifier<SyncStatusState> {
  SyncStatusNotifier() : super(const SyncStatusState());

  Future<void> checkSyncStatus() async {
    state = const SyncStatusState(
      isSyncing: false,
      lastSyncTime: null,
      pendingTransactions: 0,
    );
  }

  Future<void> startSync() async {
    state = state.copyWith(isSyncing: true);
    // Sync logic here
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isSyncing: false,
      lastSyncTime: DateTime.now(),
    );
  }
}

/// State for sync status.
class SyncStatusState {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingTransactions;

  const SyncStatusState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingTransactions = 0,
  });

  SyncStatusState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingTransactions,
  }) {
    return SyncStatusState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
    );
  }
}
