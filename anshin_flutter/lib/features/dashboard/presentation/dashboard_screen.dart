part of '../../../main.dart';

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
    final showVoiceOverlay =
        state.isStartingVoice ||
        state.isListeningVoice ||
        state.liveVoiceText.trim().isNotEmpty;

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
        if (showVoiceOverlay)
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                child: VoiceCaptureIndicator(
                  isStarting: state.isStartingVoice,
                  isListening: state.isListeningVoice,
                  transcript: state.liveVoiceText,
                  onStop: () => state.toggleVoiceCapture(),
                ),
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
                  state.isListeningVoice || state.isStartingVoice
                      ? Icons.mic_off_rounded
                      : Icons.keyboard_voice_rounded,
                ),
                label: Text(
                  state.isListeningVoice || state.isStartingVoice
                      ? 'Detener voz'
                      : 'Escuchar gasto',
                ),
              ),
            ],
          ),
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
