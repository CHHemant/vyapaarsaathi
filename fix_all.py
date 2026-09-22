import os

files = [
    "frontend/lib/main.dart",
    "frontend/lib/screens/auth/login_screen.dart",
    "frontend/lib/screens/auth/onboarding_screen.dart",
    "frontend/lib/screens/dashboard/dashboard_screen.dart",
    "frontend/lib/screens/invoices/invoice_list_screen.dart",
    "frontend/lib/screens/invoices/create_invoice_screen.dart",
    "frontend/lib/screens/invoices/invoice_preview_screen.dart",
    "frontend/lib/screens/khata/party_ledger_screen.dart",
    "frontend/lib/screens/payments/payment_link_screen.dart",
    "frontend/lib/screens/payments/vpa_qr_screen.dart",
    "frontend/lib/screens/payments/standee_export_modal.dart",
    "frontend/lib/screens/voice_ai/voice_assistant_screen.dart",
    "frontend/lib/screens/camera/passive_camera_screen.dart",
    "frontend/lib/screens/dispatch/daily_dispatch_screen.dart",
    "frontend/lib/screens/hardware/office_kit_screen.dart",
    "frontend/lib/screens/settings/settings_screen.dart",
    "frontend/lib/screens/settings/bank_accounts_screen.dart",
    "frontend/lib/screens/heatmap_screen.dart"
]

replacements = {
    "GoogleFonts.jetbrainsMono": "GoogleFonts.jetBrainsMono",
    "Icons.sync_saved_locally_rounded": "Icons.cloud_done_rounded",
    "Icons.routine_rounded": "Icons.schedule_rounded",
    "shadows:": "boxShadow:",
    "Colors.stone": "Colors.grey",
    "Colors.emerald": "Colors.green",
    "Colors.skyBlue": "Colors.lightBlue",
}

for file_path in files:
    if not os.path.exists(file_path):
        print(f"Skipping {file_path}, not found.")
        continue

    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)

    if new_content != content:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print(f"Fixed {file_path}")
    else:
        print(f"No changes needed for {file_path}")
