import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/core/constants/app_strings.dart';
import 'package:hisbatak_app/domain/entities/user_profile.dart';
import 'package:hisbatak_app/presentation/widgets/app_logo_widget.dart';
import 'package:hisbatak_app/presentation/widgets/hisbatak_loader.dart';
import 'package:hisbatak_app/presentation/widgets/hisbatak_mark.dart';
import 'package:hisbatak_app/presentation/widgets/profile_qr_code_widget.dart';

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

    testWidgets('AppLogoWidget shows the mark and the app name',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Center(child: AppLogoWidget(showText: true))),
      );

      expect(find.byType(HisbatakMark), findsOneWidget);
      expect(find.text(AppStrings.appName), findsOneWidget);
    });

    testWidgets(
        'HisbatakQrCodePainter generates an ISO matrix and ProfileQrCodeButton opens bottom sheet',
        (tester) async {
      const profile = UserProfile(
        id: '550e8400-e29b-41d4-a716-446655440000',
        fullName: 'أحمد الحميري',
        email: 'ahmed@hisbatak.local',
        phoneE164: '+967770000000',
        currencyCode: 'YER',
        currencySymbol: 'ر.ي',
        monthlyBudgetLimit: 50000,
        currentAvailable: 50000,
        biometricEnabled: false,
        isDarkMode: false,
        isConfigured: true,
      );

      final painter = HisbatakQrCodePainter(
        data: 'hisbatak://u/${profile.id}',
      );
      expect(painter.matrix.length, greaterThanOrEqualTo(29));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfileQrCodeButton(profile: profile),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProfileQrCodeButton));
      await tester.pumpAndSettle();

      expect(find.text('بطاقة الهوية والـ QR الرقمية'), findsOneWidget);
      expect(find.text('رمز قياسي ISO • جاهز للمسح الفوري'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('نسخ رابط الهوية'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('نسخ رابط الهوية'), findsOneWidget);
    });
  });
}
