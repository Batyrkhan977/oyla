import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:drift/native.dart';
import 'package:oyla/src/api.dart';
import 'package:oyla/src/app_state.dart';
import 'package:oyla/src/screens.dart';
import 'package:oyla/src/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi extends OylaApi {
  int requestCount = 0;
  String? requestedEmail;

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<String?> requestCode(String email) async {
    requestCount++;
    requestedEmail = email;
    return '123456';
  }
}

void main() {
  testWidgets('email registration validates and requests a code', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const reminderChannel = MethodChannel('oyla/reminders');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(reminderChannel, (_) async => null);
    addTearDown(
      () => messenger.setMockMethodCallHandler(reminderChannel, null),
    );
    final database = OylaDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);
    await container.read(appStateProvider.future);
    final api = _FakeApi();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: AccountScreen(api: api)),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(api.requestCount, 0);

    await tester.enterText(find.byType(TextField), ' person@example.com ');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pump();

    expect(api.requestCount, 1);
    expect(api.requestedEmail, 'person@example.com');
    expect(find.text('Development code: 123456'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Send a new code'), findsOneWidget);
    expect(find.text('Use a different email address'), findsOneWidget);
  });
}
