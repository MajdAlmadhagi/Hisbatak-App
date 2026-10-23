import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisbatak_app/presentation/widgets/custom_bottom_sheet.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('CustomBottomSheet Widget Tests', () {
    testWidgets('renders title, subtitle, icon, and body content correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CustomBottomSheet(
            title: 'عنوان الاختبار',
            subtitle: 'وصف تجريبي للشيت',
            icon: Iconsax.add,
            child: Text('محتوى النموذج'),
          ),
        ),
      );

      expect(find.text('عنوان الاختبار'), findsOneWidget);
      expect(find.text('وصف تجريبي للشيت'), findsOneWidget);
      expect(find.byIcon(Iconsax.add), findsOneWidget);
      expect(find.text('محتوى النموذج'), findsOneWidget);
      expect(find.byType(CustomBottomSheetGrabHandle), findsOneWidget);
      expect(find.byIcon(Iconsax.close_circle), findsOneWidget);
    });

    testWidgets('renders sticky footer when provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CustomBottomSheet(
            title: 'مع تذييل',
            footer: ElevatedButton(
              onPressed: null,
              child: Text('زر الحفظ'),
            ),
            child: Text('محتوى داخلي'),
          ),
        ),
      );

      expect(find.text('مع تذييل'), findsOneWidget);
      expect(find.text('محتوى داخلي'), findsOneWidget);
      expect(find.text('زر الحفظ'), findsOneWidget);
    });

    testWidgets('CustomBottomSheet.show opens modal and close button pops it', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                CustomBottomSheet.show(
                  context: context,
                  title: 'مودال نافذة',
                  child: const Text('محتوى داخل المودال'),
                );
              },
              child: const Text('افتح'),
            ),
          ),
        ),
      );

      // Tap open
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('مودال نافذة'), findsOneWidget);
      expect(find.text('محتوى داخل المودال'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Iconsax.close_circle));
      await tester.pumpAndSettle();

      expect(find.text('مودال نافذة'), findsNothing);
      expect(find.text('محتوى داخل المودال'), findsNothing);
    });

    testWidgets('CustomBottomSheet.showConfirmation resolves true on confirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await CustomBottomSheet.showConfirmation(
                  context: context,
                  title: 'تأكيد الحذف',
                  message: 'هل أنت متأكد من رغبتك في حذف هذا العنصر؟',
                  confirmText: 'نعم، حذف',
                  isDanger: true,
                );
              },
              child: const Text('طلب تأكيد'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('طلب تأكيد'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد الحذف'), findsOneWidget);
      expect(find.text('هل أنت متأكد من رغبتك في حذف هذا العنصر؟'), findsOneWidget);
      expect(find.text('نعم، حذف'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('نعم، حذف'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
