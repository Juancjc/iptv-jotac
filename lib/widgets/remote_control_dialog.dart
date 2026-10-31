import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/remote_control_providers.dart';

/// Shows the QR code / address for the phone, the remote control options and
/// lets the user turn it off.
class RemoteControlDialog extends ConsumerWidget {
  const RemoteControlDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    final theme = Theme.of(context);
    final url = remote.url;

    Widget status;
    if (remote.error != null) {
      status = Text(remote.error!, style: TextStyle(color: theme.colorScheme.error));
    } else if (url == null) {
      status = remote.starting
          ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
          : const Text('O controle pelo celular esta desligado.');
    } else {
      status = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed size: AlertDialog measures intrinsic widths, which the QR
          // widget (built on LayoutBuilder) can't answer.
          SizedBox(
            width: 186,
            height: 186,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: url.toString(), size: 170),
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Leia o QR code com o celular (mesma rede Wi-Fi) ou abra no navegador:'),
                const SizedBox(height: 8),
                SelectableText(
                  url.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No celular, escolha entre usar so o controle (setas e OK) '
                  'ou escolher direto o que assistir: listas, canais, filmes '
                  'e series, com busca.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Controle pelo celular'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [status, const SizedBox(height: 12), const RemoteControlOptions()],
          ),
        ),
      ),
      actions: [
        if (remote.active)
          TextButton(
            onPressed: () {
              ref.read(remoteControlProvider.notifier).disable();
              Navigator.of(context).pop();
            },
            child: const Text('Desativar'),
          )
        else if (!remote.starting)
          TextButton(
            onPressed: () => ref.read(remoteControlProvider.notifier).enable(),
            child: const Text('Ativar'),
          ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(remote.active ? 'Manter ativo' : 'Fechar'),
        ),
      ],
    );
  }
}

/// The saved choices for the phone remote control, shared by the dialog and
/// the settings screen.
class RemoteControlOptions extends ConsumerWidget {
  const RemoteControlOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    final prefs = remote.preferences;
    final notifier = ref.read(remoteControlProvider.notifier);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ligar sempre ao abrir o app'),
          subtitle: const Text('O controle pelo celular fica ativo sem precisar confirmar.'),
          value: prefs.autoStart,
          onChanged: (value) {
            notifier.setAutoStart(value);
            if (value && !remote.active) notifier.enable();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Manter o mesmo endereco'),
          subtitle: const Text(
            'O link do celular continua valendo quando o app reinicia. '
            'Salve a pagina nos favoritos do navegador.',
          ),
          value: prefs.keepAddress,
          onChanged: notifier.setKeepAddress,
        ),
        if (prefs.keepAddress)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Gerar novo codigo (desconecta os celulares atuais)'),
              onPressed: notifier.regenerateAccessCode,
            ),
          ),
      ],
    );
  }
}
