import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/playlist_refresh_provider.dart';
import '../services/playlist_refresh_preferences.dart';

class PlaylistRefreshOptions extends ConsumerWidget {
  const PlaylistRefreshOptions({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(playlistRefreshPreferencesProvider);
    Future<void> save(PlaylistRefreshPreferences value) async {
      try {
        await ref.read(playlistRefreshPreferencesProvider.notifier).save(value);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível salvar a preferência. Tente novamente.',
              ),
            ),
          );
        }
      }
    }

    return preferences.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => ListTile(
        title: const Text('Não foi possível carregar as opções de atualização'),
        trailing: TextButton(
          onPressed: () => ref.invalidate(playlistRefreshPreferencesProvider),
          child: const Text('Tentar novamente'),
        ),
      ),
      data: (value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Atualização das listas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Atualizar ao iniciar o app'),
            subtitle: const Text(
              'Baixar as listas uma vez a cada abertura. Desligado, abre somente a biblioteca salva.',
            ),
            value: value.onStartup,
            onChanged: (enabled) => save(value.copyWith(onStartup: enabled)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Atualizar em horários definidos'),
            subtitle: const Text(
              'Todos os dias, no horário local do aparelho, enquanto o app estiver aberto. Horários perdidos com o app fechado não são recuperados.',
            ),
            value: value.scheduled,
            onChanged: (enabled) => save(value.copyWith(scheduled: enabled)),
          ),
          if (value.scheduled) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minute in value.minutes)
                  InputChip(
                    label: Text(
                      TimeOfDay(
                        hour: minute ~/ 60,
                        minute: minute % 60,
                      ).format(context),
                    ),
                    deleteButtonTooltipMessage: 'Remover horário',
                    onDeleted: () => save(
                      value.copyWith(
                        minutes: value.minutes
                            .where((m) => m != minute)
                            .toList(),
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Adicionar horário'),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 3, minute: 0),
                      initialEntryMode: TimePickerEntryMode.input,
                      helpText: 'Horário de atualização',
                    );
                    if (time == null || !context.mounted) return;
                    final times = {
                      ...value.minutes,
                      time.hour * 60 + time.minute,
                    }.toList()..sort();
                    await save(value.copyWith(minutes: times));
                  },
                ),
              ],
            ),
            if (value.minutes.isEmpty)
              const Text(
                'Adicione pelo menos um horário para ativar o agendamento.',
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            'O botão Atualizar listas continua disponível a qualquer momento. A atualização usa uma lista por vez e mantém o conteúdo salvo em caso de falha.',
          ),
        ],
      ),
    );
  }
}
