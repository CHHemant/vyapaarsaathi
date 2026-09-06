# frontend/assets/fonts/ATTRIBUTION.md

All fonts in this folder are real, redistributable open-source font
files fetched directly from the official Google Fonts repository
(github.com/google/fonts), not placeholders.

| File | Font | License |
|---|---|---|
| Poppins-Regular.ttf, Poppins-SemiBold.ttf, Poppins-Bold.ttf | Poppins | SIL Open Font License 1.1 |
| NotoSans-Regular.ttf | Noto Sans (variable font, wdth/wght axes) | SIL Open Font License 1.1 |
| NotoSansTelugu-Regular.ttf | Noto Sans Telugu (variable font) | SIL Open Font License 1.1 |
| NotoSansDevanagari-Regular.ttf | Noto Sans Devanagari (variable font) | SIL Open Font License 1.1 |
| RobotoMono-Regular.ttf | Roboto Mono (variable font, wght axis) | SIL Open Font License 1.1 |

Full license text: `OFL.txt` in this folder (required to travel with
the fonts under the OFL's redistribution terms).

Note: NotoSans, NotoSansTelugu, NotoSansDevanagari, and RobotoMono are
**variable fonts** as distributed upstream — a single file spans the
weight range rather than separate static files per weight. pubspec.yaml
declares the Bold weight by pointing a second `weight: 700` entry at
the same file, which Flutter resolves to the matching named instance.
