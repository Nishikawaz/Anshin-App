part of '../../main.dart';

enum TransactionSource { bank, manual, ocr, voice }

class TransactionEntry {
  TransactionEntry({
    required this.id,
    required this.amountPyg,
    required this.merchant,
    required this.category,
    required this.source,
    required this.createdAt,
    required this.isConfirmed,
    required this.isIncome,
  });

  final String id;
  int amountPyg;
  String merchant;
  String category;
  final TransactionSource source;
  final DateTime createdAt;
  bool isConfirmed;
  final bool isIncome;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountPyg': amountPyg,
      'merchant': merchant,
      'category': category,
      'source': source.name,
      'createdAt': createdAt.toIso8601String(),
      'isConfirmed': isConfirmed,
      'isIncome': isIncome,
    };
  }

  static TransactionEntry? fromJson(Map<String, dynamic> json) {
    final sourceName = json['source']?.toString() ?? '';
    final source = TransactionSource.values.where(
      (item) => item.name == sourceName,
    );
    final createdAtRaw = json['createdAt']?.toString() ?? '';
    final createdAt = DateTime.tryParse(createdAtRaw);

    final amountRaw = json['amountPyg'];
    final amount = amountRaw is int
        ? amountRaw
        : (amountRaw is num ? amountRaw.round() : null);
    if (createdAt == null || amount == null) {
      return null;
    }
    if (json['id'] == null ||
        json['merchant'] == null ||
        json['category'] == null ||
        source.isEmpty ||
        json['isConfirmed'] is! bool ||
        json['isIncome'] is! bool) {
      return null;
    }

    return TransactionEntry(
      id: json['id'].toString(),
      amountPyg: amount,
      merchant: json['merchant'].toString(),
      category: json['category'].toString(),
      source: source.first,
      createdAt: createdAt,
      isConfirmed: json['isConfirmed'] as bool,
      isIncome: json['isIncome'] as bool,
    );
  }
}

class BudgetCategory {
  BudgetCategory({
    required this.name,
    required this.limitPyg,
    required this.spentPyg,
  });

  final String name;
  final int limitPyg;
  final int spentPyg;
}

class AnshinState extends ChangeNotifier {
  static const List<int> alertThresholds = [50, 75, 90, 100];
  static const int maxPushesPerDay = 1;
  static const _prefsSalaryKey = 'anshin.salary_pyg';
  static const _prefsPlanNameKey = 'anshin.plan_name';
  static const _prefsPlanFixedKey = 'anshin.plan_fixed';
  static const _prefsPlanVariableKey = 'anshin.plan_variable';
  static const _prefsPlanSavingsKey = 'anshin.plan_savings';
  static const _prefsTransactionsKey = 'anshin.transactions';

  final _notifications = FlutterLocalNotificationsPlugin();
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _speech = SpeechToText();
  final List<TransactionEntry> _transactions = [];

  StreamSubscription<ServiceNotificationEvent>? _bankListenerSub;
  bool _bankCaptureEnabled = false;
  bool _voiceAvailable = false;
  bool _isListeningVoice = false;
  bool _isStartingVoice = false;
  bool _voiceResultCommitted = false;
  String? _preferredVoiceLocaleId;
  String _liveVoiceText = '';
  String _integrationMessage = 'Inicializando conectores...';
  int _monthlyIncomePyg = 0;
  BudgetSplit _budgetPlan = const BudgetSplit(
    fixedPct: 60,
    variablePct: 30,
    savingsPct: 10,
  );
  String _budgetPlanName = 'Modo equilibrado';
  bool _hasUserBudgetConfig = false;
  int _streakDays = 9;
  int _freezeTokens = 1;
  DateTime _lastOpen = DateTime.now().subtract(const Duration(hours: 20));
  DateTime? _lastPushAt;
  String? _lastPushMessage;
  String? _lastWeeklyReport;
  String _voiceDraftTranscript = '';
  String _voiceDraftMerchant = '';
  String _voiceDraftCategory = 'Variables';
  int _voiceDraftAmountPyg = 0;
  bool _hasVoiceDraft = false;

  AnshinState();

