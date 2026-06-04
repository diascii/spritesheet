import 'package:flutter_test/flutter_test.dart';

import 'package:spritesheet/main.dart';

void main() {
  testWidgets('App loads with import prompt', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('SpriteSheet Packer'), findsWidgets);
    expect(find.text('Create, animate, and pack sprite sheets with ease.'), findsOneWidget);
  });
}
