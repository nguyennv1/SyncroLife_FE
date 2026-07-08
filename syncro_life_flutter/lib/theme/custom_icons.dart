import 'package:flutter/material.dart';
import 'colors.dart';

class LightningBoltIcon extends StatelessWidget {
  final double size;
  final Color tint;
  const LightningBoltIcon({super.key, this.size = 24.0, this.tint = AppColors.accentTeal});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LightningBoltPainter(tint),
    );
  }
}

class _LightningBoltPainter extends CustomPainter {
  final Color tint;
  _LightningBoltPainter(this.tint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w * 0.2, h * 0.55)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.45, h)
      ..lineTo(w * 0.8, h * 0.45)
      ..lineTo(w * 0.5, h * 0.45)
      ..close();
    canvas.drawPath(path, Paint()..color = tint..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartbeatIcon extends StatelessWidget {
  final double size;
  final Color tint;
  const HeartbeatIcon({super.key, this.size = 24.0, this.tint = AppColors.primaryBlue});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeartbeatPainter(tint),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final Color tint;
  _HeartbeatPainter(this.tint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.5)
      ..lineTo(w * 0.25, h * 0.5)
      ..lineTo(w * 0.35, h * 0.15)
      ..lineTo(w * 0.45, h * 0.85)
      ..lineTo(w * 0.55, h * 0.4)
      ..lineTo(w * 0.65, h * 0.6)
      ..lineTo(w * 0.75, h * 0.5)
      ..lineTo(w, h * 0.5);
    canvas.drawPath(path, Paint()..color = tint..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BullseyeIcon extends StatelessWidget {
  final double size;
  final Color tint;
  const BullseyeIcon({super.key, this.size = 24.0, this.tint = AppColors.primaryBlue});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BullseyePainter(tint),
    );
  }
}

class _BullseyePainter extends CustomPainter {
  final Color tint;
  _BullseyePainter(this.tint);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;
    final strokePaint = Paint()..color = tint..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final fillPaint = Paint()..color = tint..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, strokePaint);
    canvas.drawCircle(center, maxRadius * 0.6, strokePaint);
    canvas.drawCircle(center, maxRadius * 0.2, fillPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CoinDollarIcon extends StatelessWidget {
  final double size;
  final Color tint;
  const CoinDollarIcon({super.key, this.size = 24.0, this.tint = AppColors.primaryBlue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircleStrokePainter(tint),
          ),
          Text('\$', style: TextStyle(color: tint, fontSize: size * 0.6, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CircleStrokePainter extends CustomPainter {
  final Color tint;
  _CircleStrokePainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 2,
      Paint()..color = tint..style = PaintingStyle.stroke..strokeWidth = 2.0,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AvatarOutlineIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  final String? imageUrl;
  const AvatarOutlineIcon({super.key, this.size = 68.0, this.tint, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textMuted;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: activeTint.withOpacity(0.4), width: 1),
        borderRadius: BorderRadius.circular(16),
        image: hasImage
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      padding: hasImage ? EdgeInsets.zero : EdgeInsets.all(size * 0.15),
      child: hasImage ? null : Icon(Icons.person, color: activeTint, size: size * 0.7),
    );
  }
}

class FishIcon extends StatelessWidget {
  final double size;
  const FishIcon({super.key, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _FishPainter());
  }
}

class _FishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    
    final bodyPath = Path()
      ..moveTo(w * 0.1, h * 0.5)
      ..quadraticBezierTo(w * 0.4, h * 0.2, w * 0.75, h * 0.5)
      ..quadraticBezierTo(w * 0.4, h * 0.8, w * 0.1, h * 0.5)
      ..close();
      
    final tailPath = Path()
      ..moveTo(w * 0.75, h * 0.5)
      ..lineTo(w * 0.9, h * 0.3)
      ..lineTo(w * 0.9, h * 0.7)
      ..close();
      
    canvas.drawPath(bodyPath, Paint()..color = const Color(0xFF60A5FA)..style = PaintingStyle.fill);
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.3, h * 0.45), 2.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AvocadoIcon extends StatelessWidget {
  final double size;
  const AvocadoIcon({super.key, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _AvocadoPainter());
  }
}

class _AvocadoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF4ADE80));
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.25, Paint()..color = const Color(0xFFCA8A04));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SaladIcon extends StatelessWidget {
  final double size;
  const SaladIcon({super.key, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _SaladPainter());
  }
}

class _SaladPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bowlPath = Path()
      ..moveTo(w * 0.1, h * 0.4)
      ..lineTo(w * 0.9, h * 0.4)
      ..quadraticBezierTo(w * 0.8, h * 0.9, w * 0.5, h * 0.9)
      ..quadraticBezierTo(w * 0.2, h * 0.9, w * 0.1, h * 0.4)
      ..close();
      
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.05, w * 0.8, h * 0.3), Paint()..color = const Color(0xFF22C55E).withOpacity(0.9));
    canvas.drawPath(bowlPath, Paint()..color = const Color(0xFF94A3B8));
    canvas.drawCircle(Offset(w * 0.4, h * 0.25), 2.0, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(w * 0.6, h * 0.3), 2.0, Paint()..color = const Color(0xFFEF4444));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StrawberryIcon extends StatelessWidget {
  final double size;
  const StrawberryIcon({super.key, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _StrawberryPainter());
  }
}

