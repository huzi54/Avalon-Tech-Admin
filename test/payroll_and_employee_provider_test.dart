import 'package:flutter_payroll_app/models/employee_model.dart';
import 'package:flutter_payroll_app/models/payroll_model.dart';
import 'package:flutter_payroll_app/models/remittance_model.dart';
import 'package:flutter_payroll_app/models/weekly_work_report_model.dart';
import 'package:flutter_payroll_app/providers/employee_provider.dart';
import 'package:flutter_payroll_app/providers/payroll_provider.dart';
import 'package:flutter_payroll_app/services/firebase_service.dart';
import 'package:flutter_payroll_app/services/payroll_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('employee update appends hourly-rate history', () async {
    const employee = EmployeeModel(
      id: 'EMP-1',
      name: 'Taylor',
      email: 'taylor@example.com',
      role: 'Employee',
      hourlyRate: 20,
    );
    final firebase = _FakeFirebaseService(employees: [employee]);
    final provider = EmployeeProvider(firebase);
    await provider.loadEmployees();

    await provider.updateEmployee(employee.copyWith(hourlyRate: 25));

    final saved = provider.findById(employee.id)!;
    expect(saved.hourlyRate, 25);
    expect(saved.hourlyRateHistory, hasLength(1));
    expect(saved.hourlyRateHistory.single.previousRate, 20);
    expect(saved.hourlyRateHistory.single.newRate, 25);
    expect(firebase.savedEmployee?.hourlyRateHistory, hasLength(1));
  });

  test(
    'overpayment creates employee credit without paying remittance',
    () async {
      const employee = EmployeeModel(
        id: 'EMP-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
      );
      final payroll = const PayrollService().calculate(
        employee: employee,
        hours: 40,
        payPeriodStart: DateTime(2026, 6),
        payPeriodEnd: DateTime(2026, 6, 15),
      );
      final remittance = RemittanceModel(
        id: payroll.id,
        employeeId: employee.id,
        employeeName: employee.name,
        email: employee.email,
        payFrequency: payroll.payFrequency,
        payPeriodStart: payroll.payPeriodStart,
        payPeriodEnd: payroll.payPeriodEnd,
        grossPay: payroll.grossPay,
        employeeIncomeTax: payroll.employeeIncomeTax,
        cppDeduction: payroll.cpp,
        employeeCpp: payroll.cpp,
        employerCpp: payroll.employerCpp,
        employeeEi: payroll.ei,
        employerEi: payroll.employerEi,
        netPay: payroll.netPay,
        totalRemittance: payroll.totalRemittance,
        createdAt: payroll.createdAt,
        status: 'Unpaid',
      );
      final firebase = _FakeFirebaseService(
        payrolls: [payroll],
        remittances: [remittance],
      );
      final provider = PayrollProvider(firebase);
      await provider.loadPayrolls();

      await provider.updateSlipPayment(
        payrollId: payroll.id,
        slipStatus: 'Paid',
        paidVia: 'Cash',
        paidAmount: payroll.finalPayableAmount + 25,
      );

      expect(provider.payrolls.single.slipStatus, 'Paid');
      expect(provider.payrolls.single.extraCashGiven, 25);
      expect(provider.outstandingEmployeeCredit(employee.id), 25);
      expect(provider.remittances.single.status, 'Unpaid');
      expect(firebase.savedRemittance, isNull);
    },
  );

  test('payroll periods cannot overlap for the same employee', () async {
    const employee = EmployeeModel(
      id: 'EMP-1',
      name: 'Taylor',
      email: 'taylor@example.com',
      role: 'Employee',
      hourlyRate: 25,
    );
    const otherEmployee = EmployeeModel(
      id: 'EMP-2',
      name: 'Jordan',
      email: 'jordan@example.com',
      role: 'Employee',
      hourlyRate: 25,
    );
    final existing = const PayrollService().calculate(
      id: 'PAY-1',
      employee: employee,
      hours: 75,
      payPeriodStart: DateTime(2026, 6),
      payPeriodEnd: DateTime(2026, 6, 14),
    );
    final firebase = _FakeFirebaseService(payrolls: [existing]);
    final provider = PayrollProvider(firebase);
    await provider.loadPayrolls();

    expect(
      provider.isPayrollDateLocked(
        employeeId: employee.id,
        date: DateTime(2026, 6, 1),
      ),
      isTrue,
    );
    expect(
      provider.isPayrollDateLocked(
        employeeId: employee.id,
        date: DateTime(2026, 6, 15),
      ),
      isFalse,
    );
    await expectLater(
      provider.calculateAndSave(
        employee: employee,
        hours: 40,
        payPeriodStart: DateTime(2026, 6, 10),
        payPeriodEnd: DateTime(2026, 6, 20),
      ),
      throwsA(isA<PayrollPeriodConflictException>()),
    );

    final otherPayroll = await provider.calculateAndSave(
      employee: otherEmployee,
      hours: 40,
      payPeriodStart: DateTime(2026, 6, 10),
      payPeriodEnd: DateTime(2026, 6, 20),
    );
    expect(otherPayroll.employeeId, otherEmployee.id);
    expect(
      provider.conflictingPayroll(
        employeeId: employee.id,
        payPeriodStart: existing.payPeriodStart,
        payPeriodEnd: existing.payPeriodEnd,
        excludingPayrollId: existing.id,
      ),
      isNull,
    );
  });

  test(
    'attendance summary uses date-range hours and historical daily rates',
    () async {
      final employee = EmployeeModel(
        id: 'EMP-1',
        name: 'Taylor',
        email: 'taylor@example.com',
        role: 'Employee',
        hourlyRate: 25,
        hourlyRateHistory: [
          HourlyRateChange(
            previousRate: 20,
            newRate: 25,
            effectiveAt: DateTime(2026, 6, 2),
          ),
        ],
      );
      final report = WeeklyWorkReportModel(
        id: 'week-1',
        employeeId: employee.id,
        weekStart: DateTime(2026, 6),
        entries: const [
          DailyWorkEntry(
            dayName: 'Monday',
            checkInMinutes: 9 * 60,
            checkOutMinutes: 17 * 60,
          ),
          DailyWorkEntry(
            dayName: 'Tuesday',
            checkInMinutes: 9 * 60,
            checkOutMinutes: 17 * 60,
            hourlyRateOverride: 30,
          ),
          DailyWorkEntry(dayName: 'Wednesday'),
          DailyWorkEntry(dayName: 'Thursday'),
          DailyWorkEntry(dayName: 'Friday'),
          DailyWorkEntry(dayName: 'Saturday'),
          DailyWorkEntry(dayName: 'Sunday'),
        ],
        createdAt: DateTime(2026, 6),
      );
      final firebase = _FakeFirebaseService(
        employees: [employee],
        weeklyReports: [report],
      );
      final provider = EmployeeProvider(firebase);
      await provider.loadEmployees();

      final summary = provider.attendancePayrollSummary(
        employeeId: employee.id,
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 6, 7),
      );

      expect(summary.totalHours, 15);
      expect(summary.regularIncome, 375);
      expect(summary.effectiveHourlyRate, 25);
    },
  );

  test('bulk remittance status updates only selected records', () async {
    final first = _remittance(id: 'REM-1');
    final second = _remittance(id: 'REM-2');
    final firebase = _FakeFirebaseService(remittances: [first, second]);
    final provider = PayrollProvider(firebase);
    await provider.loadPayrolls();

    await provider.updateRemittanceStatuses(
      remittanceIds: {'REM-2'},
      status: 'Paid',
    );

    expect(provider.remittances.first.status, 'Unpaid');
    expect(provider.remittances.last.status, 'Paid');
    expect(provider.remittances.last.paidVia, isNull);
    expect(firebase.savedRemittances.map((item) => item.id), ['REM-2']);
  });

  test('owner can create a missing calendar day status record', () async {
    const employee = EmployeeModel(
      id: 'EMP-1',
      name: 'Taylor',
      email: 'taylor@example.com',
      role: 'Employee',
      hourlyRate: 25,
    );
    final firebase = _FakeFirebaseService(employees: [employee]);
    final provider = EmployeeProvider(firebase);
    await provider.loadEmployees();

    await provider.upsertDailyEntry(
      employeeId: employee.id,
      date: DateTime(2026, 6, 17),
      entry: const DailyWorkEntry(
        dayName: 'Wednesday',
        attendanceStatus: 'Absent',
        attendanceReason: 'Sick',
        hourlyRateOverride: 24,
      ),
    );

    final saved = provider.dailyEntryForDate(
      employeeId: employee.id,
      date: DateTime(2026, 6, 17),
    );
    expect(saved?.attendanceStatus, 'Absent');
    expect(saved?.attendanceReason, 'Sick');
    expect(saved?.hourlyRateOverride, 24);
    expect(firebase.savedWeeklyReport, isNotNull);
  });
}

