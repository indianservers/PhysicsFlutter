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

Future<void> tapViewportTool(WidgetTester tester, String tooltip) async {
  if (find.byTooltip(tooltip).hitTestable().evaluate().isEmpty) {
    await tester.tap(find.byTooltip('Lab options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera tools').last);
    await tester.pumpAndSettle();
  }
  final target = find.byTooltip(tooltip).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  final close = find.byTooltip('Close camera tools').hitTestable();
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.last);
    await tester.pumpAndSettle();
  }
}
