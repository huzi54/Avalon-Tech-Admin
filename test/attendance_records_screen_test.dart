import 'package:flutter/material.dart';
import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/providers/employee_provider.dart';
import 'package:flutter_payroll_app/screens/employee_info_screen.dart';
import 'package:flutter_payroll_app/services/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  const employee = EmployeeModel(
    id: 'EMP-1',
    name: 'Taylor',
    email: 'taylor@example.com',
    role: 'Employee',
    hourlyRate: 25,
  );

  testWidgets(
    'attendance records remain responsive and editing is PIN locked',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => EmployeeProvider(FirebaseService(isAvailable: false)),
          child: const MaterialApp(
            home: AttendanceRecordsScreen(employee: employee),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Read-only records'), findsOneWidget);
      expect(find.text('This Week Absences'), findsOneWidget);

      await tester.tap(find.text('Edit Records'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '1122');
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();

      expect(find.text('Editing enabled'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Period Absences'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
