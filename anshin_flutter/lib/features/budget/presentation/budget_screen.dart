part of '../../../main.dart';

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
