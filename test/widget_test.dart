import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iptv_jotac/app.dart';

void main() {
  testWidgets('App renders the home shell without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IptvJotacApp()));
    await tester.pump();

    expect(find.text('IPTV Jotac'), findsOneWidget);
  });
}
