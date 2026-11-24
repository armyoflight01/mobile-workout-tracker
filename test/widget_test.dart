import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('Russell Mobile smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RussellMobileApp());
    expect(find.text('Russell Mobile'), findsWidgets);
  });
}
