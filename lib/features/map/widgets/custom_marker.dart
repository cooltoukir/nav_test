import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserLocationMarker extends StatefulWidget {
  const UserLocationMarker({super.key});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 40 * _pulseAnimation.value,
              height: 40 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withAlpha(
                  (255 * (1.0 - _pulseAnimation.value)).round(),
                ),
              ),
            );
          },
        ),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

class DestinationMarker extends StatelessWidget {
  const DestinationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withAlpha(40),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
            ],
          ),
        ).animate().scaleX(
          begin: 0.1,
          end: 1.0,
          duration: 400.ms,
          curve: Curves.easeOut,
        ),

        Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  CustomPaint(
                    size: const Size(10, 6),
                    painter: _TrianglePainter(color: Colors.redAccent),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 200.ms)
            .slideY(
              begin: -0.6,
              end: 0,
              duration: 450.ms,
              curve: Curves.bounceOut,
            ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NavigationMarker extends StatefulWidget {
  final double bearing;
  final double size;
  final Color color;
  final Duration duration;
  final bool isMoving;

  const NavigationMarker({
    super.key,
    this.bearing = 0,
    this.size = 48,
    this.color = const Color(0xFF00BCD4),
    this.duration = const Duration(milliseconds: 350),
    this.isMoving = true,
  });

  @override
  State<NavigationMarker> createState() => _NavigationMarkerState();
}

class _NavigationMarkerState extends State<NavigationMarker> {
  late double _angle;

  @override
  void initState() {
    super.initState();
    _angle = widget.bearing;
  }

  @override
  void didUpdateWidget(covariant NavigationMarker old) {
    super.didUpdateWidget(old);
    final delta = ((widget.bearing - _angle) % 360 + 540) % 360 - 180;
    _angle += delta;
  }

  @override
  Widget build(BuildContext context) {
    final car =
        TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _angle),
              duration: widget.duration,
              curve: Curves.easeOut,
              builder: (context, a, child) =>
                  Transform.rotate(angle: a * pi / 180, child: child),
              child: CustomPaint(
                size: Size(widget.size * 0.5, widget.size),
                painter: _CarPainter(widget.color),
              ),
            )
            .animate()
            .fadeIn(duration: 250.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            );

    return SizedBox(
      width: widget.size * 1.8,
      height: widget.size * 1.8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isMoving)
            Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withAlpha(70),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.7, 1.7),
                  duration: 1600.ms,
                  curve: Curves.easeOut,
                )
                .fadeOut(duration: 1600.ms),
          car,
        ],
      ),
    );
  }
}

class _CarPainter extends CustomPainter {
  final Color color;

  _CarPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * 0.1, h * 0.04, w * 1.2, h * 0.96),
        Radius.circular(w * 0.5),
      ),
      Paint()
        ..color = color.withAlpha(90)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final wheel = Paint()..color = const Color(0xFF212121);
    for (final y in [h * 0.18, h * 0.66]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.06, y, w * 0.14, h * 0.16),
          const Radius.circular(2),
        ),
        wheel,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.92, y, w * 0.14, h * 0.16),
          const Radius.circular(2),
        ),
        wheel,
      );
    }

    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, w, h),
      topLeft: Radius.circular(w * 0.55),
      topRight: Radius.circular(w * 0.55),
      bottomLeft: Radius.circular(w * 0.35),
      bottomRight: Radius.circular(w * 0.35),
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );

    final glass = Paint()..color = const Color(0xFF263238);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.22, w * 0.7, h * 0.16),
        Radius.circular(w * 0.15),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.68, w * 0.64, h * 0.1),
        Radius.circular(w * 0.1),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.17, h * 0.4, w * 0.66, h * 0.26),
        Radius.circular(w * 0.15),
      ),
      Paint()..color = Colors.white.withAlpha(70),
    );

    final light = Paint()..color = const Color(0xFFFFF59D);
    canvas.drawCircle(Offset(w * 0.22, h * 0.08), w * 0.07, light);
    canvas.drawCircle(Offset(w * 0.78, h * 0.08), w * 0.07, light);

    final tail = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(Offset(w * 0.22, h * 0.94), w * 0.06, tail);
    canvas.drawCircle(Offset(w * 0.78, h * 0.94), w * 0.06, tail);
  }

  @override
  bool shouldRepaint(covariant _CarPainter old) => old.color != color;
}

double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  final p1 = lat1 * pi / 180, p2 = lat2 * pi / 180;
  final dl = (lon2 - lon1) * pi / 180;
  final y = sin(dl) * cos(p2);
  final x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}
