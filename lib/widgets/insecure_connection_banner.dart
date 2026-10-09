import 'package:flutter/material.dart';

/// Warns the user that a registered source uses plain HTTP, so credentials
/// and content travel unencrypted on the network.
class InsecureConnectionBanner extends StatelessWidget {
  const InsecureConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open, color: scheme.onErrorContainer, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conexao HTTP sem criptografia: usuario e senha trafegam em texto puro nesta rede.',
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