class _FakeFirebaseService extends FirebaseService {
  _FakeFirebaseService({
    this.employees = const [],
    this.payrolls = const [],
    this.remittances = const [],
    this.weeklyReports = const [],
  }) : super(isAvailable: false);

  final List<EmployeeModel> employees;
  final List<PayrollModel> payrolls;
  final List<RemittanceModel> remittances;
  final List<WeeklyWorkReportModel> weeklyReports;

  EmployeeModel? savedEmployee;
  PayrollModel? savedPayroll;
  RemittanceModel? savedRemittance;
  WeeklyWorkReportModel? savedWeeklyReport;
  final List<RemittanceModel> savedRemittances = [];

  @override
  Future<List<EmployeeModel>> fetchEmployees() async => employees;

  @override
  Future<List<WeeklyWorkReportModel>> fetchWeeklyReports({
    String? employeeId,
  }) async => weeklyReports;

  @override
  Future<void> updateEmployee(EmployeeModel employee) async {
    savedEmployee = employee;
  }

  @override
  Future<List<PayrollModel>> fetchPayrolls() async => payrolls;

  @override
  Future<List<RemittanceModel>> fetchRemittances() async => remittances;

  @override
  Future<void> savePayroll(PayrollModel payroll) async {
    savedPayroll = payroll;
  }

  @override
  Future<void> saveRemittance(RemittanceModel remittance) async {
    savedRemittance = remittance;
    savedRemittances.add(remittance);
  }

  @override
  Future<void> saveWeeklyReport(WeeklyWorkReportModel report) async {
    savedWeeklyReport = report;
  }
}

RemittanceModel _remittance({required String id}) {
  return RemittanceModel(
    id: id,
    employeeId: 'EMP-1',
    employeeName: 'Taylor',
    email: 'taylor@example.com',
    payFrequency: 'Biweekly',
    payPeriodStart: DateTime(2026, 6),
    payPeriodEnd: DateTime(2026, 6, 15),
    grossPay: 1000,
    employeeIncomeTax: 100,
    cppDeduction: 50,
    employeeCpp: 50,
    employerCpp: 50,
    employeeEi: 15,
    employerEi: 21,
    netPay: 835,
    totalRemittance: 236,
    createdAt: DateTime(2026, 6, 15),
    status: 'Unpaid',
  );
}
