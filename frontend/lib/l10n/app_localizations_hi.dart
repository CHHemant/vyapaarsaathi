// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'व्यापार साथी AI';

  @override
  String homeGreeting(String name) {
    return 'नमस्ते, $name!';
  }

  @override
  String get todaySummary => 'आज का सारांश';

  @override
  String get income => 'आमदनी';

  @override
  String get expenses => 'खर्च';

  @override
  String get net => 'शुद्ध';

  @override
  String get captureTransaction => 'लेनदेन कैप्चर करें';

  @override
  String get viewCreditScore => 'क्रेडिट स्कोर देखें';

  @override
  String get generateBill => 'बिल बनाएं';

  @override
  String get creditScore => 'क्रेडिट स्कोर';

  @override
  String get loanEligibility => 'लोन पात्रता';

  @override
  String get loanEligibilityHigh => 'उच्च - ₹50,000 तक';

  @override
  String get loanEligibilityMedium => 'मध्यम - ₹15,000 तक';

  @override
  String get loanEligibilityLow => 'कम - ₹5,000 तक';

  @override
  String get downloadCreditReport => 'क्रेडिट रिपोर्ट डाउनलोड करें';

  @override
  String get consistency => 'नियमितता';

  @override
  String get diversity => 'विविधता';

  @override
  String get avgIncome => 'औसत आमदनी';

  @override
  String get lowScoreTip => 'नियमित लेनदेन डालिए, स्कोर बढ़ाइए!';

  @override
  String get generateInvoice => 'बिल बनाएं';

  @override
  String get gstInvoiceTitle => 'जीएसटी इनवॉइस';

  @override
  String get customerNameOptional => 'ग्राहक का नाम (वैकल्पिक)';

  @override
  String get customerPhoneLabel =>
      'ग्राहक का फ़ोन नंबर (जीएसटी रिकॉर्ड के लिए)';

  @override
  String get addItemByVoice => 'आवाज़ से आइटम जोड़ें';

  @override
  String get subtotal => 'उप-योग';

  @override
  String get gst => 'जीएसटी';

  @override
  String get total => 'कुल';

  @override
  String get sendViaOfficeKit => 'ऑफिस किट से भेजें';

  @override
  String get backToEdit => 'संपादन पर वापस जाएं';

  @override
  String get cashFlowHeatmap => 'नकदी प्रवाह';

  @override
  String get mirrorToLaptop => 'लैपटॉप पर मिरर करें';

  @override
  String get stopMirroring => 'मिररिंग रोकें';

  @override
  String get exportHeatmap => 'निर्यात करें';

  @override
  String get bestDay => 'सबसे अच्छा दिन';

  @override
  String get worstDay => 'सबसे कमज़ोर दिन';

  @override
  String get trend => 'रुझान';

  @override
  String get notEnoughData => 'पर्याप्त डेटा नहीं है';

  @override
  String get noTransactionsToday => 'इंका ट्रांजैक्शन्स लेदु';

  @override
  String get workingOffline => 'ऑफ़लाइन काम कर रहे हैं';

  @override
  String lastUpdated(String time) {
    return 'आखिरी अपडेट: $time';
  }

  @override
  String get verifyManually => 'क्या मैन्युअल रूप से जांचें?';

  @override
  String get networkSlowRetry => 'नेटवर्क धीमा है, फिर से कोशिश करें?';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String get retake => 'फिर से लें';

  @override
  String get success => 'लेनदेन सेव हो गया!';

  @override
  String get error => 'कुछ गड़बड़ हो गई';

  @override
  String dayStreak(int count) {
    return '$count-दिन की स्ट्रीक!';
  }

  @override
  String get proVyapari => 'प्रो व्यापारी';
}
