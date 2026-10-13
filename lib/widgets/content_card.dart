import 'package:flutter/material.dart';

/// A poster/logo card used across the live TV, movies and series grids.
class ContentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Poster(imageUrl: imageUrl),
                  if (onToggleFavorite != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          iconSize: 18,
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.redAccent : Colors.white,
                          ),
                          onPressed: onToggleFavorite,
                        ),
                      ),
                    ),
                  if (onDownload != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Material(
                        color: Colors.black45,
                        shape: const CircleBorder(),
                        child: IconButton(
                          iconSize: 18,
                          icon: const Icon(Icons.download_outlined, color: Colors.white),
                          onPressed: onDownload,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (progress != null)
              LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
          ],
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
