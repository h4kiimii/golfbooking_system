import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.imageUrl,
    required this.child,
    this.forceDarkOverlay = false,
  });

  final String? imageUrl;
  final Widget child;
  final bool forceDarkOverlay;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return child;
    final useDarkOverlay =
        forceDarkOverlay || Theme.of(context).brightness == Brightness.dark;
    final veilColor = useDarkOverlay ? Colors.black : Colors.white;
    final veilOpacity = useDarkOverlay ? 0.54 : 0.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: veilColor.withValues(alpha: veilOpacity),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                veilColor.withValues(alpha: useDarkOverlay ? 0.08 : 0.12),
                Colors.transparent,
                veilColor.withValues(alpha: useDarkOverlay ? 0.16 : 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
