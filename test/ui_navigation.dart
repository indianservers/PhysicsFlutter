import 'package:flutter_test/flutter_test.dart';

Future<void> chooseSection(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Lab options').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> openControls(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Lab options').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Controls & investigation'));
  await tester.pumpAndSettle();
}
