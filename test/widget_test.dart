import 'package:flutter_test/flutter_test.dart';
import 'package:rail_alert/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RailAlertApp());
    await tester.pump();

    // Verify splash/loading screen appears
    expect(find.text('Loading Rail Alert...'), findsOneWidget);
  });
}