  List<TransactionEntry> get transactions => List.unmodifiable(_transactions);
  int get streakDays => _streakDays;
  int get freezeTokens => _freezeTokens;
  String? get lastPushMessage => _lastPushMessage;
  String? get lastWeeklyReport => _lastWeeklyReport;
  bool get bankCaptureEnabled => _bankCaptureEnabled;
  bool get voiceAvailable => _voiceAvailable;
  bool get isListeningVoice => _isListeningVoice;
  bool get isStartingVoice => _isStartingVoice;
  String get liveVoiceText => _liveVoiceText;
  String get integrationMessage => _integrationMessage;
  int get monthlyIncomePyg => _monthlyIncomePyg;
  String get budgetPlanName => _budgetPlanName;
  BudgetSplit get budgetPlan => _budgetPlan;
  bool get hasUserBudgetConfig => _hasUserBudgetConfig;
  bool get hasVoiceDraft => _hasVoiceDraft;
  String get voiceDraftTranscript => _voiceDraftTranscript;
  String get voiceDraftMerchant => _voiceDraftMerchant;
  String get voiceDraftCategory => _voiceDraftCategory;
  int get voiceDraftAmountPyg => _voiceDraftAmountPyg;

  int get totalExpensesPyg => _transactions
      .where((t) => t.isConfirmed && !t.isIncome)
      .fold(0, (acc, t) => acc + t.amountPyg);

  int get totalIncomePyg => _transactions
      .where((t) => t.isConfirmed && t.isIncome)
      .fold(0, (acc, t) => acc + t.amountPyg);

  int get availableTodayPyg =>
      _monthlyIncomePyg - totalExpensesPyg + totalIncomePyg;

  List<BudgetCategory> get budgets {
    final rules = <String, int>{
      'Fijos': (_monthlyIncomePyg * (_budgetPlan.fixedPct / 100)).round(),
      'Variables': (_monthlyIncomePyg * (_budgetPlan.variablePct / 100))
          .round(),
      'Ahorro': (_monthlyIncomePyg * (_budgetPlan.savingsPct / 100)).round(),
    };

    int spentFor(String category) => _transactions
        .where((t) => t.isConfirmed && !t.isIncome && t.category == category)
        .fold(0, (acc, t) => acc + t.amountPyg);

    return [
      BudgetCategory(
        name: 'Fijos',
        limitPyg: max(rules['Fijos']!, 1),
        spentPyg: spentFor('Fijos'),
      ),
      BudgetCategory(
        name: 'Variables',
        limitPyg: max(rules['Variables']!, 1),
        spentPyg: spentFor('Variables'),
      ),
      BudgetCategory(
        name: 'Ahorro',
        limitPyg: max(rules['Ahorro']!, 1),
        spentPyg: spentFor('Ahorro'),
      ),
    ];
  }

  Future<void> initializeIntegrations() async {
    await _restoreTransactionsFromStorage();
    await _initLocalNotifications();
    await _initVoice();
    _integrationMessage = 'Listo. PYG activo y conectores preparados.';
    notifyListeners();
  }

  void configureBudgetPlan({
    required int salaryPyg,
    required BudgetSplit plan,
    required String planName,
    bool persist = true,
  }) {
    _monthlyIncomePyg = salaryPyg;
    _budgetPlan = plan;
    _budgetPlanName = planName;
    _hasUserBudgetConfig = true;
    _integrationMessage =
        'Configuración inicial guardada: ${formatPyg(salaryPyg)} en $planName.';
    if (persist) {
      unawaited(_saveBudgetPlanToStorage());
    }
    notifyListeners();
  }

  Future<bool> restoreBudgetPlanFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final salary = prefs.getInt(_prefsSalaryKey);
    final fixed = prefs.getInt(_prefsPlanFixedKey);
    final variable = prefs.getInt(_prefsPlanVariableKey);
    final savings = prefs.getInt(_prefsPlanSavingsKey);
    final planName = prefs.getString(_prefsPlanNameKey);

    if (salary == null ||
        fixed == null ||
        variable == null ||
        savings == null ||
        planName == null) {
      return false;
    }

