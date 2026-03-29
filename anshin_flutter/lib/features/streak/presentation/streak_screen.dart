part of '../../../main.dart';

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
