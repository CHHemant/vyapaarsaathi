library office_kit_sdk;

// Stub SDK for iQOO Hackathon 2026

class OfficeKit {
  static Future<bool> isConnected() async => false;
  static Future<void> startMirror({
    String? sessionId,
    int? width,
    int? height,
    bool? presentationMode,
  }) async {}
  static Future<void> stopMirror() async {}
  static Future<void> sendFile({
    String? filePath,
    String? sessionId,
    dynamic destination,
    String? sourcePath,
  }) async {}
}

class OfficeKitDestination {
  static const downloads = 'downloads';
}