    final restoredSplit = BudgetSplit(
      fixedPct: fixed,
      variablePct: variable,
      savingsPct: savings,
    );
    if (salary <= 0 || restoredSplit.total != 100) {
      return false;
    }

    configureBudgetPlan(
      salaryPyg: salary,
      plan: restoredSplit,
      planName: planName,
      persist: false,
    );
    _integrationMessage =
        'Configuración recuperada: ${formatPyg(salary)} en $planName.';
    notifyListeners();
    return true;
  }

  Future<void> _saveBudgetPlanToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsSalaryKey, _monthlyIncomePyg);
      await prefs.setString(_prefsPlanNameKey, _budgetPlanName);
      await prefs.setInt(_prefsPlanFixedKey, _budgetPlan.fixedPct);
      await prefs.setInt(_prefsPlanVariableKey, _budgetPlan.variablePct);
      await prefs.setInt(_prefsPlanSavingsKey, _budgetPlan.savingsPct);
    } catch (_) {}
  }

  Future<void> _restoreTransactionsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsTransactionsKey);
      if (raw == null || raw.isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final restored = <TransactionEntry>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final tx = TransactionEntry.fromJson(Map<String, dynamic>.from(item));
        if (tx != null) {
          restored.add(tx);
        }
      }
      restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _transactions
        ..clear()
        ..addAll(restored);
    } catch (_) {}
  }

  Future<void> _saveTransactionsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _transactions.map((item) => item.toJson()).toList();
      await prefs.setString(_prefsTransactionsKey, jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> disposeIntegrations() async {
    await _bankListenerSub?.cancel();
    await _speech.cancel();
    await _textRecognizer.close();
  }

  String canIBuy(int amountPyg) {
    final left = availableTodayPyg - amountPyg;
    if (left >= 0) return 'Si, podes comprar. Te quedarian ${formatPyg(left)}.';
    return 'No conviene: te faltarian ${formatPyg(left.abs())} para mantener tu plan.';
  }

  void registerAppOpen() {
    final now = DateTime.now();
    final hours = now.difference(_lastOpen).inHours;
    if (hours < 24) {
      _streakDays += 1;
    } else if (_freezeTokens > 0) {
      _freezeTokens -= 1;
    } else {
      _streakDays = 0;
    }
    _lastOpen = now;
    _applyStreakReward();
    _maybeCreateWeeklyReport();
    notifyListeners();
  }

  void addManualTransaction({
    required int amountPyg,
    required String merchant,
    required String category,
  }) {
    _addCapturedTransaction(
      amountPyg: amountPyg,
      merchant: merchant,
      category: category,
      source: TransactionSource.manual,
      isIncome: false,
    );
  }

  bool updateTransaction({
    required String id,
    required int amountPyg,
    required String merchant,
    required String category,
  }) {
    final index = _transactions.indexWhere((item) => item.id == id);
    if (index == -1 || amountPyg <= 0 || merchant.trim().isEmpty) {
      return false;
    }
    final tx = _transactions[index];
    tx.amountPyg = amountPyg;
    tx.merchant = merchant.trim();
    tx.category = category;
    if (tx.isConfirmed && !tx.isIncome) {
      _notifyBudgetAlert(category);
    }
    unawaited(_saveTransactionsToStorage());
    notifyListeners();
    return true;
  }

  bool deleteTransaction(String id) {
    final before = _transactions.length;
    _transactions.removeWhere((item) => item.id == id);
    if (_transactions.length == before) {
      return false;
    }
    unawaited(_saveTransactionsToStorage());
    notifyListeners();
    return true;
  }

  void _setVoiceDraft({
    required String transcript,
    required String merchant,
    required String category,
    required int amountPyg,
  }) {
    _voiceDraftTranscript = transcript;
    _voiceDraftMerchant = merchant;
    _voiceDraftCategory = category;
    _voiceDraftAmountPyg = amountPyg;
    _hasVoiceDraft = true;
  }

  void _clearVoiceDraft({bool notify = false}) {
    _voiceDraftTranscript = '';
    _voiceDraftMerchant = '';
    _voiceDraftCategory = 'Variables';
    _voiceDraftAmountPyg = 0;
    _hasVoiceDraft = false;
    if (notify) {
      notifyListeners();
    }
  }

  bool completeVoiceDraft({
    required int amountPyg,
    required String merchant,
    required String category,
  }) {
    if (!_hasVoiceDraft || amountPyg <= 0 || merchant.trim().isEmpty) {
      return false;
    }
    _addCapturedTransaction(
      amountPyg: amountPyg,
      merchant: merchant.trim(),
      category: category,
      source: TransactionSource.voice,
      isIncome: false,
      notify: false,
    );
    _clearVoiceDraft();
    _integrationMessage =
        'Voz completada: ${formatPyg(amountPyg)} en "${merchant.trim()}".';
    notifyListeners();
    return true;
  }

  void discardVoiceDraft() {
    if (!_hasVoiceDraft) {
      return;
    }
    _clearVoiceDraft();
    _integrationMessage = 'Borrador de voz descartado.';
    notifyListeners();
  }

  void _addCapturedTransaction({
    required int amountPyg,
    required String merchant,
    required String category,
    required TransactionSource source,
    required bool isIncome,
    bool notify = true,
  }) {
    _transactions.insert(
      0,
      TransactionEntry(
        id: _id(),
        amountPyg: amountPyg,
        merchant: merchant,
        category: category,
        source: source,
        createdAt: DateTime.now(),
        isConfirmed: true,
        isIncome: isIncome,
      ),
    );
    if (!isIncome) {
      _notifyBudgetAlert(category);
    }
    unawaited(_saveTransactionsToStorage());
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> processOcrFromCamera() async {
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      _integrationMessage = 'OCR disponible en Android/iOS.';
      notifyListeners();
      return;
    }
    try {
      final picture = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picture == null) {
        _integrationMessage = 'OCR cancelado.';
        notifyListeners();
        return;
      }
      final inputImage = InputImage.fromFilePath(picture.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final parsed = _parseAnyAmount(recognized.text);
      if (parsed <= 0) {
        _integrationMessage =
            'OCR listo, pero no pude detectar un monto. Probá enfocando el total del ticket.';
        notifyListeners();
        return;
      }
      final merchant = _guessMerchantFromText(
        recognized.text,
        fallback: 'Ticket escaneado',
      );
      final category = _guessCategory('${recognized.text} $merchant');
      _addCapturedTransaction(
        amountPyg: parsed,
        merchant: merchant,
        category: category,
        source: TransactionSource.ocr,
        isIncome: false,
        notify: false,
      );
      _integrationMessage =
          'OCR registro ${formatPyg(parsed)} en "$merchant". Ya aparece en Movimientos para editar o borrar.';
      notifyListeners();
    } catch (_) {
      _integrationMessage = 'No se pudo ejecutar OCR en este dispositivo.';
      notifyListeners();
    }
  }

  Future<void> toggleVoiceCapture() async {
    if (_isListeningVoice || _isStartingVoice) {
      await _speech.stop();
      _isListeningVoice = false;
      _isStartingVoice = false;
      if (!_voiceResultCommitted && _liveVoiceText.trim().isNotEmpty) {
        _commitVoiceCapture(_liveVoiceText);
        return;
      }
      _integrationMessage = 'Dictado detenido sin texto detectable.';
      notifyListeners();
      return;
    }
    if (!_voiceAvailable) {
      await _initVoice();
    }
    if (!_voiceAvailable) {
      _integrationMessage = 'Voz no disponible o sin permisos.';
      notifyListeners();
      return;
    }
    _liveVoiceText = '';
    _voiceResultCommitted = false;
    _integrationMessage = 'Iniciando micrófono...';
    _isStartingVoice = true;
    _isListeningVoice = true;
    notifyListeners();

    try {
      await _speech.listen(
        localeId: _preferredVoiceLocaleId,
        onResult: _onVoiceResult,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
        listenFor: const Duration(seconds: 35),
        pauseFor: const Duration(seconds: 5),
      );
    } catch (_) {
      try {
        await _speech.listen(
          onResult: _onVoiceResult,
          listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
          ),
          listenFor: const Duration(seconds: 35),
          pauseFor: const Duration(seconds: 5),
        );
      } catch (_) {
        _isStartingVoice = false;
        _isListeningVoice = false;
        _integrationMessage =
            'No pude iniciar el microfono. Revisá permisos de voz.';
        notifyListeners();
      }
    }
  }

  Future<void> connectBankNotifications() async {
    if (kIsWeb || !Platform.isAndroid) {
      _integrationMessage = 'Captura bancaria real disponible solo en Android.';
      notifyListeners();
      return;
    }

    final granted = await NotificationListenerService.isPermissionGranted();
    if (!granted) {
      final requested = await NotificationListenerService.requestPermission();
      if (!requested) {
        _integrationMessage =
            'Permiso de lector de notificaciones no concedido.';
        notifyListeners();
        return;
      }
    }

    await _bankListenerSub?.cancel();
    _bankListenerSub = NotificationListenerService.notificationsStream.listen(
      _onBankNotification,
      onError: (_) {
        _integrationMessage = 'Error escuchando notificaciones bancarias.';
        notifyListeners();
      },
    );
    _bankCaptureEnabled = true;
    _integrationMessage = 'Captura bancaria conectada en tiempo real.';
    notifyListeners();
  }

  void confirmPending(String id) {
    final tx = _transactions.firstWhere((e) => e.id == id);
    tx.isConfirmed = true;
    _notifyBudgetAlert(tx.category);
    unawaited(_saveTransactionsToStorage());
    notifyListeners();
  }

  void rejectPending(String id) {
    _transactions.removeWhere((e) => e.id == id);
    unawaited(_saveTransactionsToStorage());
    notifyListeners();
  }

  TransactionEntry? parseBankNotification(String text, String packageName) {
    final itauAmount = RegExp(
      r'(?:G\.|PYG|Gs\.?)\s*([\d.,]+)',
      caseSensitive: false,
    );
    final uenoAmount = RegExp(r'G\s+([\d.,]+)', caseSensitive: false);
    final contAmount = RegExp(r'G\.\s*([\d.,]+)', caseSensitive: false);

    int? amount;
    String merchant = 'Movimiento bancario';
    bool isIncome = false;

    if (packageName == 'com.itau.py' || text.toLowerCase().contains('itau')) {
      amount = _parseAmount(itauAmount.firstMatch(text)?.group(1));
      merchant =
          RegExp(
            r'en\s+([A-Z0-9.\s]+?)(?:\.|$)',
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.trim() ??
          'Itaú';
      isIncome = text.toLowerCase().contains('recibiste');
    } else if (packageName == 'py.ueno.app' ||
        text.toLowerCase().contains('ueno')) {
      amount = _parseAmount(uenoAmount.firstMatch(text)?.group(1));
      merchant =
          RegExp(
            r'(?:a|en)\s+([^.]+)',
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.trim() ??
          'Ueno';
      isIncome = text.toLowerCase().contains('recibiste');
    } else if (packageName == 'py.continental.banca' ||
        text.toLowerCase().contains('continental')) {
      amount = _parseAmount(contAmount.firstMatch(text)?.group(1));
      merchant =
          RegExp(
            r'-\s*([A-Z0-9.\s]+)$',
            caseSensitive: false,
          ).firstMatch(text)?.group(1)?.trim() ??
          'Continental';
      isIncome = text.toLowerCase().contains('acredit');
    }

    if (amount == null || amount <= 0) return null;

    return TransactionEntry(
      id: _id(),
      amountPyg: amount,
      merchant: merchant,
      category: _guessCategory(merchant),
      source: TransactionSource.bank,
      createdAt: DateTime.now(),
      isConfirmed: true,
      isIncome: isIncome,
    );
  }

  String formatPyg(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return 'Gs. $buffer';
  }

  void clearPushMessage() {
    _lastPushMessage = null;
    notifyListeners();
  }

  Future<void> _initLocalNotifications() async {
    try {
      const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const init = InitializationSettings(android: initAndroid);
      await _notifications.initialize(settings: init);
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<void> _initVoice() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
      try {
        _voiceAvailable = await _speech.initialize(
          onStatus: (status) {
            if (status == 'listening') {
              _isStartingVoice = false;
              _integrationMessage = 'Escuchando gasto por voz...';
              notifyListeners();
              return;
            }
            if (status == 'notListening') {
              final shouldCommit =
                  !_voiceResultCommitted && _liveVoiceText.trim().isNotEmpty;
              _isStartingVoice = false;
              _isListeningVoice = false;
              if (shouldCommit) {
                _commitVoiceCapture(_liveVoiceText);
              } else {
                notifyListeners();
              }
            }
          },
          onError: (error) {
            _isStartingVoice = false;
            _isListeningVoice = false;
            _voiceResultCommitted = true;
            _integrationMessage =
                'Error en reconocimiento de voz: ${error.errorMsg}.';
            notifyListeners();
          },
        );
        if (_voiceAvailable) {
          final locales = await _speech.locales();
          const preferred = ['es_PY', 'es_AR', 'es_ES', 'es_MX', 'es_US'];
          for (final locale in preferred) {
            if (locales.any((item) => item.localeId == locale)) {
              _preferredVoiceLocaleId = locale;
              break;
            }
          }
          if (_preferredVoiceLocaleId == null) {
            for (final locale in locales) {
              if (locale.localeId.toLowerCase().startsWith('es')) {
                _preferredVoiceLocaleId = locale.localeId;
                break;
              }
            }
          }
        }
      } catch (_) {
        _voiceAvailable = false;
      }
    }
  }

  void _onVoiceResult(SpeechRecognitionResult result) {
    _liveVoiceText = result.recognizedWords;
    if (!result.finalResult) {
      notifyListeners();
      return;
    }
    _isListeningVoice = false;
    _commitVoiceCapture(_liveVoiceText);
  }

  void _onBankNotification(ServiceNotificationEvent event) {
    if (event.hasRemoved == true) return;
    final packageName = event.packageName ?? '';
    final title = event.title ?? '';
    final content = event.content ?? '';
    final parsed = parseBankNotification('$title $content', packageName);
    if (parsed == null) return;
    _transactions.insert(0, parsed);
    _integrationMessage =
        'Banco detectado: ${parsed.merchant} por ${formatPyg(parsed.amountPyg)}.';
    _notifyBudgetAlert(parsed.category);
    unawaited(_saveTransactionsToStorage());
    notifyListeners();
  }

  int _parseAnyAmount(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return 0;
    }

    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    int bestPreferred = 0;
    int bestCurrency = 0;
    int bestAny = 0;

    for (final line in lines) {
      final amounts = _extractAmountsFromLine(line);
      if (amounts.isEmpty) {
        continue;
      }
      final lineBest = amounts.reduce(max);
      final normalizedLine = _normalizeSpanishToken(line);

      if (_hasTotalHint(normalizedLine)) {
        bestPreferred = max(bestPreferred, lineBest);
      }
      if (_hasCurrencyHint(normalizedLine)) {
        bestCurrency = max(bestCurrency, lineBest);
      }
      bestAny = max(bestAny, lineBest);
    }

    if (bestPreferred > 0) {
      return bestPreferred;
    }
    if (bestCurrency > 0) {
      return bestCurrency;
    }
    if (bestAny > 0) {
      return bestAny;
    }

    final expandedThousands = RegExp(
      r'(?<!\d)(\d{1,3})\s*(mil|miles)',
      caseSensitive: false,
    );
    var best = 0;
    for (final match in expandedThousands.allMatches(text)) {
      final base = int.tryParse(match.group(1) ?? '') ?? 0;
      if (base > 0) {
        best = max(best, base * 1000);
      }
    }

    final numericMatches = RegExp(
      r'(?<!\d)(\d{1,3}(?:[.,\s]\d{3})+|\d{4,})(?:[.,]\d{1,2})?',
      caseSensitive: false,
    );
    for (final match in numericMatches.allMatches(text)) {
      final parsed = _parseAmount(match.group(1));
      if (parsed > best) {
        best = parsed;
      }
    }

    if (best > 0) {
      return best;
    }
    return _parseAmountFromSpanishWords(text);
  }

  int _parseAmount(String? raw) {
    if (raw == null) return 0;
    return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0;
  }

  bool _hasTotalHint(String normalizedLine) {
    const hints = [
      'total',
      'importe',
      'a pagar',
      'monto',
      'total final',
      'total gs',
      'monto total',
      'saldo',
    ];
    return hints.any(normalizedLine.contains);
  }

  bool _hasCurrencyHint(String normalizedLine) {
    return normalizedLine.contains('gs') ||
        normalizedLine.contains('pyg') ||
        normalizedLine.contains('guarani') ||
        normalizedLine.contains('g.');
  }

  List<int> _extractAmountsFromLine(String line) {
    final amounts = <int>[];
    final fixedLine = _normalizeOcrAmountToken(line);
    final amountMatches = RegExp(
      r'(?<!\d)(\d{1,3}(?:[.,\s]\d{3})+|\d{4,})(?:[.,]\d{1,2})?',
    ).allMatches(fixedLine);

    for (final match in amountMatches) {
      final amount = _parseAmount(match.group(0));
      if (amount < 100 || amount > 200000000) {
        continue;
      }
      amounts.add(amount);
    }
    return amounts;
  }

  String _normalizeOcrAmountToken(String raw) {
    return raw
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5');
  }

  String _guessCategory(String merchant) {
    final lower = merchant.toLowerCase();
    if (lower.contains('farm') ||
        lower.contains('stock') ||
        lower.contains('super')) {
      return 'Variables';
    }
    if (lower.contains('personal') ||
        lower.contains('internet') ||
        lower.contains('alquiler')) {
      return 'Fijos';
    }
    return 'Variables';
  }

  int _parseAmountFromSpanishWords(String raw) {
    final tokens = RegExp(
      r'[a-zA-ZáéíóúñÁÉÍÓÚÑ]+',
    ).allMatches(raw).map((m) => _normalizeSpanishToken(m.group(0)!)).toList();
    if (tokens.isEmpty) {
      return 0;
    }

    const units = {
      'cero': 0,
      'un': 1,
      'uno': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
      'once': 11,
      'doce': 12,
      'trece': 13,
      'catorce': 14,
      'quince': 15,
      'dieciseis': 16,
      'diecisiete': 17,
      'dieciocho': 18,
      'diecinueve': 19,
      'veinte': 20,
      'veintiun': 21,
      'veintiuno': 21,
      'veintidos': 22,
      'veintitres': 23,
      'veinticuatro': 24,
      'veinticinco': 25,
      'veintiseis': 26,
      'veintisiete': 27,
      'veintiocho': 28,
      'veintinueve': 29,
    };
    const tens = {
      'treinta': 30,
      'cuarenta': 40,
      'cincuenta': 50,
      'sesenta': 60,
      'setenta': 70,
      'ochenta': 80,
      'noventa': 90,
    };
    const hundreds = {
      'cien': 100,
      'ciento': 100,
      'doscientos': 200,
      'trescientos': 300,
      'cuatrocientos': 400,
      'quinientos': 500,
      'seiscientos': 600,
      'setecientos': 700,
      'ochocientos': 800,
      'novecientos': 900,
    };
    const ignored = {
      'y',
      'de',
      'gs',
      'g',
      'guarani',
      'guaranies',
      'pyg',
      'por',
      'en',
    };

    var usedWords = false;
    var total = 0;
    var current = 0;

    for (final token in tokens) {
      if (ignored.contains(token)) {
        continue;
      }
      if (hundreds.containsKey(token)) {
        current += hundreds[token]!;
        usedWords = true;
        continue;
      }
      if (tens.containsKey(token)) {
        current += tens[token]!;
        usedWords = true;
        continue;
      }
      if (units.containsKey(token)) {
        current += units[token]!;
        usedWords = true;
        continue;
      }
      if (token == 'mil' || token == 'miles') {
        if (current == 0) {
          current = 1;
        }
        total += current * 1000;
        current = 0;
        usedWords = true;
        continue;
      }
      if (token == 'millon' || token == 'millones') {
        if (current == 0) {
          current = 1;
        }
        total += current * 1000000;
        current = 0;
        usedWords = true;
        continue;
      }
    }

    if (!usedWords) {
      return 0;
    }
    return total + current;
  }

  String _normalizeSpanishToken(String input) {
    return input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  String _guessMerchantFromText(
    String text, {
    String fallback = 'Movimiento detectado',
  }) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.length >= 3)
        .toList();
    const blockedWords = [
      'total',
      'subtotal',
      'ruc',
      'timbrado',
      'fecha',
      'hora',
      'ticket',
      'transaccion',
      'numero',
      'nro',
      'cajero',
      'iva',
      'autorizacion',
      'saldo',
    ];

    for (final line in lines) {
      final normalizedLine = _normalizeSpanishToken(line);
      if (RegExp(r'\d').hasMatch(line)) {
        continue;
      }
      if (blockedWords.any(normalizedLine.contains)) {
        continue;
      }
      final candidate = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (candidate.isEmpty) {
        continue;
      }
      return candidate.length <= 32
          ? candidate
          : '${candidate.substring(0, 32)}...';
    }

    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return fallback;
    }
    return cleaned.length <= 32 ? cleaned : '${cleaned.substring(0, 32)}...';
  }

  void _commitVoiceCapture(String transcript) {
    if (_voiceResultCommitted) {
      return;
    }
    _voiceResultCommitted = true;
    final normalized = transcript.trim();
    final amount = _parseAnyAmount(normalized);
    final merchant = _guessMerchantFromText(
      normalized,
      fallback: 'Gasto por voz',
    );
    final category = _guessCategory(normalized);

    if (amount <= 0) {
      _setVoiceDraft(
        transcript: normalized,
        merchant: merchant,
        category: category,
        amountPyg: 0,
      );
      _integrationMessage =
          'Voz recibida, pero sin monto claro. Abrí "Movimientos" y tocá "Completar voz".';
      notifyListeners();
      return;
    }

    _clearVoiceDraft();
    _addCapturedTransaction(
      amountPyg: amount,
      merchant: merchant,
      category: category,
      source: TransactionSource.voice,
      isIncome: false,
      notify: false,
    );
    _integrationMessage =
        'Voz registro ${formatPyg(amount)} en "$merchant". Podés editar o borrar en Movimientos.';
    notifyListeners();
  }

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';

  void _notifyBudgetAlert(String category) {
    final budget = budgets.firstWhere(
      (b) => b.name == category,
      orElse: () => budgets.first,
    );
    final percent = ((budget.spentPyg / budget.limitPyg) * 100)
        .clamp(0, 999)
        .round();
    if (!alertThresholds.contains(percent) && percent <= 100) return;

    final now = DateTime.now();
    if (_lastPushAt != null && _sameDay(_lastPushAt!, now)) return;

    _lastPushAt = now;
    _lastPushMessage =
        'Presupuesto $category en $percent%. Recordatorio diario enviado ($maxPushesPerDay/$maxPushesPerDay).';
    unawaited(
      _postDailyNotification(
        'Anshin presupuesto',
        'Categoria $category alcanzo $percent% del limite.',
      ),
    );
  }

  Future<void> _postDailyNotification(String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'anshin_daily_channel',
        'Anshin Daily',
        channelDescription: 'Alertas diarias de presupuesto',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await _notifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {}
  }

  void _applyStreakReward() {
    if (_streakDays == 7) {
      _lastPushMessage = 'Recompensa: desbloqueaste 7 dias de premium.';
    }
    if (_streakDays == 30) {
      _lastPushMessage = 'Recompensa: desbloqueaste 15 dias de premium.';
    }
    if (_streakDays == 90) {
      _lastPushMessage = 'Recompensa: desbloqueaste 1 mes de premium.';
    }
  }

  void _maybeCreateWeeklyReport() {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;
    _lastWeeklyReport =
        'Reporte semanal: gastaste ${formatPyg(totalExpensesPyg)} y cerraste con ${formatPyg(availableTodayPyg)}.';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
