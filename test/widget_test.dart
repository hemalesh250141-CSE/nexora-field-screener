import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('app boots with Nexora material app', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoraApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byType(NexoraApp), findsOneWidget);
    expect(find.textContaining('NEXORA'), findsWidgets);
  });
}
