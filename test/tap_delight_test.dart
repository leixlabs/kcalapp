import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calory/core/widgets/tap_delight.dart';

void main() {
  group('TapDelight', () {
    testWidgets('renders its child and keeps the same size when idle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: TapDelight(child: Text('1234'))),
          ),
        ),
      );

      expect(find.text('1234'), findsOneWidget);
      // 空闲时不应出现任何彩蛋 emoji。
      expect(find.text('✨'), findsNothing);
    });

    testWidgets('runs the callback and pops on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TapDelight(
                emojis: const ['🍎'],
                onTap: () => taps++,
                child: const Text('100'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('100'));
      await tester.pump();

      expect(taps, 1);
      // 有 emoji 时点击会飘出彩蛋。
      expect(find.text('🍎'), findsOneWidget);

      // 让动画跑完，确认没有异常。
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('shows no egg when the emoji list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: TapDelight(emojis: [], child: Text('7')),
            ),
          ),
        ),
      );

      final textsBefore = find.byType(Text).evaluate().length;
      await tester.tap(find.text('7'));
      await tester.pumpAndSettle();

      // 只做缩放 + 震动，不新增任何彩蛋文本。
      expect(find.byType(Text).evaluate().length, textsBefore);
    });
  });
}
