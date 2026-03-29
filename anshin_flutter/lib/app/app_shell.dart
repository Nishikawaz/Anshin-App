part of '../main.dart';

void main() {
  runApp(const AnshinApp());
}

String withThousandsDots(String digits) {
  if (digits.isEmpty) {
    return '';
  }
  final reversed = digits.split('').reversed.toList();
  final buffer = StringBuffer();
  for (int i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(reversed[i]);
  }
  return buffer.toString().split('').reversed.join();
}

int parsePygAmount(String raw) {
  return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0;
}

class BudgetSplit {
  const BudgetSplit({
    required this.fixedPct,
    required this.variablePct,
    required this.savingsPct,
  });

  final int fixedPct;
  final int variablePct;
  final int savingsPct;

  int get total => fixedPct + variablePct + savingsPct;
}

class BudgetPreset {
  const BudgetPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.split,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final BudgetSplit split;
  final bool isCustom;
}

const balancedPreset = BudgetPreset(
  id: 'balanced',
  name: 'Modo equilibrado',
  description: 'Fijos 60% • Variables 30% • Ahorro 10%',
  split: BudgetSplit(fixedPct: 60, variablePct: 30, savingsPct: 10),
);

const savingPreset = BudgetPreset(
  id: 'saving',
  name: 'Modo ahorro',
  description: 'Fijos 50% • Variables 30% • Ahorro 20%',
  split: BudgetSplit(fixedPct: 50, variablePct: 30, savingsPct: 20),
);

const survivalPreset = BudgetPreset(
  id: 'survival',
  name: 'Modo supervivencia',
  description: 'Fijos 70% • Variables 20% • Ahorro 10%',
  split: BudgetSplit(fixedPct: 70, variablePct: 20, savingsPct: 10),
);

const customPreset = BudgetPreset(
  id: 'custom',
  name: 'Modo custom',
  description: 'El usuario define sus porcentajes',
  split: BudgetSplit(fixedPct: 60, variablePct: 30, savingsPct: 10),
  isCustom: true,
);

const onboardingPresets = <BudgetPreset>[
  balancedPreset,
  savingPreset,
  survivalPreset,
  customPreset,
];

class AnshinApp extends StatefulWidget {
  const AnshinApp({super.key});

  @override
  State<AnshinApp> createState() => _AnshinAppState();
}