class _StrawberryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final berryPath = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..quadraticBezierTo(w * 0.9, h * 0.3, w * 0.8, h * 0.7)
      ..quadraticBezierTo(w * 0.5, h * 0.95, w * 0.2, h * 0.7)
      ..quadraticBezierTo(w * 0.1, h * 0.3, w * 0.5, h * 0.1)
      ..close();
      
    canvas.drawPath(berryPath, Paint()..color = const Color(0xFFEF4444));
    final seedPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.4, h * 0.4), 1.0, seedPaint);
    canvas.drawCircle(Offset(w * 0.6, h * 0.5), 1.0, seedPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.65), 1.0, seedPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CoffeeIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  const CoffeeIcon({super.key, this.size = 24.0, this.tint});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textLight;
    return CustomPaint(size: Size(size, size), painter: _CoffeePainter(activeTint));
  }
}

class _CoffeePainter extends CustomPainter {
  final Color tint;
  _CoffeePainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.3, w * 0.5, h * 0.5), Radius.circular(w * 0.05)),
      Paint()..color = tint,
    );
    canvas.drawArc(
      Rect.fromLTWH(w * 0.55, h * 0.4, w * 0.25, h * 0.3),
      -1.5708, // -90 degrees in radians
      3.14159, // 180 degrees in radians
      false,
      Paint()..color = tint..style = PaintingStyle.stroke..strokeWidth = 2.0,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LaptopIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  const LaptopIcon({super.key, this.size = 24.0, this.tint});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textLight;
    return CustomPaint(size: Size(size, size), painter: _LaptopPainter(activeTint));
  }
}

class _LaptopPainter extends CustomPainter {
  final Color tint;
  _LaptopPainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.45), const Radius.circular(2)),
      Paint()..color = tint..style = PaintingStyle.stroke..strokeWidth = 2.0,
    );
    canvas.drawLine(Offset(w * 0.05, h * 0.7), Offset(w * 0.95, h * 0.7), Paint()..color = tint..strokeWidth = 3.0);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DumbbellIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  const DumbbellIcon({super.key, this.size = 24.0, this.tint});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textLight;
    return CustomPaint(size: Size(size, size), painter: _DumbbellPainter(activeTint));
  }
}

class _DumbbellPainter extends CustomPainter {
  final Color tint;
  _DumbbellPainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()..color = tint;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.15, h * 0.6), const Radius.circular(2)), p);
    canvas.drawLine(Offset(w * 0.25, h * 0.5), Offset(w * 0.75, h * 0.5), p..strokeWidth = 4.0);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.75, h * 0.2, w * 0.15, h * 0.6), const Radius.circular(2)), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SoupIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  const SoupIcon({super.key, this.size = 24.0, this.tint});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textLight;
    return CustomPaint(size: Size(size, size), painter: _SoupPainter(activeTint));
  }
}

class _SoupPainter extends CustomPainter {
  final Color tint;
  _SoupPainter(this.tint);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.4)
      ..lineTo(w * 0.85, h * 0.4)
      ..quadraticBezierTo(w * 0.75, h * 0.85, w * 0.5, h * 0.85)
      ..quadraticBezierTo(w * 0.25, h * 0.85, w * 0.15, h * 0.4)
      ..close();
    canvas.drawPath(path, Paint()..color = tint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BedtimeIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  const BedtimeIcon({super.key, this.size = 24.0, this.tint});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textLight;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text('Zzz', style: TextStyle(color: activeTint, fontSize: size * 0.5, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class TaskIcon extends StatelessWidget {
  final double size;
  final Color? tint;
  const TaskIcon({super.key, this.size = 24.0, this.tint});

  @override
  Widget build(BuildContext context) {
    final activeTint = tint ?? AppColors.textLight;
    return Icon(
      Icons.task_alt,
      size: size,
      color: activeTint,
    );
  }
}

