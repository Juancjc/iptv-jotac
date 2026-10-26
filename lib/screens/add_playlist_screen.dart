import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/playlist.dart';
import '../providers/database_provider.dart';
import '../providers/playlist_providers.dart';
import '../services/qr_pairing_server.dart';

/// Dialog to register a new playlist or, when [playlist] is given, edit an
/// existing one (name and source) and optionally fetch its content again.
class AddPlaylistScreen extends ConsumerStatefulWidget {
  final Playlist? playlist;

  const AddPlaylistScreen({super.key, this.playlist});

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _m3uFormKey = GlobalKey<FormState>();
  final _xtreamFormKey = GlobalKey<FormState>();

  final _m3uNameController = TextEditingController();
  final _m3uUrlController = TextEditingController();

  final _xtreamNameController = TextEditingController();
  final _xtreamHostController = TextEditingController();
  final _xtreamUserController = TextEditingController();
  final _xtreamPassController = TextEditingController();

  bool _submitting = false;
  bool _syncAfterSave = true;
  String? _error;

  bool get _isEditing => widget.playlist != null;

  @override
  void initState() {
    super.initState();
    final playlist = widget.playlist;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: playlist?.type == PlaylistType.xtream ? 1 : 0,
    );
    if (playlist != null) {
      if (playlist.type == PlaylistType.m3u) {
        _m3uNameController.text = playlist.name;
        _m3uUrlController.text = playlist.m3uUrl ?? '';
      } else {
        _xtreamNameController.text = playlist.name;
        _xtreamHostController.text = playlist.xtreamHost ?? '';
        _xtreamUserController.text = playlist.xtreamUsername ?? '';
        _xtreamPassController.text = playlist.xtreamPassword ?? '';
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _m3uNameController.dispose();
    _m3uUrlController.dispose();
    _xtreamNameController.dispose();
    _xtreamHostController.dispose();
    _xtreamUserController.dispose();
    _xtreamPassController.dispose();
    super.dispose();
  }

  Future<void> _submitM3u() async {
    if (!_m3uFormKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final editing = widget.playlist;
      if (editing != null) {
        await _saveEdits(
          editing.copyWith(name: _m3uNameController.text.trim(), m3uUrl: _m3uUrlController.text.trim()),
        );
        return;
      }
      final repo = ref.read(playlistRepositoryProvider);
      final playlist = await repo.addM3uPlaylist(
        name: _m3uNameController.text.trim(),
        url: _m3uUrlController.text.trim(),
      );
      await repo.syncPlaylist(playlist);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Falha ao carregar lista: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitXtream() async {
    if (!_xtreamFormKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final editing = widget.playlist;
      if (editing != null) {
        await _saveEdits(
          editing.copyWith(
            name: _xtreamNameController.text.trim(),
            xtreamHost: _xtreamHostController.text.trim(),
            xtreamUsername: _xtreamUserController.text.trim(),
            xtreamPassword: _xtreamPassController.text.trim(),
          ),
        );
        return;
      }
      final repo = ref.read(playlistRepositoryProvider);
      final playlist = await repo.addXtreamPlaylist(
        name: _xtreamNameController.text.trim(),
        host: _xtreamHostController.text.trim(),
        username: _xtreamUserController.text.trim(),
        password: _xtreamPassController.text.trim(),
      );
      await repo.syncPlaylist(playlist);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Falha ao conectar: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveEdits(Playlist edited) async {
    final updated = await ref.read(playlistRepositoryProvider).updatePlaylist(edited);
    if (_syncAfterSave) {
      await ref.read(playlistSyncControllerProvider).sync(updated);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isEditing ? 'Editar lista' : 'Adicionar lista', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (!_isEditing)
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'URL M3U'),
                    Tab(text: 'Xtream Codes'),
                    Tab(icon: Icon(Icons.qr_code, size: 18), text: 'QR Code'),
                  ],
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    switch (_tabController.index) {
                      case 0:
                        return _buildM3uForm();
                      case 1:
                        return _buildXtreamForm();
                      default:
                        return _QrPairingTab(onAdded: () {
                          if (mounted) Navigator.of(context).pop();
                        });
                    }
                  },
                ),
              ),
              if (_isEditing)
                CheckboxListTile(
                  value: _syncAfterSave,
                  onChanged: _submitting ? null : (value) => setState(() => _syncAfterSave = value ?? true),
                  title: const Text('Atualizar o conteudo da lista ao salvar'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 2) return const SizedBox.shrink();
                      return FilledButton(
                        onPressed: _submitting ? null : (_tabController.index == 0 ? _submitM3u : _submitXtream),
                        child: _submitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isEditing ? 'Salvar' : 'Adicionar'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildM3uForm() {
    return Form(
      key: _m3uFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _m3uNameController,
            decoration: const InputDecoration(labelText: 'Nome da lista'),
            autofocus: true,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _m3uUrlController,
            decoration: const InputDecoration(labelText: 'URL do M3U/M3U8'),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitM3u(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe a URL';
              final uri = Uri.tryParse(v.trim());
              if (uri == null || !uri.hasScheme) return 'URL invalida';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildXtreamForm() {
    return Form(
      key: _xtreamFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _xtreamNameController,
            decoration: const InputDecoration(labelText: 'Nome da lista'),
            autofocus: true,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _xtreamHostController,
            decoration: const InputDecoration(labelText: 'Host (http(s)://host:porta)'),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o host' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _xtreamUserController,
            decoration: const InputDecoration(labelText: 'Usuario'),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o usuario' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _xtreamPassController,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitXtream(),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a senha' : null,
          ),
        ],
      ),
    );
  }
}

/// Shows a QR code pointing to a tiny local web form so the playlist can be
/// typed on a phone instead of with a TV remote. The pairing server is only
/// alive while this tab is mounted (i.e. while it is the selected tab).
class _QrPairingTab extends ConsumerStatefulWidget {
  final VoidCallback onAdded;

  const _QrPairingTab({required this.onAdded});

  @override
  ConsumerState<_QrPairingTab> createState() => _QrPairingTabState();
}

class _QrPairingTabState extends ConsumerState<_QrPairingTab> {
  final _server = QrPairingServer();
  StreamSubscription<PairingSubmission>? _subscription;
  Uri? _url;
  String? _startError;
  String? _submissionError;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final url = await _server.start();
      _subscription = _server.submissions.listen(_handleSubmission);
      if (mounted) setState(() => _url = url);
    } catch (e) {
      if (mounted) setState(() => _startError = 'Nao foi possivel iniciar o servidor local: $e');
    }
  }

  Future<void> _handleSubmission(PairingSubmission submission) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _submissionError = null;
    });
    try {
      final repo = ref.read(playlistRepositoryProvider);
      final playlist = submission.isXtream
          ? await repo.addXtreamPlaylist(
              name: submission.name,
              host: submission.xtreamHost!,
              username: submission.xtreamUsername!,
              password: submission.xtreamPassword!,
            )
          : await repo.addM3uPlaylist(name: submission.name, url: submission.m3uUrl!);
      await repo.syncPlaylist(playlist);
      widget.onAdded();
    } catch (e) {
      if (mounted) setState(() => _submissionError = 'Falha ao adicionar a lista recebida: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_startError != null) {
      return Center(
        child: Text(_startError!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
      );
    }

    final url = _url;
    if (url == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final link = url.toString();
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            'Aponte a camera do celular para o QR code abaixo',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: QrImageView(data: link, size: 170, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'Ou acesse pelo navegador do celular:',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          SelectableText(link, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (_processing)
            const CircularProgressIndicator()
          else
            Text(
              'Aguardando dados do celular...',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          if (_submissionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_submissionError!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
            ),
        ],
      ),
    );
  }
}
