import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:upgrade_flutter_starter_kit/main.dart';
import 'package:upgrade_flutter_starter_kit/services/block_service.dart';

void main() {
  testWidgets('Screen Guard SnapApp build test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => BlockService(),
        child: const SnapApp(),
      ),
    );

    // Verify Screen Guard title is present
    expect(find.text('Screen Guard'), findsOneWidget);
  });
}
