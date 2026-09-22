// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'व्यापार साथी AI';

  @override
  String homeGreeting(String name) {
    return 'नमस्कार, $name!';
  }

  @override
  String get todaySummary => 'आजचा सारांश';

  @override
  String get income => 'उत्पन्न';

  @override
  String get expenses => 'खर्च';

  @override
  String get net => 'निव्वळ';

  @override
  String get captureTransaction => 'व्यवहार नोंदवा';

  @override
  String get viewCreditScore => 'क्रेडिट स्कोअर पहा';

  @override
  String get generateBill => 'बिल तयार करा';

  @override
  String get creditScore => 'क्रेडिट स्कोअर';

  @override
  String get loanEligibility => 'कर्ज पात्रता';

  @override
  String get loanEligibilityHigh => 'उच्च - ₹50,000 पर्यंत';

  @override
  String get loanEligibilityMedium => 'मध्यम - ₹15,000 पर्यंत';

  @override
  String get loanEligibilityLow => 'कमी - ₹5,000 पर्यंत';

  @override
  String get downloadCreditReport => 'क्रेडिट अहवाल डाउनलोड करा';

  @override
  String get consistency => 'सातत्य';

  @override
  String get diversity => 'विविधता';

  @override
  String get avgIncome => 'सरासरी उत्पन्न';

  @override
  String get lowScoreTip =>
      'नियमित व्यवहार नोंदवा आणि तुमचा स्कोअर सुधारण्याचा प्रयत्न करा.';

  @override
  String get generateInvoice => 'बिल तयार करा';

  @override
  String get gstInvoiceTitle => 'GST इनव्हॉइस';

  @override
  String get customerNameOptional => 'ग्राहकाचे नाव (ऐच्छिक)';

  @override
  String get customerPhoneLabel => 'ग्राहकाचा फोन नंबर (GST रेकॉर्डसाठी)';

  @override
  String get addItemByVoice => 'आवाजाने वस्तू जोडा';

  @override
  String get subtotal => 'उपएकूण';

  @override
  String get gst => 'GST';

  @override
  String get total => 'एकूण';

  @override
  String get sendViaOfficeKit => 'ऑफिस किटद्वारे पाठवा';

  @override
  String get backToEdit => 'संपादनाकडे परत जा';

  @override
  String get cashFlowHeatmap => 'रोख प्रवाह';

  @override
  String get mirrorToLaptop => 'लॅपटॉपवर मिरर करा';

  @override
  String get stopMirroring => 'मिररिंग थांबवा';

  @override
  String get exportHeatmap => 'एक्सपोर्ट करा';

  @override
  String get bestDay => 'सर्वोत्तम दिवस';

  @override
  String get worstDay => 'सर्वात कमी कामगिरीचा दिवस';

  @override
  String get trend => 'कल';

  @override
  String get notEnoughData => 'पुरेसा डेटा उपलब्ध नाही';

  @override
  String get noTransactionsToday => 'आज कोणतेही व्यवहार नाहीत';

  @override
  String get workingOffline => 'ऑफलाइन काम करत आहे';

  @override
  String lastUpdated(String time) {
    return 'शेवटचे अपडेट: $time';
  }

  @override
  String get verifyManually => 'तुम्हाला हे स्वतः तपासायचे आहे का?';

  @override
  String get networkSlowRetry => 'नेटवर्क धीमे आहे, पुन्हा प्रयत्न करायचा का?';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get confirm => 'पुष्टी करा';

  @override
  String get retake => 'पुन्हा घ्या';

  @override
  String get success => 'व्यवहार यशस्वीरित्या जतन झाला!';

  @override
  String get error => 'काहीतरी चूक झाली';

  @override
  String dayStreak(int count) {
    return '$count दिवसांची स्ट्रीक!';
  }

  @override
  String get proVyapari => 'प्रो व्यापारी';
}
