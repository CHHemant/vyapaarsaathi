import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('te')
  ];

  /// App name shown in OS task switcher / title bar
  ///
  /// In en, this message translates to:
  /// **'VyapaarSaathi AI'**
  String get appTitle;

  /// Home dashboard greeting
  ///
  /// In en, this message translates to:
  /// **'Namaste, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @todaySummary.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Summary'**
  String get todaySummary;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @captureTransaction.
  ///
  /// In en, this message translates to:
  /// **'Capture Transaction'**
  String get captureTransaction;

  /// No description provided for @viewCreditScore.
  ///
  /// In en, this message translates to:
  /// **'View Credit Score'**
  String get viewCreditScore;

  /// No description provided for @generateBill.
  ///
  /// In en, this message translates to:
  /// **'Generate Bill'**
  String get generateBill;

  /// No description provided for @creditScore.
  ///
  /// In en, this message translates to:
  /// **'Credit Score'**
  String get creditScore;

  /// No description provided for @loanEligibility.
  ///
  /// In en, this message translates to:
  /// **'Loan Eligibility'**
  String get loanEligibility;

  /// No description provided for @loanEligibilityHigh.
  ///
  /// In en, this message translates to:
  /// **'High - Up to ₹50,000'**
  String get loanEligibilityHigh;

  /// No description provided for @loanEligibilityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium - Up to ₹15,000'**
  String get loanEligibilityMedium;

  /// No description provided for @loanEligibilityLow.
  ///
  /// In en, this message translates to:
  /// **'Low - Up to ₹5,000'**
  String get loanEligibilityLow;

  /// No description provided for @downloadCreditReport.
  ///
  /// In en, this message translates to:
  /// **'Download Credit Report'**
  String get downloadCreditReport;

  /// No description provided for @consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get consistency;

  /// No description provided for @diversity.
  ///
  /// In en, this message translates to:
  /// **'Diversity'**
  String get diversity;

  /// No description provided for @avgIncome.
  ///
  /// In en, this message translates to:
  /// **'Avg Income'**
  String get avgIncome;

  /// No description provided for @lowScoreTip.
  ///
  /// In en, this message translates to:
  /// **'Regular transactions veyandi, score penchukondi!'**
  String get lowScoreTip;

  /// No description provided for @generateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Generate Bill'**
  String get generateInvoice;

  /// No description provided for @gstInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'GST Invoice'**
  String get gstInvoiceTitle;

  /// No description provided for @customerNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer name (optional)'**
  String get customerNameOptional;

  /// No description provided for @customerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer phone (for GST record)'**
  String get customerPhoneLabel;

  /// No description provided for @addItemByVoice.
  ///
  /// In en, this message translates to:
  /// **'Add item by voice'**
  String get addItemByVoice;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @gst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get gst;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @sendViaOfficeKit.
  ///
  /// In en, this message translates to:
  /// **'Send via Office Kit'**
  String get sendViaOfficeKit;

  /// No description provided for @backToEdit.
  ///
  /// In en, this message translates to:
  /// **'Back to Edit'**
  String get backToEdit;

  /// No description provided for @cashFlowHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cashFlowHeatmap;

  /// No description provided for @mirrorToLaptop.
  ///
  /// In en, this message translates to:
  /// **'Mirror to Laptop'**
  String get mirrorToLaptop;

  /// No description provided for @stopMirroring.
  ///
  /// In en, this message translates to:
  /// **'Stop Mirroring'**
  String get stopMirroring;

  /// No description provided for @exportHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportHeatmap;

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get bestDay;

  /// No description provided for @worstDay.
  ///
  /// In en, this message translates to:
  /// **'Worst Day'**
  String get worstDay;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get notEnoughData;

  /// No description provided for @noTransactionsToday.
  ///
  /// In en, this message translates to:
  /// **'Inka transactions ledu'**
  String get noTransactionsToday;

  /// No description provided for @workingOffline.
  ///
  /// In en, this message translates to:
  /// **'Working offline'**
  String get workingOffline;

  /// Cached-data badge timestamp
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdated(String time);

  /// No description provided for @verifyManually.
  ///
  /// In en, this message translates to:
  /// **'Verify manually?'**
  String get verifyManually;

  /// No description provided for @networkSlowRetry.
  ///
  /// In en, this message translates to:
  /// **'Network slow, retry?'**
  String get networkSlowRetry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved!'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// Home streak counter
  ///
  /// In en, this message translates to:
  /// **'{count}-day streak!'**
  String dayStreak(int count);

  /// No description provided for @proVyapari.
  ///
  /// In en, this message translates to:
  /// **'Pro Vyapari'**
  String get proVyapari;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
