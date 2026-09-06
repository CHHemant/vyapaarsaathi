// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'వ్యాపార సాథి AI';

  @override
  String homeGreeting(String name) {
    return 'నమస్కారం, $name!';
  }

  @override
  String get todaySummary => 'ఈ రోజు సారాంశం';

  @override
  String get income => 'ఆదాయం';

  @override
  String get expenses => 'ఖర్చులు';

  @override
  String get net => 'నికర';

  @override
  String get captureTransaction => 'లావాదేవీ క్యాప్చర్ చేయండి';

  @override
  String get viewCreditScore => 'క్రెడిట్ స్కోర్ చూడండి';

  @override
  String get generateBill => 'బిల్లు తయారు చేయండి';

  @override
  String get creditScore => 'క్రెడిట్ స్కోర్';

  @override
  String get loanEligibility => 'రుణ అర్హత';

  @override
  String get loanEligibilityHigh => 'అధికం - ₹50,000 వరకు';

  @override
  String get loanEligibilityMedium => 'మధ్యస్థం - ₹15,000 వరకు';

  @override
  String get loanEligibilityLow => 'తక్కువ - ₹5,000 వరకు';

  @override
  String get downloadCreditReport => 'క్రెడిట్ రిపోర్ట్ డౌన్‌లోడ్ చేయండి';

  @override
  String get consistency => 'స్థిరత్వం';

  @override
  String get diversity => 'వైవిధ్యం';

  @override
  String get avgIncome => 'సగటు ఆదాయం';

  @override
  String get lowScoreTip =>
      'రెగ్యులర్ ట్రాన్సాక్షన్లు వేయండి, స్కోర్ పెంచుకోండి!';

  @override
  String get generateInvoice => 'బిల్లు తయారు చేయండి';

  @override
  String get gstInvoiceTitle => 'జీఎస్టీ ఇన్వాయిస్';

  @override
  String get customerNameOptional => 'కస్టమర్ పేరు (ఐచ్ఛికం)';

  @override
  String get customerPhoneLabel => 'కస్టమర్ ఫోన్ నంబర్ (జీఎస్టీ రికార్డ్ కోసం)';

  @override
  String get addItemByVoice => 'వాయిస్ ద్వారా ఐటమ్ జోడించండి';

  @override
  String get subtotal => 'ఉప మొత్తం';

  @override
  String get gst => 'జీఎస్టీ';

  @override
  String get total => 'మొత్తం';

  @override
  String get sendViaOfficeKit => 'ఆఫీస్ కిట్ ద్వారా పంపండి';

  @override
  String get backToEdit => 'ఎడిట్‌కి తిరిగి వెళ్ళండి';

  @override
  String get cashFlowHeatmap => 'నగదు ప్రవాహం';

  @override
  String get mirrorToLaptop => 'ల్యాప్‌టాప్‌కి మిర్రర్ చేయండి';

  @override
  String get stopMirroring => 'మిర్రరింగ్ ఆపండి';

  @override
  String get exportHeatmap => 'ఎగుమతి చేయండి';

  @override
  String get bestDay => 'ఉత్తమ రోజు';

  @override
  String get worstDay => 'అత్యల్ప రోజు';

  @override
  String get trend => 'ధోరణి';

  @override
  String get notEnoughData => 'తగినంత డేటా లేదు';

  @override
  String get noTransactionsToday => 'ఇంకా ట్రాన్సాక్షన్లు లేదు';

  @override
  String get workingOffline => 'ఆఫ్‌లైన్‌లో పని చేస్తోంది';

  @override
  String lastUpdated(String time) {
    return 'చివరిసారి అప్‌డేట్: $time';
  }

  @override
  String get verifyManually => 'మాన్యువల్‌గా వెరిఫై చేయాలా?';

  @override
  String get networkSlowRetry => 'నెట్‌వర్క్ నెమ్మది, మళ్ళీ ప్రయత్నించాలా?';

  @override
  String get retry => 'మళ్ళీ ప్రయత్నించండి';

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get confirm => 'నిర్ధారించండి';

  @override
  String get retake => 'మళ్ళీ తీయండి';

  @override
  String get success => 'లావాదేవీ సేవ్ అయింది!';

  @override
  String get error => 'ఏదో తప్పు జరిగింది';

  @override
  String dayStreak(int count) {
    return '$count-రోజుల స్ట్రీక్!';
  }

  @override
  String get proVyapari => 'ప్రో వ్యాపారి';
}
