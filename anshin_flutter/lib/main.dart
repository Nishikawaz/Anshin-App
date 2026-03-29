import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

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

class VoiceCaptureIndicator extends StatelessWidget {
  const VoiceCaptureIndicator({
    super.key,
    required this.isStarting,
    required this.isListening,
    required this.transcript,
    required this.onStop,
  });

  final bool isStarting;
  final bool isListening;
  final String transcript;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (!isStarting && !isListening && transcript.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final hasTranscript = transcript.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isListening
            ? scheme.errorContainer.withValues(alpha: 0.35)
            : scheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isListening ? scheme.error : scheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isListening || isStarting)
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isListening ? scheme.error : scheme.primary,
                      ),
                    Icon(
                      isStarting || isListening
                          ? Icons.mic_rounded
                          : Icons.check_circle_rounded,
                      color: isListening ? scheme.error : scheme.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isStarting
                      ? 'Iniciando micrófono...'
                      : (isListening
                            ? 'Grabando gasto por voz...'
                            : 'Voz detectada'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isListening || isStarting)
                TextButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Detener'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasTranscript
                ? '“${transcript.trim()}”'
                : 'Habla ahora, por ejemplo: gaste 45.000 en supermercado.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (isListening || isStarting) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 4),
          ],
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.state});
  final AnshinState state;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final buyController = TextEditingController();
  String? buyResult;
  bool _isFormattingBuy = false;

  @override
  void dispose() {
    buyController.dispose();
    super.dispose();
  }

  void _onBuyChanged(String value) {
    if (_isFormattingBuy) {
      return;
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = withThousandsDots(digits);
    if (formatted == buyController.text) {
      return;
    }
    _isFormattingBuy = true;
    buyController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingBuy = false;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cardTitle = state.formatPyg(state.availableTodayPyg);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF101418), const Color(0xFF141C17)]
                  : [const Color(0xFFEAF4EE), scheme.surface],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroCard(context, cardTitle),
                const SizedBox(height: 14),
                _quickActions(context, state),
                const SizedBox(height: 14),
                _buyCheckCard(context, state),
                const SizedBox(height: 14),
                _statusCard(context, state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroCard(BuildContext context, String cardTitle) {
    final scheme = Theme.of(context).colorScheme;
    final primarySoft = scheme.primary.withValues(alpha: 0.72);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, primarySoft],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anshin',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Disponible hoy (solo PYG)',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cardTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Moneda principal fija: PYG.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.84),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Plan: ${widget.state.budgetPlanName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.84),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, AnshinState state) {
    return _panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Captura bancaria automatica',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: state.connectBankNotifications,
                icon: const Icon(Icons.notifications_active_rounded),
                label: Text(
                  state.bankCaptureEnabled
                      ? 'Banco conectado'
                      : 'Conectar banco',
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: state.processOcrFromCamera,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Escanear ticket'),
              ),
              FilledButton.tonalIcon(
                onPressed: state.toggleVoiceCapture,
                icon: Icon(
                  state.isListeningVoice
                      ? Icons.mic_off_rounded
                      : Icons.keyboard_voice_rounded,
                ),
                label: Text(
                  state.isListeningVoice ? 'Detener voz' : 'Escuchar gasto',
                ),
              ),
            ],
          ),
          if (state.isStartingVoice ||
              state.isListeningVoice ||
              state.liveVoiceText.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            VoiceCaptureIndicator(
              isStarting: state.isStartingVoice,
              isListening: state.isListeningVoice,
              transcript: state.liveVoiceText,
              onStop: () => state.toggleVoiceCapture(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buyCheckCard(BuildContext context, AnshinState state) {
    return _panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Puedo comprar esto?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa un monto en PYG y la app te responde contra tu plan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: buyController,
            keyboardType: TextInputType.number,
            onChanged: _onBuyChanged,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Monto en PYG',
              hintText: 'Ejemplo: 120.000',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              final amount = parsePygAmount(buyController.text);
              setState(() {
                buyResult = state.canIBuy(amount);
              });
            },
            child: const Text('Evaluar compra'),
          ),
          if (buyResult != null) ...[
            const SizedBox(height: 8),
            Text(buyResult!, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context, AnshinState state) {
    final scheme = Theme.of(context).colorScheme;
    return _panel(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado del sistema',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Push por dia: ${AnshinState.maxPushesPerDay}. Racha actual: ${state.streakDays} dias.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Text(
            state.integrationMessage,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.primary),
          ),
          if (state.lastPushMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              state.lastPushMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.primary),
            ),
          ],
          if (state.lastWeeklyReport != null) ...[
            const SizedBox(height: 6),
            Text(
              state.lastWeeklyReport!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _panel({required BuildContext context, required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2127) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: child,
    );
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key, required this.state});
  final AnshinState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.transactions.where((t) => !t.isConfirmed).toList();
    final confirmed = state.transactions.where((t) => t.isConfirmed).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Movimientos', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'OCR y voz se registran automaticamente. Podés editar o borrar cada movimiento.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: state.processOcrFromCamera,
                child: const Text('Escanear ticket'),
              ),
              FilledButton.tonal(
                onPressed: state.toggleVoiceCapture,
                child: Text(
                  state.isListeningVoice ? 'Detener voz' : 'Escuchar gasto',
                ),
              ),
              FilledButton.tonal(
                onPressed: () => _showManualDialog(context, state),
                child: const Text('Agregar manual'),
              ),
            ],
          ),
          if (state.isStartingVoice ||
              state.isListeningVoice ||
              state.liveVoiceText.trim().isNotEmpty)
            const SizedBox(height: 10),
          if (state.isStartingVoice ||
              state.isListeningVoice ||
              state.liveVoiceText.trim().isNotEmpty)
            VoiceCaptureIndicator(
              isStarting: state.isStartingVoice,
              isListening: state.isListeningVoice,
              transcript: state.liveVoiceText,
              onStop: () => state.toggleVoiceCapture(),
            ),
          if (state.hasVoiceDraft) ...[
            const SizedBox(height: 10),
            Card(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.45),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completar voz',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No se pudo detectar el monto con precisión. Texto detectado:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“${state.voiceDraftTranscript}”',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              _showVoiceRecoveryDialog(context, state),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Completar voz'),
                        ),
                        OutlinedButton.icon(
                          onPressed: state.discardVoiceDraft,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Descartar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Pendientes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...pending.map((tx) => _pendingCard(context, tx)),
          ],
          const SizedBox(height: 18),
          Text('Confirmados', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (confirmed.isEmpty)
            const Text('Todavía no hay movimientos confirmados.')
          else
            ...confirmed.map((tx) => _confirmedCard(context, tx)),
        ],
      ),
    );
  }

  Widget _pendingCard(BuildContext context, TransactionEntry tx) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tx.merchant, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${state.formatPyg(tx.amountPyg)} • ${_sourceLabel(tx.source)}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: () => state.confirmPending(tx.id),
                  child: const Text('Confirmar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => state.rejectPending(tx.id),
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmedCard(BuildContext context, TransactionEntry tx) {
    final scheme = Theme.of(context).colorScheme;
    final amountLabel = tx.isIncome
        ? '+${state.formatPyg(tx.amountPyg)}'
        : state.formatPyg(tx.amountPyg);
    final amountColor = tx.isIncome ? scheme.primary : scheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.merchant,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text('${_sourceLabel(tx.source)} • ${tx.category}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Editar movimiento',
                      onPressed: () => _showEditDialog(context, state, tx),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: 'Borrar movimiento',
                      onPressed: () => _confirmDelete(context, state, tx),
                      icon: const Icon(Icons.delete_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(TransactionSource source) {
    switch (source) {
      case TransactionSource.bank:
        return 'Banco';
      case TransactionSource.manual:
        return 'Manual';
      case TransactionSource.ocr:
        return 'OCR';
      case TransactionSource.voice:
        return 'Voz';
    }
  }

  Future<void> _showVoiceRecoveryDialog(
    BuildContext context,
    AnshinState state,
  ) async {
    final amountController = TextEditingController(
      text: state.voiceDraftAmountPyg > 0
          ? withThousandsDots('${state.voiceDraftAmountPyg}')
          : '',
    );
    final merchantController = TextEditingController(
      text: state.voiceDraftMerchant.isEmpty
          ? 'Gasto por voz'
          : state.voiceDraftMerchant,
    );
    var isFormattingAmount = false;
    String category = state.voiceDraftCategory;

    void onAmountChanged(String value) {
      if (isFormattingAmount) {
        return;
      }
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final formatted = withThousandsDots(digits);
      if (formatted == amountController.text) {
        return;
      }
      isFormattingAmount = true;
      amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      isFormattingAmount = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Completar movimiento por voz'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Texto detectado: "${state.voiceDraftTranscript}"',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: onAmountChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Monto PYG',
                      hintText: 'Ej: 85.000',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(labelText: 'Comercio'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const ['Fijos', 'Variables', 'Ahorro']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => category = value);
                    },
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = parsePygAmount(amountController.text);
                    final merchant = merchantController.text.trim();
                    final saved = state.completeVoiceDraft(
                      amountPyg: amount,
                      merchant: merchant,
                      category: category,
                    );
                    if (!saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Revisá monto y comercio antes de guardar.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar movimiento'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showManualDialog(
    BuildContext context,
    AnshinState state,
  ) async {
    final amountController = TextEditingController();
    final merchantController = TextEditingController();
    var isFormattingAmount = false;
    String category = 'Variables';

    void onAmountChanged(String value) {
      if (isFormattingAmount) {
        return;
      }
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final formatted = withThousandsDots(digits);
      if (formatted == amountController.text) {
        return;
      }
      isFormattingAmount = true;
      amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      isFormattingAmount = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuevo movimiento manual'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: onAmountChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Monto PYG',
                      hintText: 'Ej: 85.000',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(labelText: 'Comercio'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const ['Fijos', 'Variables', 'Ahorro']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => category = value);
                    },
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = parsePygAmount(amountController.text);
                    if (amount <= 0 || merchantController.text.trim().isEmpty) {
                      return;
                    }
                    state.addManualTransaction(
                      amountPyg: amount,
                      merchant: merchantController.text.trim(),
                      category: category,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    AnshinState state,
    TransactionEntry tx,
  ) async {
    final amountController = TextEditingController(
      text: withThousandsDots('${tx.amountPyg}'),
    );
    final merchantController = TextEditingController(text: tx.merchant);
    var isFormattingAmount = false;
    String category = tx.category;

    void onAmountChanged(String value) {
      if (isFormattingAmount) {
        return;
      }
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final formatted = withThousandsDots(digits);
      if (formatted == amountController.text) {
        return;
      }
      isFormattingAmount = true;
      amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      isFormattingAmount = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar movimiento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: onAmountChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Monto PYG',
                      hintText: 'Ej: 85.000',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: merchantController,
                    decoration: const InputDecoration(labelText: 'Comercio'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    items: const ['Fijos', 'Variables', 'Ahorro']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => category = value);
                    },
                    decoration: const InputDecoration(labelText: 'Categoria'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = parsePygAmount(amountController.text);
                    final merchant = merchantController.text.trim();
                    if (amount <= 0 || merchant.isEmpty) {
                      return;
                    }
                    final updated = state.updateTransaction(
                      id: tx.id,
                      amountPyg: amount,
                      merchant: merchant,
                      category: category,
                    );
                    if (!updated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo editar el movimiento.'),
                        ),
                      );
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Movimiento actualizado.')),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar cambios'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AnshinState state,
    TransactionEntry tx,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Borrar movimiento'),
          content: Text('Se va a borrar "${tx.merchant}". ¿Continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );

    if (accepted == true) {
      if (!context.mounted) {
        return;
      }
      final deleted = state.deleteTransaction(tx.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted
                ? 'Movimiento borrado.'
                : 'No se pudo borrar el movimiento.',
          ),
        ),
      );
    }
  }
}

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key, required this.state});
  final AnshinState state;

  bool _sameSplit(BudgetSplit a, BudgetSplit b) {
    return a.fixedPct == b.fixedPct &&
        a.variablePct == b.variablePct &&
        a.savingsPct == b.savingsPct;
  }

  BudgetPreset _presetForCurrentPlan() {
    if (_sameSplit(state.budgetPlan, balancedPreset.split)) {
      return balancedPreset;
    }
    if (_sameSplit(state.budgetPlan, savingPreset.split)) {
      return savingPreset;
    }
    if (_sameSplit(state.budgetPlan, survivalPreset.split)) {
      return survivalPreset;
    }
    return customPreset;
  }

  Future<void> _showSalaryEditor(BuildContext context) async {
    final salaryController = TextEditingController(
      text: withThousandsDots('${state.monthlyIncomePyg}'),
    );
    var isFormattingSalary = false;

    void onSalaryChanged(String value) {
      if (isFormattingSalary) {
        return;
      }
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      final formatted = withThousandsDots(digits);
      if (formatted == salaryController.text) {
        return;
      }
      isFormattingSalary = true;
      salaryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
      isFormattingSalary = false;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Actualizar sueldo'),
          content: TextField(
            controller: salaryController,
            keyboardType: TextInputType.number,
            onChanged: onSalaryChanged,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Sueldo mensual en PYG',
              hintText: 'Ej: 5.000.000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final salary = parsePygAmount(salaryController.text);
                if (salary <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresá un sueldo válido en PYG.'),
                    ),
                  );
                  return;
                }
                state.configureBudgetPlan(
                  salaryPyg: salary,
                  plan: state.budgetPlan,
                  planName: state.budgetPlanName,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sueldo actualizado.')),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTemplatePicker(BuildContext context) async {
    var selectedPreset = _presetForCurrentPlan();
    var customFixed = state.budgetPlan.fixedPct.toDouble();
    var customVariable = state.budgetPlan.variablePct.toDouble();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final customSavings = max(
              0,
              100 - customFixed.round() - customVariable.round(),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cambiar plantilla',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ...onboardingPresets.map((preset) {
                    final selected = selectedPreset.id == preset.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setSheetState(() => selectedPreset = preset);
                        },
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(preset.name),
                                    Text(
                                      preset.description,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
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
                  if (selectedPreset.isCustom) ...[
                    const SizedBox(height: 8),
                    Text('Fijos: ${customFixed.round()}%'),
                    Slider(
                      value: customFixed,
                      min: 0,
                      max: 100,
                      onChanged: (value) {
                        setSheetState(() {
                          customFixed = value;
                          final maxVariable = max<double>(0, 100 - customFixed);
                          if (customVariable > maxVariable) {
                            customVariable = maxVariable;
                          }
                        });
                      },
                    ),
                    Text('Variables: ${customVariable.round()}%'),
                    Slider(
                      value: customVariable,
                      min: 0,
                      max: max(1, 100 - customFixed),
                      onChanged: (value) {
                        setSheetState(() => customVariable = value);
                      },
                    ),
                    Text('Ahorro: $customSavings%'),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (state.monthlyIncomePyg <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Primero definí tu sueldo en la configuración inicial.',
                              ),
                            ),
                          );
                          return;
                        }

                        final split = selectedPreset.isCustom
                            ? BudgetSplit(
                                fixedPct: customFixed.round(),
                                variablePct: customVariable.round(),
                                savingsPct: customSavings,
                              )
                            : selectedPreset.split;

                        if (split.total != 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La suma de porcentajes debe ser 100%.',
                              ),
                            ),
                          );
                          return;
                        }

                        state.configureBudgetPlan(
                          salaryPyg: state.monthlyIncomePyg,
                          plan: split,
                          planName: selectedPreset.name,
                        );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Plantilla actualizada a ${selectedPreset.name}.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Aplicar plantilla'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = state.budgets;
    final variableBudget = budgets.firstWhere(
      (budget) => budget.name == 'Variables',
      orElse: () => BudgetCategory(name: 'Variables', limitPyg: 0, spentPyg: 0),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            state.formatPyg(variableBudget.limitPyg),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tope mensual de Variables • ${state.budgetPlanName} (${state.budgetPlan.fixedPct}/${state.budgetPlan.variablePct}/${state.budgetPlan.savingsPct}) • Sueldo ${state.formatPyg(state.monthlyIncomePyg)} • Moneda fija: PYG.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showTemplatePicker(context),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Cambiar plantilla'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showSalaryEditor(context),
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Cambiar sueldo'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...budgets.map((b) {
            final ratio = (b.spentPyg / b.limitPyg).clamp(0.0, 1.5);
            final pct = (ratio * 100).round();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          b.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text('$pct%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: ratio > 1 ? 1 : ratio),
                    const SizedBox(height: 8),
                    Text(
                      '${state.formatPyg(b.spentPyg)} / ${state.formatPyg(b.limitPyg)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key, required this.state});
  final AnshinState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Racha', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Abrir app diariamente mantiene la racha. Si perdes el dia, se usa freeze si hay disponible.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              title: const Text('Dias consecutivos'),
              trailing: Text(
                '${state.streakDays}',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontSize: 30),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Freeze disponible'),
              trailing: Text('${state.freezeTokens}'),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: state.registerAppOpen,
            child: const Text('Registrar apertura de hoy'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: state.clearPushMessage,
            child: const Text('Limpiar aviso diario'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recompensas: 7 dias = 7d premium, 30 dias = 15d, 90 dias = 1 mes.',
          ),
        ],
      ),
    );
  }
}
