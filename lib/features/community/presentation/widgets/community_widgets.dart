import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/admin_image.dart';
import '../../../../core/widgets/admin_ui.dart';
import '../../domain/admin_community_models.dart';

/// Square photo of a post, or a tinted tile when it has none.
class PostThumb extends StatelessWidget {
  const PostThumb({super.key, required this.post, this.size = 56});

  final AdminCommunityPost post;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = post.imageUrls.isNotEmpty ? post.imageUrls.first : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox.square(
        dimension: size,
        child: isImageUrl(url)
            ? AdminNetworkImage(url: url, fit: BoxFit.cover)
            : ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.article_outlined,
                  size: size * 0.45,
                  color: BrandColors.coralInk,
                ),
              ),
      ),
    );
  }
}

/// Chips describing a post's state: pinned, flagged, hidden.
List<Widget> postStateChips(AdminCommunityPost p) => [
  if (p.isPinned)
    const AdminChip('Pinned', tone: ChipTone.info, icon: Icons.push_pin_rounded),
  if (p.isFlagged)
    AdminChip(
      p.pendingReports == 1 ? 'Flagged · 1 report' : 'Flagged · ${p.pendingReports} reports',
      tone: ChipTone.warn,
      icon: Icons.flag_rounded,
    ),
  if (!p.isActive)
    const AdminChip('Hidden', tone: ChipTone.neutral, icon: Icons.visibility_off_rounded),
];

/// Parses "#RRGGBB" (or "RRGGBB"); null when it is not a colour.
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  final h = hex.replaceFirst('#', '').trim();
  if (h.length != 6 && h.length != 8) return null;
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? null : Color(v);
}

/// What a status looks like in the app: its photo, or its caption on its
/// background colour.
class StatusArtwork extends StatelessWidget {
  const StatusArtwork({
    super.key,
    this.mediaUrl,
    this.caption,
    this.backgroundColor,
    this.captionSize = 15,
  });

  final String? mediaUrl;
  final String? caption;
  final String? backgroundColor;
  final double captionSize;

  @override
  Widget build(BuildContext context) {
    if (isImageUrl(mediaUrl)) {
      return AdminNetworkImage(url: mediaUrl, fit: BoxFit.cover);
    }
    final bg = parseHexColor(backgroundColor) ?? BrandColors.plumSoft;
    final light = bg.computeLuminance() > 0.5;
    return ColoredBox(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            (caption ?? '').trim().isEmpty ? 'Text status' : caption!.trim(),
            textAlign: TextAlign.center,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: light ? BrandColors.plum : Colors.white,
              fontSize: captionSize,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

/// One status in the grid: artwork, author, live/expired and report count.
class StatusTile extends StatelessWidget {
  const StatusTile({super.key, required this.status, required this.onTap});

  final AdminUserStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = status;
    return Semantics(
      button: true,
      label: 'Status by ${s.authorName}',
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: s.pendingReports > 0
                ? BrandColors.coral
                : Theme.of(context).colorScheme.outlineVariant,
            width: s.pendingReports > 0 ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              StatusArtwork(
                mediaUrl: s.mediaUrl,
                caption: s.caption,
                backgroundColor: s.backgroundColor,
                captionSize: 13,
              ),
              // Readable footer over any photo.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC1A1026)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    s.isLive
                        ? AdminChip('Live · ends ${timeLeft(s.expiresAt)}', tone: ChipTone.ok)
                        : const AdminChip('Expired'),
                    if (s.pendingReports > 0)
                      AdminChip(
                        '${s.pendingReports} report${s.pendingReports == 1 ? '' : 's'}',
                        tone: ChipTone.danger,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    AdminAvatar(url: s.authorAvatarUrl, name: s.authorName, radius: 13),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${timeAgo(s.createdAt)} · ${s.viewsCount} views',
                            maxLines: 1,
                            style: const TextStyle(
                              color: Color(0xFFE9DDF0),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
