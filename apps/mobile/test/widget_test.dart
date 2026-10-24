import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/dependencies.dart';
import 'package:mobile/widgets/order_card.dart';

void main() {
  setUpAll(initializeDomainTimeZones);

  Widget app() => SapaApp(dependencies: AppDependencies.fake(latency: Duration.zero));

  testWidgets('starts on the owner\'s orders', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Moji nalozi'), findsOneWidget);
    expect(find.text('Aktuelni'), findsOneWidget);
    expect(find.text('Prethodni'), findsOneWidget);
    expect(find.text('U toku'), findsWidgets);
  });

  testWidgets('shows finished orders on the second tab', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prethodni'));
    await tester.pumpAndSettle();

    expect(find.text('Završeni'), findsOneWidget);
  });

  testWidgets('shows only the chosen pet\'s orders', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Mica'));
    await tester.pumpAndSettle();

    Finder onCards(String text) => find.descendant(of: find.byType(OrderCard), matching: find.text(text));
    expect(onCards('Mica'), findsWidgets);
    expect(onCards('Reks'), findsNothing);
    expect(onCards('Bobi'), findsNothing);
  });
}
