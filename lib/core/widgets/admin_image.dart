import 'package:flutter/material.dart';

/// True for something an `<img>` can load.
bool isImageUrl(String? url) => url != null && url.trim().startsWith('http');

/// A remote image that degrades to an icon instead of throwing.
///
/// Bucket images are served from another origin; when that origin sends no
/// CORS headers the canvas renderer cannot read the pixels, so the image falls
/// back to a plain `<img>` element rather than failing.
class AdminNetworkImage extends StatelessWidget {
  const AdminNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_not_supported_outlined,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: scheme.outline),
    );
    if (!isImageUrl(url)) return placeholder;
    return Image.network(
      url!.trim(),
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              width: width,
              height: height,
              color: scheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );
  }
}

/// A user's profile photo, or their initial when there is none.
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.url,
    required this.name,
    this.radius = 20,
  });

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = Text(
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.8,
        color: scheme.onPrimaryContainer,
      ),
    );
    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: ColoredBox(
          color: scheme.primaryContainer,
          child: isImageUrl(url)
              ? Image.network(
                  url!.trim(),
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                  errorBuilder: (_, _, _) => Center(child: initial),
                )
              : Center(child: initial),
        ),
      ),
    );
  }
}

/// Full-size viewer for one or more images, with previous / next.
Future<void> showImageViewer(
  BuildContext context,
  List<String> urls, {
  int initialIndex = 0,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ImageViewerDialog(urls: urls, initialIndex: initialIndex),
  );
}

class _ImageViewerDialog extends StatefulWidget {
  const _ImageViewerDialog({required this.urls, required this.initialIndex});

  final List<String> urls;
  final int initialIndex;

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late int _index = widget.initialIndex.clamp(0, widget.urls.length - 1);

  void _step(int delta) =>
      setState(() => _index = (_index + delta) % widget.urls.length);

  @override
  Widget build(BuildContext context) {
    final many = widget.urls.length > 1;
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(32),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: AdminNetworkImage(
              url: widget.urls[_index],
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          if (many) ...[
            Positioned(
              left: 8,
              child: IconButton.filledTonal(
                tooltip: 'Previous',
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _step(-1),
              ),
            ),
            Positioned(
              right: 8,
              child: IconButton.filledTonal(
                tooltip: 'Next',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _step(1),
              ),
            ),
            Positioned(
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "2026-11-06 14:05" in the admin's local time.
String formatAdminDate(DateTime? dt) {
  if (dt == null) return '—';
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// `FULLY_FURNISHED` → "Fully furnished".
String humanizeEnum(String? value, {String fallback = '—'}) {
  if (value == null || value.isEmpty) return fallback;
  final words = value.toLowerCase().split('_').join(' ');
  return words[0].toUpperCase() + words.substring(1);
}
