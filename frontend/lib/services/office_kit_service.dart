// frontend/lib/services/office_kit_service.dart
//
// Thin wrapper around the iQOO Hackathon 2026 Office Kit SDK (screen
// mirror + file transfer). This file exists specifically so that when
// you get the real SDK at the venue, the fix is contained to THIS file
// — every screen calls OfficeKitService's methods below, never the raw
// SDK package directly.
//
// HONESTY NOTE — READ BEFORE THE HACKATHON:
// The actual Office Kit SDK (package name, method signatures, whether
// it's callback-based or Future-based, what errors it throws) is not
// something I have access to — it's hackathon-provided and hasn't been
// handed out yet per the pubspec.yaml placeholder path dependency. The
// method bodies below call a package `office_kit_sdk` with a signature
// I've inferred from the spec's plain-English description ("mirror to
// laptop", "send PDF to laptop"), not from real SDK docs. Treat every
// call to `OfficeKit.*` in this file as a placeholder contract you MUST
// verify and likely rename against the real SDK once it's distributed —
// everything else here (permission checks, error surfacing, the
// interface screens code against) is real and won't need to change even
// if the underlying SDK calls do.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:office_kit_sdk/office_kit_sdk.dart' as sdk;

sealed class OfficeKitResult {
  const OfficeKitResult();
}

class OfficeKitSuccess extends OfficeKitResult {
  const OfficeKitSuccess();
}

class OfficeKitFailure extends OfficeKitResult {
  final String reason;
  const OfficeKitFailure(this.reason);
}

/// Whether the laptop-side companion app is currently paired/connected.
/// Screens should check this before offering "Mirror to Laptop" /
/// "Download Credit Report" so the button doesn't fail silently.
enum OfficeKitConnectionState { connected, disconnected, unknown }

class OfficeKitService {
  OfficeKitConnectionState _connectionState = OfficeKitConnectionState.unknown;
  OfficeKitConnectionState get connectionState => _connectionState;

  /// Call once at app startup (or when the user opens a screen that
  /// needs Office Kit) to establish/refresh pairing status. Cheap to
  /// call repeatedly — screens can re-check before every mirror/transfer
  /// attempt rather than trusting a stale cached state.
  Future<OfficeKitConnectionState> checkConnection() async {
    try {
      // ASSUMPTION: sdk.OfficeKit.isConnected() — verify against real SDK.
      final connected = await sdk.OfficeKit.isConnected();
      _connectionState =
          connected ? OfficeKitConnectionState.connected : OfficeKitConnectionState.disconnected;
    } catch (e) {
      debugPrint('[OfficeKitService] connection check failed: $e');
      _connectionState = OfficeKitConnectionState.unknown;
    }
    return _connectionState;
  }

  // ---------------------------------------------------------------------
  // Screen mirror
  // ---------------------------------------------------------------------

  /// Extends the app display to the paired laptop, optimized for
  /// 1920x1080 landscape per the spec (heatmap + credit dashboard demo
  /// views). Hides the app's own navigation chrome on the mirrored output
  /// where the SDK supports a "presentation mode" flag — screens using
  /// this should also proactively hide their own nav bar in-app so the
  /// primary phone display stays consistent with what's mirrored.
  Future<OfficeKitResult> mirrorToLaptop({
    int targetWidth = 1920,
    int targetHeight = 1080,
  }) async {
    if (_connectionState != OfficeKitConnectionState.connected) {
      await checkConnection();
    }
    if (_connectionState != OfficeKitConnectionState.connected) {
      return const OfficeKitFailure('Laptop not paired. Reconnect Office Kit and try again.');
    }

    try {
      // ASSUMPTION: sdk.OfficeKit.startMirror(width, height, mode) —
      // verify parameter names/order against the real SDK.
      await sdk.OfficeKit.startMirror(
        width: targetWidth,
        height: targetHeight,
        presentationMode: true,
      );
      return const OfficeKitSuccess();
    } catch (e) {
      debugPrint('[OfficeKitService] mirror failed: $e');
      return OfficeKitFailure('Could not start screen mirror: $e');
    }
  }

  Future<void> stopMirroring() async {
    try {
      // ASSUMPTION: sdk.OfficeKit.stopMirror()
      await sdk.OfficeKit.stopMirror();
    } catch (e) {
      debugPrint('[OfficeKitService] stop mirror failed (non-fatal): $e');
    }
  }

  // ---------------------------------------------------------------------
  // File transfer
  // ---------------------------------------------------------------------

  /// Sends a local file (credit report PDF, GST invoice PDF, exported
  /// heatmap PNG) to the paired laptop's Downloads folder.
  /// [localPath] must point to a file that already exists on-device —
  /// this method does not generate PDFs itself (see api_service's
  /// generateInvoice, which returns the backend-rendered pdf_path).
  Future<OfficeKitResult> transferFile(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      return OfficeKitFailure('File not found on device: $localPath');
    }

    if (_connectionState != OfficeKitConnectionState.connected) {
      await checkConnection();
    }
    if (_connectionState != OfficeKitConnectionState.connected) {
      return const OfficeKitFailure('Laptop not paired. Reconnect Office Kit and try again.');
    }

    try {
      // ASSUMPTION: sdk.OfficeKit.sendFile(path, destination) — verify
      // against the real SDK, including whether it wants a raw path,
      // a File object, or bytes.
      await sdk.OfficeKit.sendFile(
        sourcePath: localPath,
        destination: sdk.OfficeKitDestination.downloads,
      );
      return const OfficeKitSuccess();
    } catch (e) {
      debugPrint('[OfficeKitService] file transfer failed: $e');
      return OfficeKitFailure('Could not send file to laptop: $e');
    }
  }
}
