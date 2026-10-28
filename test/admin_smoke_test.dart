import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchmate_admin/app/app.dart';

void main() {
  testWidgets('Admin app widget smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MatchMateAdminApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MatchMateAdminApp), findsOneWidget);
  });
}
