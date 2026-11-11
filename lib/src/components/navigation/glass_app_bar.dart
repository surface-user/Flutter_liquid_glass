import 'package:flutter/material.dart';
import '../../core/style.dart';
import '../../theme/theme.dart';
import '../surfaces/glass_surface.dart';

/// Use Scaffold.extendBodyBehindAppBar to provide content behind the blur.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.style,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.automaticallyImplyLeading = true,
  });
  final Widget? title, leading;
  final List<Widget>? actions;
  final GlassStyle? style;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final bool automaticallyImplyLeading;
  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
  @override
  Widget build(BuildContext context) {
    final theme = LiquidGlassTheme.of(context);
    final material = Theme.of(context);
    final appBarTheme = AppBarTheme.of(context);
    final inheritedTitle = theme.textTheme.titleLarge != null
        ? material.textTheme.titleLarge
        : appBarTheme.titleTextStyle ??
              material.textTheme.titleLarge?.copyWith(
                color: appBarTheme.foregroundColor,
              );
    final titleStyle = glassTextStyle(
      context,
      theme.textTheme.titleLarge,
      inheritedStyle: inheritedTitle,
    );
    final highContrast =
        theme.accessibility.highContrast ||
        MediaQuery.maybeOf(context)?.highContrast == true;
    final overrideTitle =
        theme.textTheme.titleLarge != null ||
        (highContrast &&
            (titleStyle.color != null || titleStyle.foreground != null));
    return GlassSurface(
      style: style ?? theme.appBarStyle,
      child: AppBar(
        title: title,
        leading: leading,
        actions: actions,
        bottom: bottom,
        automaticallyImplyLeading: automaticallyImplyLeading,
        toolbarHeight: toolbarHeight,
        foregroundColor: highContrast
            ? titleStyle.foreground?.color ?? titleStyle.color
            : titleStyle.color,
        titleTextStyle: overrideTitle
            ? inheritedTitle?.merge(titleStyle)
            : null,
        titleSpacing: theme.layout.appBarTitleSpacing,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
