import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_jotac/widgets/remote_content_action.dart';

void main() {
  testWidgets('Short OK opens; held OK and Menu favorite without opening', (
    tester,
  ) async {
    var opens = 0;
    var favorites = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteContentAction(
            onTap: () => opens++,
            onToggleFavorite: () => favorites++,
            child: const SizedBox(
              width: 200,
              height: 100,
              child: Text('Canal'),
            ),
          ),
        ),
      ),
    );
    final ink = tester.widget<InkWell>(find.byType(InkWell));
    ink.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    expect(opens, 1);
    expect(favorites, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(favorites, 1);
    expect(opens, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    expect(favorites, 2);
    await tester.longPress(find.text('Canal'));
    expect(favorites, 3);
    expect(opens, 1);
  });

  testWidgets('Nested favorite button keeps OK and leaving cancels a hold', (
    tester,
  ) async {
    var opens = 0;
    var favorites = 0;
    final buttonFocus = FocusNode();
    addTearDown(buttonFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RemoteContentAction(
            onTap: () => opens++,
            onToggleFavorite: () => favorites++,
            child: IconButton(
              focusNode: buttonFocus,
              icon: const Icon(Icons.star),
              onPressed: () => favorites++,
            ),
          ),
        ),
      ),
    );
    buttonFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(favorites, 1);
    expect(opens, 0);
    final ink = tester.widgetList<InkWell>(find.byType(InkWell)).first;
    ink.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    buttonFocus.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(favorites, 1);
    expect(opens, 0);
  });
}
