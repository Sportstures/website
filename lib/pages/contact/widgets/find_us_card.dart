import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/site/photo_background.dart';
import '../../../widgets/site/site_routes.dart';
import '../../../widgets/site/ui_kit.dart';
import 'contact_card.dart';

class FindUsCard extends StatelessWidget {
  const FindUsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ContactCard(
      title: 'Find us',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const PhotoBackground(
              asset: SiteImages.contactMap,
              fallback: CustomPaint(painter: _StreetMapPainter()),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Icon(Icons.location_on, size: 40, color: Color(0xFFDC2626)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sportstures Head Office',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          // TODO: confirm the office address before launch
          const SelectableText(
            'The Campus, 57 Sloane Street\nBryanston, Johannesburg, 2191\nGauteng, South Africa',
            style: TextStyle(fontSize: 12, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 14),
          SiteButton(
            label: 'GET DIRECTIONS',
            trailingIcon: Icons.arrow_forward,
            variant: SiteButtonVariant.outlineOrange,
            small: true,
            // TODO: open Google Maps (needs the url_launcher package)
            onPressed: () => openSiteRoute(context, null),
          ),
        ],
      ),
    );
  }
}

/// Stylised street map drawn until a real map image is exported.
class _StreetMapPainter extends CustomPainter {
  const _StreetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEFF2E8));

    final park = Paint()..color = const Color(0xFFCFE3C0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.55, size.width * 0.22, size.height * 0.3),
        const Radius.circular(6),
      ),
      park,
    );

    final river = Paint()
      ..color = const Color(0xFFB9D7EA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.6, 0)
        ..quadraticBezierTo(size.width * 0.75, size.height * 0.5, size.width, size.height * 0.7),
      river,
    );

    final majorRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 7;
    final minorRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas
      ..drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.3), majorRoad)
      ..drawLine(Offset(size.width * 0.42, 0), Offset(size.width * 0.5, size.height), majorRoad);
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6 - 10, size.height), minorRoad);
    }
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(Offset(0, size.height * i / 4 + 8), Offset(size.width, size.height * i / 4), minorRoad);
    }
  }

  @override
  bool shouldRepaint(_StreetMapPainter oldDelegate) => false;
}
