import 'package:flutter/material.dart';

import '../../../data/sports_data.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/site/ui_kit.dart';

class BrowseByRegionCard extends StatelessWidget {
  const BrowseByRegionCard({super.key, required this.selectedRegion, required this.onSelect});

  final String? selectedRegion;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Browse by region',
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 170,
            child: CustomPaint(painter: _SouthAfricaPainter()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final region in SportsData.regions)
                _RegionChip(
                  label: region,
                  selected: region == selectedRegion,
                  onTap: () => onSelect(region == selectedRegion ? null : region),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: CardLink(label: 'View all regions', onTap: () => onSelect(null)),
          ),
        ],
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Simplified outline of South Africa (with Lesotho cut out), drawn from
/// approximate longitude/latitude points.
class _SouthAfricaPainter extends CustomPainter {
  const _SouthAfricaPainter();

  static const _outline = [
    (16.45, -28.63), (16.9, -29.5), (17.3, -30.5), (17.9, -31.5), (18.2, -32.4),
    (17.9, -32.8), (18.4, -33.3), (18.4, -33.9), (18.5, -34.35), (19.0, -34.4),
    (19.6, -34.6), (20.0, -34.83), (20.9, -34.4), (22.1, -34.2), (23.4, -34.1),
    (24.8, -34.2), (25.6, -34.0), (26.6, -33.7), (27.9, -33.0), (28.8, -32.2),
    (29.5, -31.6), (30.4, -30.8), (31.0, -29.9), (31.6, -29.0), (32.1, -28.8),
    (32.4, -28.0), (32.9, -26.85), (32.0, -25.9), (31.95, -24.5), (31.6, -23.5),
    (31.3, -22.4), (30.3, -22.3), (29.4, -22.2), (28.4, -22.6), (27.3, -23.4),
    (26.8, -24.2), (25.9, -24.7), (25.5, -25.5), (24.6, -25.8), (23.5, -25.3),
    (22.6, -26.0), (21.7, -26.8), (20.8, -26.8), (20.4, -25.5), (20.0, -24.75),
    (20.0, -28.4), (19.3, -28.9), (18.5, -28.9), (17.4, -28.7),
  ];

  static const _lesotho = [
    (27.0, -29.6), (27.6, -28.9), (28.3, -28.6), (29.0, -28.9), (29.45, -29.4),
    (29.2, -30.0), (28.6, -30.5), (28.0, -30.6), (27.4, -30.2),
  ];

  static const _west = 16.3, _east = 33.0, _north = -22.1, _south = -34.9;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = [
      size.width / (_east - _west),
      size.height / (_north - _south),
    ].reduce((a, b) => a < b ? a : b);
    final dx = (size.width - (_east - _west) * scale) / 2;
    final dy = (size.height - (_north - _south) * scale) / 2;

    Offset project((double, double) point) =>
        Offset(dx + (point.$1 - _west) * scale, dy + (_north - point.$2) * scale);

    Path polygon(List<(double, double)> points) =>
        Path()..addPolygon([for (final p in points) project(p)], true);

    final shape = polygon(_outline)
      ..addPath(polygon(_lesotho), Offset.zero)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(shape, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_SouthAfricaPainter oldDelegate) => false;
}
