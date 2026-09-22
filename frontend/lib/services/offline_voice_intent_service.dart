import '../models/transaction.dart';
import 'cache_service.dart';

enum OfflineVoiceAction {
  none,
  createSale,
  createExpense,
  openDashboard,
  openKhata,
  openInvoice,
  openPayments,
  openHistory,
  openCreditScore,
  openSettings,
}

class OfflineVoiceResult {
  final OfflineVoiceAction action;
  final String response;
  final bool success;

  const OfflineVoiceResult({
    required this.action,
    required this.response,
    required this.success,
  });
}

/// Deterministic, low-RAM offline command engine for
/// English, Hindi and Telugu.
///
/// Responsibilities:
/// - Detect voice intent
/// - Extract numeric and spoken amounts
/// - Record sales locally
/// - Record expenses locally
/// - Read today's sales/expenses
/// - Handle navigation commands
///
/// No internet connection or AI API is required.
class OfflineVoiceIntentService {
  final CacheService cacheService;

  const OfflineVoiceIntentService({
    required this.cacheService,
  });

  // ---------------------------------------------------------------------------
  // MAIN INTENT PROCESSOR
  // ---------------------------------------------------------------------------

  Future<OfflineVoiceResult> process(String transcript) async {
    final raw = transcript.trim();

    if (raw.isEmpty) {
      return _result(
        OfflineVoiceAction.none,
        'I did not hear a command. Please try again.',
        success: false,
      );
    }

    final text = _normalize(raw);

    // Navigation intents are checked first.
    if (_containsAny(text, _historyWords)) {
      return _result(
        OfflineVoiceAction.openHistory,
        _localized(
          text,
          'Opening transaction history.',
          'लेनदेन की हिस्ट्री खोल रहा हूँ।',
          'లావాదేవీల హిస్టరీ తెరుస్తున్నాను.',
        ),
      );
    }

    if (_containsAny(text, _khataWords)) {
      return _result(
        OfflineVoiceAction.openKhata,
        _localized(
          text,
          'Opening Khata.',
          'खाता खोल रहा हूँ।',
          'ఖాతా తెరుస్తున్నాను.',
        ),
      );
    }

    if (_containsAny(text, _invoiceWords)) {
      return _result(
        OfflineVoiceAction.openInvoice,
        _localized(
          text,
          'Opening invoices.',
          'इनवॉइस खोल रहा हूँ।',
          'ఇన్వాయిస్‌లు తెరుస్తున్నాను.',
        ),
      );
    }

    if (_containsAny(text, _paymentWords)) {
      return _result(
        OfflineVoiceAction.openPayments,
        _localized(
          text,
          'Opening payments.',
          'पेमेंट्स खोल रहा हूँ।',
          'పేమెంట్స్ తెరుస్తున్నాను.',
        ),
      );
    }

    if (_containsAny(text, _creditScoreWords)) {
      return _result(
        OfflineVoiceAction.openCreditScore,
        _localized(
          text,
          'Opening credit score.',
          'क्रेडिट स्कोर खोल रहा हूँ।',
          'క్రెడిట్ స్కోర్ తెరుస్తున్నాను.',
        ),
      );
    }

    if (_containsAny(text, _settingsWords)) {
      return _result(
        OfflineVoiceAction.openSettings,
        _localized(
          text,
          'Opening settings.',
          'सेटिंग्स खोल रहा हूँ।',
          'సెట్టింగ్స్ తెరుస్తున్నాను.',
        ),
      );
    }

    if (_containsAny(text, _dashboardWords)) {
      return _result(
        OfflineVoiceAction.openDashboard,
        _localized(
          text,
          'Opening dashboard.',
          'डैशबोर्ड खोल रहा हूँ।',
          'డాష్‌బోర్డ్ తెరుస్తున్నాను.',
        ),
      );
    }

    final asksSales = _containsAny(text, _salesWords);
    final asksExpenses = _containsAny(text, _expenseWords);

    // -----------------------------------------------------------------------
    // QUERY INTENT
    //
    // IMPORTANT:
    // A command such as:
    // "today's sales"
    // "आज की बिक्री कितनी है?"
    //
    // should be treated as a query.
    //
    // But:
    // "आज का सेल पांच सौ रुपये का हुआ है"
    //
    // should be treated as a CREATE SALE command because it contains
    // a transaction amount.
    // -----------------------------------------------------------------------

    final amount = _extractAmount(text);
    final isQuery = _isQuery(text);

    if (isQuery && asksSales && amount == null) {
      return _salesSummary(text);
    }

    if (isQuery && asksExpenses && amount == null) {
      return _expenseSummary(text);
    }

    // -----------------------------------------------------------------------
    // CREATE SALE
    // -----------------------------------------------------------------------

    if (asksSales && !_looksNegative(text)) {
      if (amount != null && amount > 0) {
        return _record(
          amount,
          TransactionCategory.sales,
          text,
        );
      }

      return _result(
        OfflineVoiceAction.none,
        _localized(
          text,
          'I understood this as a sale, but I could not find the amount. Please say the amount.',
          'मैंने बिक्री समझी, लेकिन रकम नहीं समझ पाया। कृपया रकम बताएं।',
          'అమ్మకం అని అర్థమైంది, కానీ మొత్తం అర్థం కాలేదు. దయచేసి మొత్తాన్ని చెప్పండి.',
        ),
        success: false,
      );
    }

    // -----------------------------------------------------------------------
    // CREATE EXPENSE
    // -----------------------------------------------------------------------

    if (asksExpenses) {
      if (amount != null && amount > 0) {
        return _record(
          amount,
          TransactionCategory.expense,
          text,
        );
      }

      return _result(
        OfflineVoiceAction.none,
        _localized(
          text,
          'I understood this as an expense, but I could not find the amount. Please say the amount.',
          'मैंने खर्च समझा, लेकिन रकम नहीं समझ पाया। कृपया रकम बताएं।',
          'ఖర్చు అని అర్థమైంది, కానీ మొత్తం అర్థం కాలేదు. దయచేసి మొత్తాన్ని చెప్పండి.',
        ),
        success: false,
      );
    }

    // -----------------------------------------------------------------------
    // UNKNOWN COMMAND
    // -----------------------------------------------------------------------

    return _result(
      OfflineVoiceAction.none,
      _localized(
        text,
        'I can handle sales, expenses, Khata, invoices, payments, history and business totals offline.',
        'मैं बिक्री, खर्च, खाता, इनवॉइस, पेमेंट, हिस्ट्री और बिजनेस टोटल ऑफलाइन संभाल सकता हूँ।',
        'నేను అమ్మకాలు, ఖర్చులు, ఖాతా, ఇన్వాయిస్, పేమెంట్స్, హిస్టరీ మరియు బిజినెస్ టోటల్స్‌ను ఆఫ్‌లైన్‌లో నిర్వహించగలను.',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RECORD TRANSACTION
  // ---------------------------------------------------------------------------

  Future<OfflineVoiceResult> _record(
    double amount,
    TransactionCategory category,
    String text,
  ) async {
    final transaction = Transaction(
      id: 'voice_${DateTime.now().microsecondsSinceEpoch}',
      amount: amount,
      category: category,
      timestamp: DateTime.now(),
      confidence: 100,
      isSynced: false,
    );

    await cacheService.addTransaction(transaction);

    final formattedAmount = '₹${_formatAmount(amount)}';

    final response = category == TransactionCategory.sales
        ? _localized(
            text,
            'Recorded a $formattedAmount sale.',
            '$formattedAmount की बिक्री रिकॉर्ड कर दी है।',
            '$formattedAmount అమ్మకం నమోదు చేశాను.',
          )
        : _localized(
            text,
            'Recorded a $formattedAmount expense.',
            '$formattedAmount का खर्च रिकॉर्ड कर दिया है।',
            '$formattedAmount ఖర్చు నమోదు చేశాను.',
          );

    return _result(
      category == TransactionCategory.sales
          ? OfflineVoiceAction.createSale
          : OfflineVoiceAction.createExpense,
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // SALES SUMMARY
  // ---------------------------------------------------------------------------

  OfflineVoiceResult _salesSummary(String text) {
    return _summary(
      text,
      TransactionCategory.sales,
    );
  }

  // ---------------------------------------------------------------------------
  // EXPENSE SUMMARY
  // ---------------------------------------------------------------------------

  OfflineVoiceResult _expenseSummary(String text) {
    return _summary(
      text,
      TransactionCategory.expense,
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  OfflineVoiceResult _summary(
    String text,
    TransactionCategory category,
  ) {
    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    final transactions = cacheService.getCachedTransactions().data;

    final total = transactions
        .where(
          (transaction) =>
              transaction.category == category &&
              !transaction.timestamp.isBefore(start) &&
              transaction.timestamp.isBefore(end),
        )
        .fold<double>(
          0,
          (sum, transaction) => sum + transaction.amount,
        );

    final amount = '₹${_formatAmount(total)}';

    final response = category == TransactionCategory.sales
        ? _localized(
            text,
            'Today’s sales are $amount.',
            'आज की बिक्री $amount है।',
            'ఈరోజు అమ్మకాలు $amount ఉన్నాయి.',
          )
        : _localized(
            text,
            'Today’s expenses are $amount.',
            'आज का खर्च $amount है।',
            'ఈరోజు ఖర్చు $amount ఉంది.',
          );

    return _result(
      OfflineVoiceAction.none,
      response,
    );
  }

  // ---------------------------------------------------------------------------
  // AMOUNT EXTRACTION
  // ---------------------------------------------------------------------------

  double? _extractAmount(String text) {
    // First try normal numeric amounts:
    //
    // 500
    // ₹500
    // Rs 500
    // 500 रुपये
    // 1,500
    // 1500.50
    //
    final numeric = RegExp(
      r'(?:₹|rs\.?|rupees?|रु\.?|रुपये|रुपया|रुपए|रूपये|రూ\.?|రూపాయలు?|రూపాయలు|రూపాయి)?\s*([0-9]+(?:,[0-9]{2,3})*(?:\.[0-9]+)?)',
      caseSensitive: false,
    ).firstMatch(text);

    if (numeric != null) {
      return double.tryParse(
        numeric.group(1)!.replaceAll(',', ''),
      );
    }

    // Hindi spoken numbers.
    final hindi = _parseHindiNumber(text);

    if (hindi != null) {
      return hindi;
    }

    // English spoken numbers.
    final english = _parseWordNumber(
      text,
      _englishNumbers,
    );

    if (english != null) {
      return english;
    }

    // Telugu spoken numbers.
    final telugu = _parseWordNumber(
      text,
      _teluguNumbers,
    );

    if (telugu != null) {
      return telugu;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // HINDI NUMBER PARSER
  //
  // Examples:
  // पांच सौ              -> 500
  // पाँच सौ              -> 500
  // पांच सौ रुपये        -> 500
  // एक हजार              -> 1000
  // दो हजार पांच सौ      -> 2500
  // पंद्रह सौ             -> 1500
  // ---------------------------------------------------------------------------

  double? _parseHindiNumber(String text) {
    final tokens = text.split(RegExp(r'\s+'));

    var total = 0;
    var current = 0;
    var found = false;

    for (final token in tokens) {
      final number = _hindiNumbers[token];

      if (number == null) {
        continue;
      }

      found = true;

      if (number == 100) {
        current = current == 0 ? 100 : current * 100;
      } else if (number == 1000) {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
      } else {
        current += number;
      }
    }

    if (!found) {
      return null;
    }

    final result = total + current;

    return result > 0 ? result.toDouble() : null;
  }

  // ---------------------------------------------------------------------------
  // GENERIC WORD NUMBER PARSER
  // ---------------------------------------------------------------------------

  double? _parseWordNumber(
    String text,
    Map<String, int> values,
  ) {
    final tokens = text.split(RegExp(r'\s+'));

    var total = 0;
    var current = 0;
    var found = false;

    for (final token in tokens) {
      final number = values[token];

      if (number == null) {
        continue;
      }

      found = true;

      if (number == 100) {
        current = current == 0 ? 100 : current * 100;
      } else if (number == 1000) {
        total += (current == 0 ? 1 : current) * 1000;
        current = 0;
      } else {
        current += number;
      }
    }

    if (!found) {
      return null;
    }

    final result = total + current;

    return result > 0 ? result.toDouble() : null;
  }

  // ---------------------------------------------------------------------------
  // QUERY DETECTION
  // ---------------------------------------------------------------------------

  bool _isQuery(String text) {
    // Explicit question words are always queries.
    if (_containsAny(text, _explicitQueryWords)) {
      return true;
    }

    // "today's sales" / "आज की बिक्री" / "ఈరోజు అమ్మకాలు"
    // without an amount is a query.
    if (_containsAny(text, _todayWords) &&
        (_containsAny(text, _salesWords) ||
            _containsAny(text, _expenseWords))) {
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // NEGATIVE SALE DETECTION
  // ---------------------------------------------------------------------------

  bool _looksNegative(String text) {
    return _containsAny(
      text,
      [
        'not sale',
        'no sale',
        'sale not',
        'बिक्री नहीं',
        'सेल नहीं',
        'बिक्री नही',
        'सेल नही',
        'అమ్మకం కాదు',
        'అమ్మకం లేదు',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TEXT HELPERS
  // ---------------------------------------------------------------------------

  bool _containsAny(
    String text,
    Iterable<String> words,
  ) {
    return words.any(
      text.contains,
    );
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        // Normalize common Hindi ASR variations.
        .replaceAll('रुपए', 'रुपये')
        .replaceAll('रूपये', 'रुपये')
        .replaceAll('रूपए', 'रुपये')
        .replaceAll('पाँच', 'पांच')
        // Normalize common Telugu currency variations.
        .replaceAll('రూపాయల', 'రూపాయలు')
        .replaceAll(
          RegExp(r'[!?.,;:।,]+'),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  bool _isHindi(String text) {
    return RegExp(
      r'[\u0900-\u097F]',
    ).hasMatch(text);
  }

  bool _isTelugu(String text) {
    return RegExp(
      r'[\u0C00-\u0C7F]',
    ).hasMatch(text);
  }

  String _localized(
    String text,
    String en,
    String hi,
    String te,
  ) {
    if (_isHindi(text)) {
      return hi;
    }

    if (_isTelugu(text)) {
      return te;
    }

    return en;
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }

  OfflineVoiceResult _result(
    OfflineVoiceAction action,
    String response, {
    bool success = true,
  }) {
    return OfflineVoiceResult(
      action: action,
      response: response,
      success: success,
    );
  }

  // ---------------------------------------------------------------------------
  // INTENT KEYWORDS
  // ---------------------------------------------------------------------------

  static const _salesWords = [
    'sale',
    'sales',
    'sell',
    'sold',
    'selling',
    'सेल',
    'बिक्री',
    'बिका',
    'बेचा',
    'बेचे',
    'विक्रय',
    'అమ్మకం',
    'అమ్మకాలు',
    'విక్రయం',
    'ammakam',
    'ammakalu',
  ];

  static const _expenseWords = [
    'expense',
    'expenses',
    'spent',
    'spend',
    'खर्च',
    'खर्चा',
    'खर्चे',
    'व्यय',
    'ఖర్చు',
    'ఖర్చులు',
    'వ్యయం',
    'kharch',
    'kharchu',
  ];

  // Explicit question words.
  static const _explicitQueryWords = [
    'how much',
    'how many',
    'total',
    'what is',
    'what are',
    'show me',
    'tell me',
    'कितना',
    'कितनी',
    'कितने',
    'कुल',
    'बताओ',
    'बताइए',
    'ఎంత',
    'ఎన్ని',
    'మొత్తం',
    'చెప్పు',
    'చెప్పండి',
  ];

  static const _todayWords = [
    'today',
    'todays',
    'today\'s',
    'आज',
    'आज का',
    'आज की',
    'आज के',
    'आज का',
    'ఈరోజు',
    'ఈ రోజు',
    'ivala',
    'ee roju',
  ];

  static const _khataWords = [
    'khata',
    'udhaar',
    'udhar',
    'उधार',
    'उधारी',
    'खाता',
    'खाते',
    'ఖాతా',
    'ఖాతాలు',
  ];

  static const _invoiceWords = [
    'invoice',
    'invoices',
    'bill',
    'bills',
    'बिल',
    'इनवॉइस',
    'ఇన్వాయిస్',
    'బిల్',
  ];

  static const _paymentWords = [
    'payment',
    'payments',
    'pay',
    'paid',
    'भुगतान',
    'पेमेंट',
    'पेमेंट्स',
    'पैसा मिला',
    'चुकाया',
    'చెల్లింపు',
    'చెల్లింపులు',
    'పేమెంట్',
    'పేమెంట్స్',
  ];

  static const _historyWords = [
    'history',
    'transactions',
    'transaction history',
    'लेनदेन',
    'हिस्ट्री',
    'इतिहास',
    'लेन देन',
    'లావాదేవీ',
    'లావాదేవీలు',
    'హిస్టరీ',
  ];

  static const _creditScoreWords = [
    'credit score',
    'score',
    'क्रेडिट स्कोर',
    'क्रेडिट',
    'క్రెడిట్ స్కోర్',
  ];

  static const _settingsWords = [
    'settings',
    'setting',
    'सेटिंग',
    'सेटिंग्स',
    'సెట్టింగ్',
    'సెట్టింగ్స్',
  ];

  static const _dashboardWords = [
    'dashboard',
    'home',
    'main screen',
    'डैशबोर्ड',
    'होम',
    'मुख्य स्क्रीन',
    'డాష్‌బोर्ड',
    'హోమ్',
  ];

  // ---------------------------------------------------------------------------
  // HINDI NUMBER WORDS
  // ---------------------------------------------------------------------------

  static const _hindiNumbers = <String, int>{
    'शून्य': 0,
    'एक': 1,
    'दो': 2,
    'तीन': 3,
    'चार': 4,
    'पांच': 5,
    'पाँच': 5,
    'छह': 6,
    'छः': 6,
    'सात': 7,
    'आठ': 8,
    'नौ': 9,
    'दस': 10,
    'ग्यारह': 11,
    'बारह': 12,
    'तेरह': 13,
    'चौदह': 14,
    'पंद्रह': 15,
    'पन्द्रह': 15,
    'सोलह': 16,
    'सत्रह': 17,
    'अठारह': 18,
    'उन्नीस': 19,
    'बीस': 20,
    'तीस': 30,
    'चालीस': 40,
    'पचास': 50,
    'साठ': 60,
    'सत्तर': 70,
    'अस्सी': 80,
    'नब्बे': 90,
    'सौ': 100,
    'सैकड़ा': 100,
    'सैकड़े': 100,
    'हजार': 1000,
    'हज़ार': 1000,
  };

  // ---------------------------------------------------------------------------
  // ENGLISH NUMBER WORDS
  // ---------------------------------------------------------------------------

  static const _englishNumbers = <String, int>{
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
    'hundred': 100,
    'thousand': 1000,
  };

  // ---------------------------------------------------------------------------
  // TELUGU NUMBER WORDS
  // ---------------------------------------------------------------------------

  static const _teluguNumbers = <String, int>{
    'సున్న': 0,
    'సున్నా': 0,
    'ఒకటి': 1,
    'ఒక్కటి': 1,
    'రెండు': 2,
    'మూడు': 3,
    'నాలుగు': 4,
    'ఐదు': 5,
    'ఆరు': 6,
    'ఏడు': 7,
    'ఎనిమిది': 8,
    'తొమ్మిది': 9,
    'పది': 10,
    'పదకొండు': 11,
    'పన్నెండు': 12,
    'పదమూడు': 13,
    'పద్నాలుగు': 14,
    'పదిహేను': 15,
    'పదహారు': 16,
    'పదిహేడు': 17,
    'పద్దెనిమిది': 18,
    'పందొమ్మిది': 19,
    'ఇరవై': 20,
    'ముప్పై': 30,
    'నలభై': 40,
    'యాభై': 50,
    'అరవై': 60,
    'డెబ్బై': 70,
    'ఎనభై': 80,
    'తొంభై': 90,
    'వంద': 100,
    'వందల': 100,
    'వెయ్యి': 1000,
    'వేలు': 1000,
  };
}
