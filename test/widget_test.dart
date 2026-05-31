import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:upgrade_flutter_starter_kit/main.dart';
import 'package:upgrade_flutter_starter_kit/services/block_service.dart';

void main() {
  testWidgets('Screen Guard NoScrollApp build test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => BlockService(),
        child: const NoScrollApp(),
      ),
    );

    // Verify NoScroll title is present
    expect(find.text('NoScroll'), findsOneWidget);
  });
}
