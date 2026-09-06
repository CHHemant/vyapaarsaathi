// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VyapaarSaathi AI';

  @override
  String homeGreeting(String name) {
    return 'Namaste, $name!';
  }

  @override
  String get todaySummary => 'Today\'s Summary';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get net => 'Net';

  @override
  String get captureTransaction => 'Capture Transaction';

  @override
  String get viewCreditScore => 'View Credit Score';

  @override
  String get generateBill => 'Generate Bill';

  @override
  String get creditScore => 'Credit Score';

  @override
  String get loanEligibility => 'Loan Eligibility';

  @override
  String get loanEligibilityHigh => 'High - Up to ₹50,000';

  @override
  String get loanEligibilityMedium => 'Medium - Up to ₹15,000';

  @override
  String get loanEligibilityLow => 'Low - Up to ₹5,000';

  @override
  String get downloadCreditReport => 'Download Credit Report';

  @override
  String get consistency => 'Consistency';

  @override
  String get diversity => 'Diversity';

  @override
  String get avgIncome => 'Avg Income';

  @override
  String get lowScoreTip => 'Regular transactions veyandi, score penchukondi!';

  @override
  String get generateInvoice => 'Generate Bill';

  @override
  String get gstInvoiceTitle => 'GST Invoice';

  @override
  String get customerNameOptional => 'Customer name (optional)';

  @override
  String get customerPhoneLabel => 'Customer phone (for GST record)';

  @override
  String get addItemByVoice => 'Add item by voice';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get gst => 'GST';

  @override
  String get total => 'Total';

  @override
  String get sendViaOfficeKit => 'Send via Office Kit';

  @override
  String get backToEdit => 'Back to Edit';

  @override
  String get cashFlowHeatmap => 'Cash Flow';

  @override
  String get mirrorToLaptop => 'Mirror to Laptop';

  @override
  String get stopMirroring => 'Stop Mirroring';

  @override
  String get exportHeatmap => 'Export';

  @override
  String get bestDay => 'Best Day';

  @override
  String get worstDay => 'Worst Day';

  @override
  String get trend => 'Trend';

  @override
  String get notEnoughData => 'Not enough data';

  @override
  String get noTransactionsToday => 'Inka transactions ledu';

  @override
  String get workingOffline => 'Working offline';

  @override
  String lastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get verifyManually => 'Verify manually?';

  @override
  String get networkSlowRetry => 'Network slow, retry?';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get retake => 'Retake';

  @override
  String get success => 'Transaction saved!';

  @override
  String get error => 'Something went wrong';

  @override
  String dayStreak(int count) {
    return '$count-day streak!';
  }

  @override
  String get proVyapari => 'Pro Vyapari';
}
