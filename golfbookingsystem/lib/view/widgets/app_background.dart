import 'package:flutter/material.dart';

enum AppBackgroundPreset { login, app }

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.imageUrl,
    required this.child,
    this.fallbackAsset,
    this.preset = AppBackgroundPreset.app,
    this.forceDarkOverlay = false,
  });

  static const defaultLoginAsset = 'assets/images/background-login-default.png';
  static const defaultAppAsset = 'assets/images/background-app-default.png';

  final String? imageUrl;
  final Widget child;
  final String? fallbackAsset;
  final AppBackgroundPreset preset;
  final bool forceDarkOverlay;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final useDarkOverlay =
        forceDarkOverlay || Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        _BackgroundImage(url: url, fallbackAsset: fallbackAsset),
        if (useDarkOverlay)
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xA6000000)),
          )
        else
          DecoratedBox(decoration: BoxDecoration(gradient: _lightGradient)),
        if (!useDarkOverlay && preset == AppBackgroundPreset.login)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.15,
                colors: [Color(0x6BFFFFFF), Color(0x00FFFFFF)],
                stops: [0, 0.42],
              ),
            ),
          ),
        if (useDarkOverlay)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x14000000),
                  Color(0x00000000),
                  Color(0x29000000),
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

  LinearGradient get _lightGradient {
    switch (preset) {
      case AppBackgroundPreset.login:
        return const LinearGradient(
          colors: [Color(0x6BF4FBF5), Color(0xC2FFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case AppBackgroundPreset.app:
        return const LinearGradient(
          colors: [Color(0xC7F4FBF5), Color(0xD6FFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.url, required this.fallbackAsset});

  final String? url;
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    final asset = fallbackAsset;
    if (url == null || url!.isEmpty) {
      return asset == null ? const SizedBox.shrink() : _assetImage(asset);
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) =>
          asset == null ? const SizedBox.shrink() : _assetImage(asset),
    );
  }

  Widget _assetImage(String asset) {
    return Image.asset(asset, fit: BoxFit.cover, alignment: Alignment.center);
  }
}
