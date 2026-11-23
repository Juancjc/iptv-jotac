import 'package:flutter/material.dart';
import 'remote_content_action.dart';

/// A poster/logo card used across the live TV, movies and series grids.
class ContentCard extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final double? progress;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDownload;

  const ContentCard({
    super.key,
    required this.title,
    required this.onTap,
    this.imageUrl,
    this.subtitle,
    this.progress,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.onDownload,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _focused = false;
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _focused || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: RemoteContentAction(
            onToggleFavorite: widget.onToggleFavorite,
            onTap: widget.onTap,
            onFocusChange: (focused) {
              setState(() => _focused = focused);
              if (focused) {
                Scrollable.ensureVisible(
                  context,
                  alignment: .5,
                  duration: const Duration(milliseconds: 180),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Poster(imageUrl: widget.imageUrl),
                      if (active)
                        const Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      if (_focused && widget.onToggleFavorite != null)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          right: 6,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: Colors.black87),
                            child: Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                widget.isFavorite
                                    ? 'Segure OK: remover favorito'
                                    : 'Segure OK: favoritar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.onToggleFavorite != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: widget.isFavorite
                                  ? 'Remover dos favoritos'
                                  : 'Adicionar aos favoritos',
                              iconSize: 18,
                              icon: Icon(
                                widget.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: widget.isFavorite
                                    ? theme.colorScheme.primary
                                    : Colors.white,
                              ),
                              onPressed: widget.onToggleFavorite,
                            ),
                          ),
                        ),
                      if (widget.onDownload != null)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Material(
                            color: Colors.black45,
                            shape: const CircleBorder(),
                            child: IconButton(
                              iconSize: 18,
                              tooltip: 'Baixar',
                              icon: const Icon(
                                Icons.download_outlined,
                                color: Colors.white,
                              ),
                              onPressed: widget.onDownload,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.progress != null)
                  LinearProgressIndicator(
                    value: widget.progress!.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final String? imageUrl;
  const _Poster({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final background = Theme.of(context).colorScheme.surfaceContainerHighest;
    if (url == null || url.isEmpty) {
      return ColoredBox(
        color: background,
        child: const Center(child: Icon(Icons.live_tv, size: 36)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 360,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: background,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 36)),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return ColoredBox(
          color: background,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
