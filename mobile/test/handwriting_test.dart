import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/handwriting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('oyla/handwriting');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('normalizes strokes and keeps only recognized digits', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return 'Answer: 42';
    });

    final answer = await HandwritingRecognizer().recognize([
      [const Offset(20, 10), const Offset(100, 50)],
    ], const Size(200, 100));

    expect(answer, '42');
    expect(received?.method, 'recognize');
    final arguments = received?.arguments as Map<Object?, Object?>;
    final strokes = arguments['strokes'] as List<Object?>;
    final points = strokes.single as List<Object?>;
    expect(points.first, {'x': 0.1, 'y': 0.1});
    expect(points.last, {'x': 0.5, 'y': 0.5});
  });

  test('returns null when native recognition is unavailable', () async {
    final answer = await HandwritingRecognizer().recognize([
      [const Offset(1, 1), const Offset(2, 2)],
    ], const Size(10, 10));

    expect(answer, isNull);
  });

  testWidgets('drawing vertically does not scroll the surrounding page', (
    tester,
  ) async {
    final handwriting = HandwritingController();
    final scrolling = ScrollController();
    addTearDown(handwriting.dispose);
    addTearDown(scrolling.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: scrolling,
            children: [
              const SizedBox(height: 200),
              HandwritingPad(controller: handwriting),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byType(HandwritingPad),
      100,
      scrollable: find.byType(Scrollable),
    );
    final initialOffset = scrolling.offset;

    await tester.drag(find.byType(HandwritingPad), const Offset(0, -140));
    await tester.pump();

    expect(handwriting.hasInk, isTrue);
    expect(scrolling.offset, initialOffset);
  });
}
