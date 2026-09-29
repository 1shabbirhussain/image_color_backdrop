import 'package:flutter_test/flutter_test.dart';
import 'package:image_color_backdrop_example/main.dart';

void main() {
  testWidgets('example app shows its three tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Gallery'), findsWidgets);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Use the color'), findsOneWidget);

    await tester.tap(find.text('Playground'));
    await tester.pump();

    expect(find.text('Strategy'), findsOneWidget);
  });
}
