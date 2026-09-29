import 'package:flutter_test/flutter_test.dart';

import 'package:country_trivia/main.dart';

void main() {
  testWidgets('Country Trivia app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryTriviaApp());

    expect(find.text('Country Trivia'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
