import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';

class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key});

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
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              Text('Adicionar lista', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TabBar(controller: _tabController, tabs: const [Tab(text: 'URL M3U'), Tab(text: 'Xtream Codes')]),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildM3uForm(), _buildXtreamForm()],
                ),
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
                    builder: (context, _) => FilledButton(
                      onPressed: _submitting ? null : (_tabController.index == 0 ? _submitM3u : _submitXtream),
                      child: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Adicionar'),
                    ),
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _m3uUrlController,
            decoration: const InputDecoration(labelText: 'URL do M3U/M3U8'),
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
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _xtreamHostController,
            decoration: const InputDecoration(labelText: 'Host (http(s)://host:porta)'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o host' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _xtreamUserController,
            decoration: const InputDecoration(labelText: 'Usuario'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o usuario' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _xtreamPassController,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a senha' : null,
          ),
        ],
      ),
    );
  }
}
