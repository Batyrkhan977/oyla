import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oyla/src/app.dart';
import 'package:oyla/src/models.dart';

void main() {
  test('reduced-motion setting disables framework animations', () {
    final result = accessibilityMediaQuery(
      const MediaQueryData(),
      const UserSettings(reducedMotion: true),
    );

    expect(result.disableAnimations, isTrue);
  });

  test('system reduced-motion preference is always preserved', () {
    final result = accessibilityMediaQuery(
      const MediaQueryData(disableAnimations: true),
      const UserSettings(reducedMotion: false),
    );

    expect(result.disableAnimations, isTrue);
  });
}
