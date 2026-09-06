# VyapaarSaathi — Frontend

Zero-touch financial assistant for informal workers, built for iQOO
Hackathon 2026 (Hyderabad City Battle, Open Innovation Track). This is
the Flutter frontend; the backend (Python/FastAPI, localhost:8000) is
built separately.

---

## 1. Prerequisites

- Flutter 3.24+ / Dart 3.5+ (`flutter --version` to check)
- The backend running and reachable at `http://localhost:8000` — the
  app will not function without it (no cloud fallback, by design)
- An Android device (tested target: iQOO loaner phone, Snapdragon NPU,
  8GB RAM, 120Hz display) with USB debugging enabled, OR an emulator
  for UI-only testing (camera/voice features need a real device)
- The Office Kit SDK, distributed at the hackathon venue — see
  **Section 4** before assuming this "just works"

---

## 2. Setup

```bash
# From the frontend/ directory:
flutter pub get

# Generates AppLocalizations from lib/l10n/*.arb (also runs
# automatically on `flutter run` / `flutter build` since
# pubspec.yaml has `generate: true`, but running it explicitly
# first surfaces any .arb syntax errors early):
flutter gen-l10n

# Verify nothing's broken before you're on a clock at the venue:
flutter analyze
```

If `office_kit_sdk` fails to resolve during `pub get`: expected until
you have the real SDK — see Section 4.

### Backend must be running first

Start the FastAPI backend (`localhost:8000`) before launching the app.
Every screen except cached/offline views depends on it; there is no
seed/demo data baked into the frontend.

---

## 3. Running on the iQOO device

```bash
# Connect the device via USB, then:
flutter devices        # confirm the iQOO shows up
flutter run --release  # release mode matters for camera/animation perf on stage
```

If the device doesn't appear: check USB debugging is enabled
(Settings → About Phone → tap Build Number 7x → Developer Options →
USB Debugging), and that you've accepted the "Allow USB debugging?"
prompt on the device itself.

---

## 4. Office Kit pairing — READ THIS BEFORE THE DEMO

**`lib/services/office_kit_service.dart` was written against an
*assumed* API shape, not the real Office Kit SDK documentation** — the
SDK wasn't available at the time this codebase was generated. Every
`sdk.OfficeKit.*` call in that file is marked `// ASSUMPTION` in code.

**Do this the moment you have the real SDK, before wiring demo flows
around it:**

1. Open `lib/services/office_kit_service.dart`.
2. Compare `isConnected()`, `startMirror()`, `stopMirror()`, and
   `sendFile()` against the real SDK's actual method names/signatures.
3. Fix the ~4 call sites inside that one file. Nothing else in the app
   should need to change — every screen calls `OfficeKitService`, never
   the raw SDK package.
4. Pairing steps themselves (how the phone discovers/connects to the
   laptop) are entirely the SDK's responsibility and aren't something
   this README can document sight-unseen — follow whatever pairing
   flow the hackathon organizers hand out with the kit.

---

## 5. Architecture

```
lib/
  main.dart              # entry point, theme, GoRouter, Hive bootstrap
  models/                 # Transaction, Customer, CreditScore, Invoice, HeatmapData
  services/
    api_service.dart      # Dio client, 6 backend endpoints, retry/timeout
    cache_service.dart     # Hive offline-first cache layer + HiveBoxes
    voice_service.dart     # ASR command parsing, navigation, invoice voice input
    office_kit_service.dart # screen mirror + file transfer (SEE SECTION 4)
  providers/
    core_providers.dart    # shared Riverpod providers for all services
  theme/kirana_colors.dart # design system colors
  widgets/                 # KiranaCard, RupeeButton, CreditScoreGauge, etc.
  screens/                 # Home, Capture, Credit, Invoice, Heatmap
  l10n/                    # app_en.arb, app_hi.arb, app_te.arb
```

State management: Riverpod (`AsyncNotifier` per screen with a
cache-fallback `_fetch()` pattern — see `home_screen.dart` or
`credit_screen.dart` for the canonical shape).

---

## 6. Known limitations / not yet implemented

Being direct about these rather than letting them surface as surprises
during judging:

- **Camera capture shows a static alignment guide, not live AI
  detection.** The spec describes a real-time bounding box around
  detected UPI screens/cash — that needs an on-device TFLite model,
  which isn't in this dependency tree. What's shown is a scan-frame
  overlay to help framing, not live detection.

- **"Always-listen" voice mode is a polling approximation**, not true
  streaming wake-word detection (which needs a dedicated engine like
  Porcupine). It records ~3s clips back-to-back and checks each for the
  wake word — works for a demo, costs battery.

- **Customer search has no backing endpoint.** The 6-endpoint contract
  has no list/search-customers call. Autocomplete only surfaces
  customers already seen in a fetched transaction list this session.

- **Customer phone numbers are never cached in plaintext** (privacy
  choice — only a hash is stored), so even a known customer's phone
  must be typed manually on the invoice screen.

- **"Download Credit Report" actually calls the GST invoice
  endpoint** with a dummy line item — there's no dedicated
  report-generation endpoint in the given contract. The resulting PDF
  may look like an invoice, not a report, depending on how the backend
  renders it.

- **`transcribeAudio`'s response field name is guessed** (`transcript`
  or `text`) — unconfirmed against real backend behavior for
  audio-only capture calls.

- **Most screens' user-facing strings are still hardcoded English**,
  not wired to `AppLocalizations` — only the Home screen's greeting
  currently respects the selected locale. The `.arb` files define the
  full string set; the screen-level retrofit is outstanding.

- **`assets/lottie/` has no animation files** — the milestone
  celebration (credit score >70) has nowhere to point a Lottie player
  yet. Needs a real `.json` file added before that code path works.

- **JSON serialization is hand-written**, not `json_serializable`
  codegen, despite the package being a dev dependency — a deliberate
  call to avoid a `build_runner` failure point during a 30-hour build.
  Same reasoning for Hive: boxes store plain JSON maps, not generated
  `TypeAdapter`s.

- **`invoice.pdfPath` / credit report path is assumed to be a local
  on-device file path**, not a URL — consistent with the backend
  running on-device, but unconfirmed. If it's actually a URL, the PDF
  preview and Office Kit transfer both need adjusting.

---

## 7. Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `office_kit_sdk` not found during `pub get` | Real SDK not yet installed at the path dependency in `pubspec.yaml` — placeholder until venue distribution |
| Blank/red screen mentioning `AppLocalizations` | Run `flutter gen-l10n` (or just `flutter run`, which triggers it) |
| Camera screen stuck on permission-denied view | Camera/mic permission was denied — tap "Open Settings" and grant both manually |
| "Working offline" badge won't go away | Backend isn't running at `localhost:8000`, or device isn't on the Office Kit bridge network |
| Hindi/Telugu locale doesn't change most screen text | Known limitation — see Section 6, string wiring is incomplete outside Home's greeting |
| `flutter analyze` warnings on font weight declarations | Expected — see the variable-font note in `assets/fonts/ATTRIBUTION.md`; not a real error |

---

## 8. Credits

Fonts (Poppins, Noto Sans, Noto Sans Telugu, Noto Sans Devanagari,
Roboto Mono) are open-source under the SIL Open Font License — see
`assets/fonts/ATTRIBUTION.md` and `assets/fonts/OFL.txt`.

Built for iQOO Hackathon 2026 — Hyderabad City Battle.