class _AnshinAppState extends State<AnshinApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1F242A) : Colors.white,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF14181D) : Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1F24) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 48,
          height: 1.05,
          color: scheme.onSurface,
        ),
        displaySmall: GoogleFonts.dmSans(
          fontSize: 34,
          height: 1.1,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 22,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          height: 1.45,
          color: scheme.onSurface,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          height: 1.38,
          color: scheme.onSurface.withValues(alpha: 0.82),
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lightPrimary = Color(0xFF1A4A31);
    const darkPrimary = Color(0xFF68C08D);

    final lightScheme = ColorScheme.fromSeed(
      seedColor: lightPrimary,
      brightness: Brightness.light,
      primary: lightPrimary,
      surface: const Color(0xFFF4F7F5),
      onSurface: const Color(0xFF1F2925),
      secondary: const Color(0xFF2D7E53),
      tertiary: const Color(0xFF6FAE89),
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      brightness: Brightness.dark,
      primary: darkPrimary,
      surface: const Color(0xFF101418),
      onSurface: const Color(0xFFE2F2EA),
      secondary: const Color(0xFF4BAE78),
      tertiary: const Color(0xFF8BC8A8),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Anshin',
      theme: _buildTheme(lightScheme),
      darkTheme: _buildTheme(darkScheme),
      themeMode: _themeMode,
      home: RootScreen(
        themeMode: _themeMode,
        onToggleThemeMode: _toggleThemeMode,
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.themeMode,
    required this.onToggleThemeMode,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleThemeMode;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final appState = AnshinState();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final TextEditingController _salaryController = TextEditingController();

  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;
  GoogleSignInAccount? _account;
  bool _googleReady = false;
  bool _isSigningIn = false;
  bool _setupCompleted = false;
  String? _authError;
  int _selectedTab = 0;
  BudgetPreset _selectedPreset = balancedPreset;
  double _customFixed = 60;
  double _customVariable = 30;
  bool _isFormattingSalary = false;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeApp());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _salaryController.dispose();
    appState.disposeIntegrations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_account == null) {
      return _buildAuthScreen(context);
    }

    if (!_setupCompleted) {
      return _buildOnboardingScreen(context);
    }

    final screens = [
      DashboardScreen(state: appState),
      TransactionsScreen(state: appState),
      BudgetScreen(state: appState),
      StreakScreen(state: appState),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anshin'),
        actions: [
          IconButton(
            tooltip: widget.themeMode == ThemeMode.light
                ? 'Activar modo oscuro'
                : 'Activar modo claro',
            onPressed: widget.onToggleThemeMode,
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
          ),
          if (_account?.photoUrl case final photo?)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(backgroundImage: NetworkImage(photo)),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) => screens[_selectedTab],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (value) {
          setState(() => _selectedTab = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Movimientos',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Presupuesto',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_fire_department_rounded),
            label: 'Racha',
          ),
        ],
      ),
    );
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      const clientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
      const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
      await _googleSignIn.initialize(
        clientId: clientId.isEmpty ? null : clientId,
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      );
      _authSub = _googleSignIn.authenticationEvents.listen(
        (event) {
          switch (event) {
            case GoogleSignInAuthenticationEventSignIn(:final user):
              if (!mounted) {
                return;
              }
              setState(() {
                _account = user;
                _authError = null;
                _setupCompleted = appState.hasUserBudgetConfig;
              });
            case GoogleSignInAuthenticationEventSignOut():
              if (!mounted) {
                return;
              }
              setState(() {
                _account = null;
                _setupCompleted = appState.hasUserBudgetConfig;
              });
          }
        },
        onError: (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _authError =
                'No se pudo conectar Google ahora. Revisá configuración OAuth.';
          });
        },
      );
      final attempt = _googleSignIn.attemptLightweightAuthentication();
      if (attempt != null) {
        final restoredUser = await attempt;
        if (restoredUser != null && mounted) {
          setState(() {
            _account = restoredUser;
            _setupCompleted = appState.hasUserBudgetConfig;
          });
        }
      }
      if (mounted) {
        setState(() => _googleReady = true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _googleReady = true;
        _authError =
            'Google Sign-In no está listo en este entorno. Probá en Android con OAuth configurado.';
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_googleReady) {
      return;
    }
    if (!_googleSignIn.supportsAuthenticate()) {
      setState(() {
        _authError =
            'Este dispositivo no soporta autenticación directa de Google.';
      });
      return;
    }
    setState(() {
      _isSigningIn = true;
      _authError = null;
    });
    try {
      final user = await _googleSignIn.authenticate();
      if (!mounted) {
        return;
      }
      setState(() {
        _account = user;
        _setupCompleted = appState.hasUserBudgetConfig;
      });
    } on GoogleSignInException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authError =
            'Google Sign-In error: ${error.code.name}. ${error.description ?? ''}'
                .trim();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authError =
            'Inicio de sesión cancelado o fallido. Revisá la cuenta de Google e intentá de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _account = null;
      _setupCompleted = appState.hasUserBudgetConfig;
      _selectedTab = 0;
    });
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      appState.initializeIntegrations(),
      _restoreSavedSetup(),
      _initializeGoogleSignIn(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() => _isBootstrapping = false);
  }

  Future<void> _restoreSavedSetup() async {
    final restored = await appState.restoreBudgetPlanFromStorage();
    if (!mounted || !restored) {
      return;
    }
    _salaryController.text = withThousandsDots('${appState.monthlyIncomePyg}');
    _syncPresetWithState();
    setState(() => _setupCompleted = true);
  }

  void _syncPresetWithState() {
    final split = appState.budgetPlan;
    if (split.fixedPct == balancedPreset.split.fixedPct &&
        split.variablePct == balancedPreset.split.variablePct &&
        split.savingsPct == balancedPreset.split.savingsPct) {
      _selectedPreset = balancedPreset;
    } else if (split.fixedPct == savingPreset.split.fixedPct &&
        split.variablePct == savingPreset.split.variablePct &&
        split.savingsPct == savingPreset.split.savingsPct) {
      _selectedPreset = savingPreset;
    } else if (split.fixedPct == survivalPreset.split.fixedPct &&
        split.variablePct == survivalPreset.split.variablePct &&
        split.savingsPct == survivalPreset.split.savingsPct) {
      _selectedPreset = survivalPreset;
    } else {
      _selectedPreset = customPreset;
      _customFixed = split.fixedPct.toDouble();
      _customVariable = split.variablePct.toDouble();
    }
  }

  void _onSalaryChanged(String value) {
    if (_isFormattingSalary) {
      return;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = withThousandsDots(digits);
    if (formatted == _salaryController.text) {
      return;
    }
    _isFormattingSalary = true;
    _salaryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingSalary = false;
  }

  Widget _buildAuthScreen(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0E1613),
                    Color(0xFF184029),
                    Color(0xFF101418),
                  ]
                : const [
                    Color(0xFF1A4A31),
                    Color(0xFF2A7A4E),
                    Color(0xFFEEF8F2),
                  ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filledTonal(
                    tooltip: widget.themeMode == ThemeMode.light
                        ? 'Modo oscuro'
                        : 'Modo claro',
                    onPressed: widget.onToggleThemeMode,
                    icon: Icon(
                      widget.themeMode == ThemeMode.light
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'El orden\nes progreso',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: isDark ? scheme.onSurface : const Color(0xFFEEF8F2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ingresá para construir tu sistema financiero con calma y claridad.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? scheme.onSurface.withValues(alpha: 0.85)
                        : const Color(0xFFD4E8DD),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSigningIn ? null : _signInWithGoogle,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isSigningIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: Text(
                      _googleReady
                          ? 'Continuar con Google'
                          : 'Preparando Google Sign-In...',
                    ),
                  ),
                ),
                if (_authError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _authError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFFE1E1),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final customSavings = max(
      0,
      100 - _customFixed.round() - _customVariable.round(),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración inicial'),
        actions: [
          IconButton(
            tooltip: widget.themeMode == ThemeMode.light
                ? 'Modo oscuro'
                : 'Modo claro',
            onPressed: widget.onToggleThemeMode,
            icon: Icon(
              widget.themeMode == ThemeMode.light
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: [
          Text(
            'Hola ${_account?.displayName?.split(' ').first ?? 'usuario'}',
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Definí tu sueldo y elegí una plantilla para arrancar.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _salaryController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: _onSalaryChanged,
            decoration: const InputDecoration(
              labelText: 'Sueldo mensual en PYG',
              prefixText: 'Gs. ',
              border: OutlineInputBorder(),
              hintText: 'Ej: 5.000.000',
            ),
          ),
          const SizedBox(height: 18),
          ...onboardingPresets.map((preset) {
            final selected = _selectedPreset.id == preset.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => _selectedPreset = preset),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? scheme.primaryContainer
                        : (isDark ? const Color(0xFF1B2127) : Colors.white),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outlineVariant,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              preset.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_selectedPreset.isCustom) ...[
            const SizedBox(height: 8),
            _buildSliderCard(
              context: context,
              label: 'Fijos',
              value: _customFixed,
              max: 100,
              onChanged: (value) {
                setState(() {
                  _customFixed = value;
                  final currentMaxVariable = max<double>(0, 100 - _customFixed);
                  if (_customVariable > currentMaxVariable) {
                    _customVariable = currentMaxVariable;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            _buildSliderCard(
              context: context,
              label: 'Variables',
              value: _customVariable,
              max: max(0, 100 - _customFixed),
              onChanged: (value) {
                setState(() => _customVariable = value);
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1B2127)
                    : const Color(0xFFF4F7F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Ahorro: $customSavings%',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => _finishOnboarding(customSavings),
            child: const Text('Guardar y continuar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required BuildContext context,
    required String label,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2127)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${value.round()}%'),
          Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max == 0 ? 1 : max,
            onChanged: max == 0 ? null : onChanged,
          ),
        ],
      ),
    );
  }

  void _finishOnboarding(int customSavings) {
    final salary = parsePygAmount(_salaryController.text);
    if (salary <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresá un sueldo válido en PYG.')),
      );
      return;
    }

    final split = _selectedPreset.isCustom
        ? BudgetSplit(
            fixedPct: _customFixed.round(),
            variablePct: _customVariable.round(),
            savingsPct: customSavings,
          )
        : _selectedPreset.split;

    if (split.total != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La suma de porcentajes debe ser 100%.')),
      );
      return;
    }

    appState.configureBudgetPlan(
      salaryPyg: salary,
      plan: split,
      planName: _selectedPreset.name,
    );
    setState(() => _setupCompleted = true);
  }
}
