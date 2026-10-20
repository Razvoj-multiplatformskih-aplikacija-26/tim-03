import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  setUpAll(initializeDomainTimeZones);

  testWidgets('starts on the owner\'s orders', (tester) async {
    await tester.pumpWidget(const SapaApp());
    await tester.pumpAndSettle();

    expect(find.text('Moji nalozi'), findsOneWidget);
    expect(find.text('Aktuelni'), findsOneWidget);
  });
}
