part of '../../../main.dart';

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
                  state.isListeningVoice || state.isStartingVoice
                      ? 'Detener voz'
                      : 'Escuchar gasto',
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
