import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/playlist_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final ValueChanged<int> onSectionSelected;

  const HomeDashboardScreen({super.key, required this.onSectionSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(allChannelsProvider);
    final movies = ref.watch(allMoviesProvider);
    final series = ref.watch(allSeriesProvider);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (constraints.maxHeight - 80).clamp(0.0, double.infinity),
          ),
          child: Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 24,
              children: [
                _HomeSectionCard(
                  key: const ValueKey('live-tv-card'),
                  icon: Icons.live_tv_outlined,
                  title: 'TV AO VIVO',
                  countLabel: _countLabel(
                    channels,
                    singular: 'Canal',
                    plural: 'Canais',
                  ),
                  liveBadge: true,
                  autofocus: true,
                  onTap: () => onSectionSelected(1),
                ),
                _HomeSectionCard(
                  key: const ValueKey('movies-card'),
                  icon: Icons.movie_creation_outlined,
                  title: 'Filmes',
                  countLabel: _countLabel(
                    movies,
                    singular: 'Titulo',
                    plural: 'Titulos',
                  ),
                  onTap: () => onSectionSelected(2),
                ),
                _HomeSectionCard(
                  key: const ValueKey('series-card'),
                  icon: Icons.video_library_outlined,
                  title: 'Series',
                  countLabel: _countLabel(
                    series,
                    singular: 'Titulo',
                    plural: 'Titulos',
                  ),
                  onTap: () => onSectionSelected(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _countLabel<T>(
    AsyncValue<List<T>> value, {
    required String singular,
    required String plural,
  }) {
    return value.when(
      data: (items) =>
          '${items.length} ${items.length == 1 ? singular : plural}',
      loading: () => 'Carregando...',
      error: (_, _) => 'Indisponivel',
    );
  }
}

class _HomeSectionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String countLabel;
  final bool liveBadge;
  final bool autofocus;
  final VoidCallback onTap;

  const _HomeSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.countLabel,
    required this.onTap,
    this.liveBadge = false,
    this.autofocus = false,
  });

  @override
  State<_HomeSectionCard> createState() => _HomeSectionCardState();
}

class _HomeSectionCardState extends State<_HomeSectionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final highlighted = _hovered || _focused;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 220,
        height: 200,
        transform: Matrix4.translationValues(0, highlighted ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: highlighted
              ? colors.surfaceContainerHigh
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? colors.primary.withValues(alpha: .7)
                : colors.outlineVariant,
            width: _focused ? 2 : 1,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .28),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            autofocus: widget.autofocus,
            onFocusChange: (value) => setState(() => _focused = value),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.liveBadge) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: colors.onErrorContainer,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AO VIVO',
                            style: TextStyle(
                              color: colors.onErrorContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ] else
                    const SizedBox(height: 28),
                  Icon(widget.icon, size: 48, color: colors.onSurfaceVariant),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFF42C65A),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          widget.countLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
