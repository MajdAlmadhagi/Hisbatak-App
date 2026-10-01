import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/constants/app_strings.dart';
import 'package:hisbatak_app/presentation/widgets/app_logo_widget.dart';
import 'package:hisbatak_app/presentation/widgets/hisbatak_loader.dart';
import 'package:hisbatak_app/presentation/widgets/hisbatak_mark.dart';

void main() {
  group('Hisbatak brand widgets', () {
    testWidgets('HisbatakLoader keeps animating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: HisbatakLoader())),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('HisbatakLoader stands still when the device reduces motion',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: HisbatakLoader()),
          ),
        ),
      );

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('HisbatakLoader keeps the mark proportions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: HisbatakLoader(size: 66))),
      );

      final size = tester.getSize(find.byType(HisbatakLoader));
      expect(size.height, 66);
      expect(size.width, closeTo(66 * HisbatakMarkPainter.aspectRatio, 0.01));
    });

    testWidgets('AppLogoWidget shows the mark and the app name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: AppLogoWidget(showText: true))),
      );

      expect(find.byType(HisbatakMark), findsOneWidget);
      expect(find.text(AppStrings.appName), findsOneWidget);
    });
  });
}
