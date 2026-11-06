import 'dart:math';
import 'package:flutter/material.dart';

enum OmirDirection { mind, read, move, music, sing, piano, togyz, connect }

class OmirMark extends StatelessWidget {
  const OmirMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'ÖmirAI',
    image: true,
    child: CustomPaint(size: Size.square(size), painter: _BrandPainter(null)),
  );
}

class OmirIcon extends StatelessWidget {
  const OmirIcon(this.direction, {super.key, this.size = 48});
  final OmirDirection direction;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _BrandPainter(direction),
    ),
  );
}

class OmirWordmark extends StatelessWidget {
  const OmirWordmark({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        const OmirMark(size: 40),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Ömir',
                style: TextStyle(
                  color: dark
                      ? const Color(0xff80D8CF)
                      : const Color(0xff0E7C7B),
                ),
              ),
              TextSpan(
                text: 'AI',
                style: TextStyle(
                  color: dark
                      ? const Color(0xffF4B24E)
                      : const Color(0xff95600B),
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _BrandPainter extends CustomPainter {
  _BrandPainter(this.direction);
  final OmirDirection? direction;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final p = Paint()
      ..color = direction == null
          ? const Color(0xff0E7C7B)
          : const Color(0xffD9EEEA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 48, 48),
        Radius.circular(direction == null ? 24 : 14),
      ),
      p,
    );
    p
      ..color = direction == null ? Colors.white : const Color(0xff0E7C7B)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    void line(double a, double b, double c, double d) =>
        canvas.drawLine(Offset(a, b), Offset(c, d), p);
    switch (direction) {
      case null:
        line(24, 36, 24, 22);
        p.style = PaintingStyle.fill;
        canvas.drawPath(
          Path()
            ..moveTo(24, 27)
            ..quadraticBezierTo(9, 28, 11, 16)
            ..quadraticBezierTo(24, 16, 24, 27),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(24, 25)
            ..quadraticBezierTo(24, 13, 37, 13)
            ..quadraticBezierTo(38, 25, 24, 25),
          p,
        );
        canvas.drawCircle(const Offset(20, 10), 2, p);
        canvas.drawCircle(const Offset(28, 7), 2, p);
      case OmirDirection.mind:
        canvas.drawPath(
          Path()
            ..moveTo(24, 8)
            ..lineTo(28, 19)
            ..lineTo(39, 24)
            ..lineTo(28, 28)
            ..lineTo(24, 40)
            ..lineTo(20, 28)
            ..lineTo(9, 24)
            ..lineTo(20, 19)
            ..close(),
          p,
        );
      case OmirDirection.read:
        canvas.drawPath(
          Path()
            ..moveTo(24, 36)
            ..lineTo(10, 32)
            ..lineTo(10, 12)
            ..lineTo(24, 16)
            ..lineTo(38, 12)
            ..lineTo(38, 32)
            ..close(),
          p,
        );
        line(24, 16, 24, 36);
      case OmirDirection.move:
        canvas.drawCircle(const Offset(27, 11), 3, p);
        line(25, 18, 20, 29);
        line(20, 29, 11, 38);
        line(20, 29, 32, 37);
        line(25, 18, 35, 23);
        line(25, 18, 14, 22);
      case OmirDirection.music:
        line(29, 10, 29, 28);
        line(29, 10, 36, 13);
        canvas.drawOval(const Rect.fromLTWH(18, 24, 11, 7), p);
        canvas.drawPath(
          Path()
            ..moveTo(9, 37)
            ..quadraticBezierTo(17, 30, 24, 37)
            ..quadraticBezierTo(32, 43, 39, 36),
          p,
        );
      case OmirDirection.sing:
        for (var i = 0; i < 7; i++) {
          final h = 6 + 12 * sin(i * pi / 6);
          line(9 + i * 5, 24 - h / 2, 9 + i * 5, 24 + h / 2);
        }
      case OmirDirection.piano:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(8, 12, 32, 26),
            const Radius.circular(3),
          ),
          p,
        );
        for (var i = 1; i < 4; i++) {
          line(8 + i * 8, 12, 8 + i * 8, 38);
        }
        p.style = PaintingStyle.fill;
        for (var i = 1; i < 4; i++) {
          canvas.drawRect(Rect.fromLTWH(5 + i * 8, 12, 6, 14), p);
        }
      case OmirDirection.togyz:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 12, 36, 25),
            const Radius.circular(7),
          ),
          p,
        );
        for (var r = 0; r < 2; r++) {
          for (var c = 0; c < 4; c++) {
            canvas.drawCircle(Offset(12 + c * 8, 19 + r * 11), 2, p);
          }
        }
      case OmirDirection.connect:
        canvas.drawPath(
          Path()
            ..moveTo(24, 26)
            ..cubicTo(4, 2, 3, 43, 24, 26)
            ..cubicTo(45, 3, 44, 44, 24, 26),
          p,
        );
        canvas.drawCircle(const Offset(15, 10), 2, p);
        canvas.drawCircle(const Offset(33, 10), 2, p);
    }
  }

  @override
  bool shouldRepaint(_BrandPainter old) => old.direction != direction;
}
