import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Layout sizes shared by the shell and the pages.
abstract final class AdminBreakpoints {
  /// Below this the shell shows a top bar + drawer instead of a sidebar.
  static const phone = 720.0;

  /// Below this the sidebar collapses to icons.
  static const wide = 1180.0;

  /// Content never gets wider than this, so lines stay readable.
  static const maxContent = 1280.0;
}

extension AdminLayoutContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isPhone => screenWidth < AdminBreakpoints.phone;

  /// Outer padding of a page.
  double get pagePadding => isPhone ? 14 : 28;
}

/// Standard page: title row (with actions that wrap under the title on a
/// phone), then [child]. When [scrollable] is false, [child] gets the rest
/// of the height (for pages that hold their own list).
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.breadcrumb,
    this.onBack,
    this.scrollable = true,
    this.onRefresh,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Small line above the title ("Community · Posts").
  final String? breadcrumb;

  /// Shows a back arrow before the breadcrumb/title.
  final VoidCallback? onBack;
  final bool scrollable;
  final Future<void> Function()? onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    final header = AdminPageHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      breadcrumb: breadcrumb,
      onBack: onBack,
    );

    Widget body;
    if (scrollable) {
      body = ListView(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + 24),
        children: [
          _Constrained(child: header),
          SizedBox(height: context.isPhone ? 16 : 22),
          _Constrained(child: child),
        ],
      );
      if (onRefresh != null) {
        body = RefreshIndicator(onRefresh: onRefresh!, child: body);
      }
    } else {
      body = Padding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
        child: _Constrained(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              SizedBox(height: context.isPhone ? 14 : 20),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }
    return Scaffold(body: SafeArea(top: false, child: body));
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AdminBreakpoints.maxContent),
      child: child,
    ),
  );
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.breadcrumb,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String? breadcrumb;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = context.isPhone;
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumb != null || onBack != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBack != null)
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  if (onBack != null && breadcrumb != null)
                    const SizedBox(width: 6),
                  if (breadcrumb != null)
                    Flexible(
                      child: Text(
                        breadcrumb!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        Text(
          title,
          style: (phone
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.headlineMedium)
              ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    if (actions.isEmpty) return titleBlock;
    final actionWrap = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
    if (phone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titleBlock, const SizedBox(height: 12), actionWrap],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        actionWrap,
      ],
    );
  }
}

/// White rounded card with the brand border; optional title row.
class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.borderColor,
    this.onTap,
    required this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = padding ?? EdgeInsets.all(context.isPhone ? 14 : 18);
    Widget content = child;
    if (title != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      );
    }
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: borderColor ?? theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: pad, child: content),
      ),
    );
  }
}

enum ChipTone { neutral, ok, warn, danger, info, coral }

/// Rounded status pill ("Live", "Flagged · 2", "Archived", …).
class AdminChip extends StatelessWidget {
  const AdminChip(this.label, {super.key, this.tone = ChipTone.neutral, this.icon});

  final String label;
  final ChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = switch (tone) {
      ChipTone.neutral => dark
          ? (BrandColors.plumRaised, BrandColors.creamText)
          : (BrandColors.creamDeep, BrandColors.plum),
      ChipTone.ok => (BrandColors.okBg, BrandColors.okInk),
      ChipTone.warn => (BrandColors.warnBg, BrandColors.warnInk),
      ChipTone.danger => (BrandColors.dangerBg, BrandColors.dangerInk),
      ChipTone.info => (BrandColors.infoBg, BrandColors.infoInk),
      ChipTone.coral => (BrandColors.coral, BrandColors.plum),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// One option of an [AdminFilterBar].
class AdminFilter<T> {
  const AdminFilter(this.value, this.label, {this.count});

  final T value;
  final String label;
  final int? count;
}

/// Row of pill filters that scrolls sideways on a phone.
class AdminFilterBar<T> extends StatelessWidget {
  const AdminFilterBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<AdminFilter<T>> filters;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterPill(
                label: f.count == null ? f.label : '${f.label} · ${f.count}',
                selected: f.value == selected,
                onTap: () => onSelected(f.value),
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final dark = theme.brightness == Brightness.dark;
    final bg = selected
        ? (dark ? BrandColors.coral : BrandColors.plum)
        : theme.colorScheme.surface;
    final fg = selected
        ? (dark ? BrandColors.plum : BrandColors.creamText)
        : theme.colorScheme.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? bg : theme.colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Search box used at the top of list pages.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onSubmitted,
    this.initialValue = '',
  });

  final String hint;
  final ValueChanged<String> onSubmitted;
  final String initialValue;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (v) => widget.onSubmitted(v.trim()),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onSubmitted('');
                },
              ),
      ),
    );
  }
}

/// Centered message for an empty list.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: BrandColors.coralInk),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered error with a retry button.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 10),
            Text(
              'Couldn’t load this',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Page 2 of 7" with previous / next.
class AdminPager extends StatelessWidget {
  const AdminPager({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPage,
    this.totalElements,
  });

  /// Zero-based.
  final int page;
  final int totalPages;
  final int? totalElements;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 0 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            'Page ${page + 1} of $totalPages'
            '${totalElements == null ? '' : ' · $totalElements total'}',
            style: theme.textTheme.bodyMedium,
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: page < totalPages - 1 ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Small number tile used on the Overview page.
class AdminStatTile extends StatelessWidget {
  const AdminStatTile({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.noteColor,
    this.highlight = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String? note;
  final Color? noteColor;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AdminCard(
      onTap: onTap,
      borderColor: highlight ? BrandColors.coral : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: noteColor ?? theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Just now", "5m ago", "3h ago", "2d ago", then the date.
String timeAgo(DateTime? dt, {DateTime? now}) {
  if (dt == null) return '—';
  final diff = (now ?? DateTime.now()).difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final l = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${l.day} ${months[l.month - 1]} ${l.year}';
}

/// "in 9h", "in 40m" for something that ends in the future; "ended" otherwise.
String timeLeft(DateTime end, {DateTime? now}) {
  final diff = end.difference(now ?? DateTime.now());
  if (diff.isNegative) return 'ended';
  if (diff.inMinutes < 60) return 'in ${diff.inMinutes.clamp(1, 59)}m';
  return 'in ${diff.inHours}h';
}

/// Shows a short message at the bottom of the screen.
void showAdminSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
}
