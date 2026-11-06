import 'package:flutter/material.dart';
import 'localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class HandwritingRecognizer {
  static const _channel = MethodChannel('oyla/handwriting');

  Future<String?> recognize(List<List<Offset>> strokes, Size size) async {
    if (strokes.isEmpty || size.isEmpty) return null;
    try {
      final value = await _channel.invokeMethod<String>('recognize', {
        'strokes': strokes
            .map(
              (stroke) => stroke
                  .map(
                    (point) => {
                      'x': (point.dx / size.width).clamp(0.0, 1.0),
                      'y': (point.dy / size.height).clamp(0.0, 1.0),
                    },
                  )
                  .toList(),
            )
            .toList(),
      });
      final digits = value?.replaceAll(RegExp(r'[^0-9]'), '');
      return digits == null || digits.isEmpty ? null : digits;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}

class HandwritingController extends ChangeNotifier {
  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  List<List<Offset>> get strokes => _strokes
      .map((stroke) => List<Offset>.unmodifiable(stroke))
      .toList(growable: false);
  Size get size => _size;
  bool get hasInk => _strokes.any((stroke) => stroke.isNotEmpty);

  void startStroke(Offset point, Size size) {
    _size = size;
    _strokes.add([point]);
    notifyListeners();
  }

  void extendStroke(Offset point, Size size) {
    if (_strokes.isEmpty) return;
    _size = size;
    _strokes.last.add(point);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }
}

class HandwritingPad extends StatelessWidget {
  const HandwritingPad({super.key, required this.controller});

  final HandwritingController controller;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.strings.text('handwritingArea'),
    child: ExcludeSemantics(
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) => RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(EagerGestureRecognizer.new, (_) {}),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => controller.startStroke(
                  event.localPosition,
                  constraints.biggest,
                ),
                onPointerMove: (event) => controller.extendStroke(
                  event.localPosition,
                  constraints.biggest,
                ),
                child: CustomPaint(
                  painter: _HandwritingPainter(
                    strokes: controller.strokes,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  child: controller.hasInk
                      ? null
                      : Center(
                          child: Text(
                            context.strings.text('writeAnswerHere'),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HandwritingPainter extends CustomPainter {
  const _HandwritingPainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, paint.strokeWidth / 2, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_HandwritingPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.color != color;
}
