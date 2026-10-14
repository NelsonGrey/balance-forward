import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:balance_forward/design_system/bf_theme.dart';

void main() {
  test(
    'uses one responsive gutter contract for phone, tablet, and wide layouts',
    () {
      expect(BfLayout.pageGutterFor(390), 20);
      expect(BfLayout.pageGutterFor(768), 32);
      expect(BfLayout.pageGutterFor(1440), 48);
      expect(BfLayout.isTablet(599), isFalse);
      expect(BfLayout.isTablet(600), isTrue);
    },
  );

  test('Flutter theme matches the shared Balance Forward palette', () {
    final scheme = BfTheme.light.colorScheme;

    expect(scheme.primary, BfColors.brand);
    expect(scheme.secondary, BfColors.accent);
    expect(scheme.surface, BfColors.surface);
    expect(scheme.onSurface, BfColors.ink);
    expect(scheme.error, BfColors.danger);
    expect(BfTheme.light.scaffoldBackgroundColor, BfColors.canvas);
  });

  testWidgets('responsive body caps wide content at the universal width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: BfTheme.light,
        home: Scaffold(
          body: BfResponsiveBody(
            child: ColoredBox(
              key: const Key('responsive-content'),
              color: BfColors.mint,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('responsive-content'))).width,
      BfLayout.contentMaxWidth,
    );
  });
}
