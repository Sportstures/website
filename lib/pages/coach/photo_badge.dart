import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A team logo or person's photo, or their initials when there is no image yet.
class PhotoBadge extends StatelessWidget {
  const PhotoBadge({super.key, this.url, required this.fallback, this.size = 64, this.square = false});

  final String? url;

  /// The team or person's name; its first letters show when there is no image.
  final String fallback;
  final double size;

  /// Logos are square with rounded corners; people are round.
  final bool square;

  String get _initials {
    final words = fallback.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(square ? size * 0.18 : size);
    final initials = Center(
      child: Text(_initials, style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w900, color: AppColors.green)),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.white, borderRadius: radius, border: Border.all(color: AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? initials
          : Image.network(
              url!,
              fit: square ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (_, _, _) => initials,
              loadingBuilder: (context, child, progress) => progress == null ? child : initials,
            ),
    );
  }
}
