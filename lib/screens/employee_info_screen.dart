import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../models/attendance_report_model.dart';
import '../models/employee_document_model.dart';
import '../models/employee_model.dart';
import '../models/weekly_work_report_model.dart';
import '../providers/employee_provider.dart';
import '../services/firebase_service.dart';
import '../services/pdf_service.dart';
import '../utils/app_input_formatters.dart';
import '../utils/date_time_helper.dart';
import '../utils/responsive.dart';
import '../widgets/custom_textfield.dart';
import 'salary_calculator_screen.dart';

class EmployeeInfoScreen extends StatefulWidget {
  const EmployeeInfoScreen({
    this.onCreateEmployee,
    this.onOpenAttendance,
    super.key,
  });

  static const routeName = '/employee-info';

  final VoidCallback? onCreateEmployee;
  final ValueChanged<EmployeeModel>? onOpenAttendance;

  @override
  State<EmployeeInfoScreen> createState() => _EmployeeInfoScreenState();
}

class _EmployeeInfoScreenState extends State<EmployeeInfoScreen> {
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _hoursController = TextEditingController();
  final _sinController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _editReportHorizontalController = ScrollController();
  final _savedReportHorizontalController = ScrollController();

  EmployeeModel? _selectedEmployee;
  bool _isEditing = false;
  DateTime? _joiningDate;
  DateTime? _endDate;
  String? _legalStatus;
  String _employmentType = 'Full-time';
  late DateTime _weekStart;
  late List<_DailyTimeDraft> _weeklyDraft;
  String? _editingWeeklyReportId;

  static const _legalStatuses = [
    'Citizen',
    'Permanent Resident',
    'Work Permit',
    'Student Permit',
    'Visitor Record',
    'Other',
  ];
  static const _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Seasonal',
    'Temporary',
    'Casual',
    'Internship',
    'Other',
  ];

  static const _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
    _weeklyDraft = _emptyWeeklyDraft();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _hourlyRateController.dispose();
    _hoursController.dispose();
    _sinController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _editReportHorizontalController.dispose();
    _savedReportHorizontalController.dispose();
    _disposeWeeklyDraft();
    super.dispose();
  }

  void _selectEmployee(EmployeeModel employee) {
    setState(() {
      _disposeWeeklyDraft();
      _selectedEmployee = employee;
      _isEditing = false;
      _fillEditFields(employee);
      _weekStart = _startOfWeek(DateTime.now());
      _weeklyDraft = _emptyWeeklyDraft();
      _editingWeeklyReportId = null;
    });
  }

  void _fillEditFields(EmployeeModel employee) {
    _nameController.text = employee.name;
    _emailController.text = employee.email;
    _phoneController.text = employee.phone ?? '';
    _roleController.text = employee.role;
    _departmentController.text = employee.department ?? '';
    _hourlyRateController.text = employee.hourlyRate.toStringAsFixed(2);
    _hoursController.text = employee.defaultHours.toStringAsFixed(2);
    _sinController.text = employee.socialSecurityNumber ?? '';
    _emergencyNameController.text = employee.emergencyContactName ?? '';
    _emergencyPhoneController.text = employee.emergencyContactPhone ?? '';
    _joiningDate = employee.joiningDate;
    _endDate = employee.endDate;
    _legalStatus = employee.legalStatus;
    _employmentType = employee.employmentType;
  }

  Future<void> _openCreateEmployee() async {
    final onCreateEmployee = widget.onCreateEmployee;
    if (onCreateEmployee != null) {
      onCreateEmployee();
      return;
    }

    final employeeId = await context.push<String>(AppRoutes.createEmployee);
    if (!mounted || employeeId == null) return;

    final employee = context.read<EmployeeProvider>().findById(employeeId);
    if (employee != null) _selectEmployee(employee);
  }

  void _openCalculator() {
    final employee = _selectedEmployee;
    if (employee == null) return;

    context.push(
      AppRoutes.salaryCalculator,
      extra: SalaryCalculatorArgs(employeeId: employee.id),
    );
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onChanged,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onChanged(picked));
  }

  Future<void> _pickWeekStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _weekStart = _startOfWeek(picked));
  }

  Future<void> _pickTime(_DailyTimeDraft draft, {required bool checkIn}) async {
    final current = checkIn ? draft.checkIn : draft.checkOut;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      if (checkIn) {
        draft.checkIn = picked;
      } else {
        draft.checkOut = picked;
      }
    });
  }

  Future<void> _updateWeeklyReport() async {
    final employee = _selectedEmployee;
    final reportId = _editingWeeklyReportId;
    if (employee == null || reportId == null) return;

    final entries = [
      for (final draft in _weeklyDraft)
        DailyWorkEntry(
          dayName: draft.dayName,
          checkInMinutes: _minutes(draft.checkIn),
          checkOutMinutes: _minutes(draft.checkOut),
          attendanceNote: _emptyToNull(draft.noteController.text),
          attendanceStatus: draft.attendanceStatus,
          attendanceReason: draft.attendanceReason,
          hourlyRateOverride: draft.hourlyRateOverride,
        ),
    ];
    final totalHours = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.workingHours,
    );
    final hasStatusRecord = entries.any(
      (entry) =>
          entry.attendanceStatus != 'Present' ||
          (entry.attendanceReason?.trim().isNotEmpty ?? false) ||
          (entry.attendanceNote?.trim().isNotEmpty ?? false),
    );
    if (totalHours <= 0 && !hasStatusRecord) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one check-in/check-out.')),
      );
      return;
    }

    final existing = context
        .read<EmployeeProvider>()
        .weeklyReportsFor(employee.id)
        .where((report) => report.id == reportId)
        .firstOrNull;
    if (existing == null) return;

    final report = WeeklyWorkReportModel(
      id: existing.id,
      employeeId: employee.id,
      weekStart: _weekStart,
      entries: entries,
      createdAt: existing.createdAt,
    );

    await context.read<EmployeeProvider>().updateWeeklyReport(report);
    setState(() {
      _disposeWeeklyDraft();
      _editingWeeklyReportId = null;
      _weeklyDraft = _emptyWeeklyDraft();
      _weekStart = _startOfWeek(DateTime.now());
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Weekly report updated: ${totalHours.toStringAsFixed(2)} hours',
        ),
      ),
    );
  }

  Future<void> _saveEmployee() async {
    final employee = _selectedEmployee;
    if (employee == null || !_formKey.currentState!.validate()) return;

    final updated = EmployeeModel(
      id: employee.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _roleController.text.trim(),
      hourlyRate: double.parse(_hourlyRateController.text.trim()),
      employmentType: _employmentType,
      defaultHours: double.parse(_hoursController.text.trim()),
      phone: _emptyToNull(_phoneController.text),
      department: _emptyToNull(_departmentController.text),
      socialSecurityNumber: _emptyToNull(_sinController.text),
      emergencyContactName: _emptyToNull(_emergencyNameController.text),
      emergencyContactPhone: _emptyToNull(_emergencyPhoneController.text),
      joiningDate: _joiningDate,
      endDate: _endDate,
      legalStatus: _legalStatus,
      passportFilePath: employee.passportFilePath,
      workPermitFilePath: employee.workPermitFilePath,
      offerLetterFilePath: employee.offerLetterFilePath,
      additionalDocumentPaths: employee.additionalDocumentPaths,
      hourlyRateHistory: employee.hourlyRateHistory,
    );

    final provider = context.read<EmployeeProvider>();
    await provider.updateEmployee(updated);
    final savedEmployee = provider.findById(updated.id) ?? updated;
    setState(() {
      _selectedEmployee = savedEmployee;
      _isEditing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${updated.name} updated')));
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _email(String? value) {
    final required = _required(value);
    if (required != null) return required;
    final trimmed = value!.trim();
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a number greater than 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _openCreateEmployee,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Create Employee'),
            ),
          ),
        ],
      ),
      body: Consumer<EmployeeProvider>(
        builder: (context, provider, _) {
          final employees = _filtered(provider.employees);
          if (_selectedEmployee == null && provider.employees.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _selectEmployee(provider.employees.first),
            );
          }

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Responsive(
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 390, child: _directoryPanel(employees)),
                  const SizedBox(width: 20),
                  Expanded(child: _detailsPanel()),
                ],
              ),
              compact: ListView(
                children: [
                  _directoryPanel(employees),
                  const SizedBox(height: 20),
                  _detailsPanel(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<EmployeeModel> _filtered(List<EmployeeModel> employees) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return employees;

    return employees.where((employee) {
      return employee.name.toLowerCase().contains(query) ||
          employee.id.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.role.toLowerCase().contains(query) ||
          (employee.department ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Widget _directoryPanel(List<EmployeeModel> employees) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Employee Directory',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name, ID, email, role',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Text('${employees.length} employees'),
            const SizedBox(height: 8),
            if (employees.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(child: Text('No employees found.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: employees.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final employee = employees[index];
                  final selected = employee.id == _selectedEmployee?.id;
                  return ListTile(
                    selected: selected,
                    selectedTileColor: const Color(0xFFEAF2FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE2E8F0),
                      foregroundColor: selected
                          ? Colors.white
                          : const Color(0xFF334155),
                      child: Text(
                        employee.name.isEmpty
                            ? '?'
                            : employee.name[0].toUpperCase(),
                      ),
                    ),
                    title: Text(employee.name),
                    subtitle: Text('${employee.id} - ${employee.role}'),
                    trailing: Text(
                      DateTimeHelper.currency(employee.hourlyRate),
                    ),
                    onTap: () => _selectEmployee(employee),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailsPanel() {
    final employee = _selectedEmployee;
    if (employee == null) {
      return const Card(
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 420,
          child: Center(child: Text('Select an employee to view details.')),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _isEditing ? _editForm(employee) : _readOnlyDetails(employee),
      ),
    );
  }

  Widget _readOnlyDetails(EmployeeModel employee) {
    return ListView(
      shrinkWrap: true,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                employee.name.isEmpty ? '?' : employee.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${employee.role} - ${employee.id}'),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _openCalculator,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Payroll'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _openAttendanceRecords(employee),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Attendance Records'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => setState(() {
                _fillEditFields(employee);
                _isEditing = true;
              }),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _section('Profile', [
          _detail('Employee ID', employee.id),
          _detail('Designation', employee.role),
          _detail('Employment Type', employee.employmentType),
          _detail('Department', employee.department ?? '-'),
          _detail('Hourly Rate', DateTimeHelper.currency(employee.hourlyRate)),
          _detail(
            'Default Working Hours',
            employee.defaultHours.toStringAsFixed(2),
          ),
        ]),
        if (employee.hourlyRateHistory.isNotEmpty)
          _section('Hourly Rate History', [
            for (final change in employee.hourlyRateHistory.reversed)
              _detail(
                DateTimeHelper.formatDateTime(change.effectiveAt),
                '${DateTimeHelper.currency(change.previousRate)} -> '
                '${DateTimeHelper.currency(change.newRate)}',
              ),
          ]),
        _section('Contact', [
          _detail('Email', employee.email),
          _detail('Phone', employee.phone ?? '-'),
          _detail('Emergency Contact', employee.emergencyContactName ?? '-'),
          _detail('Emergency Phone', employee.emergencyContactPhone ?? '-'),
        ]),
        _section('Identity / Legal', [
          _detail(
            'Social Security / SIN',
            employee.socialSecurityNumber ?? '-',
          ),
          _detail('Legal Status', employee.legalStatus ?? '-'),
          _documentDetail('Work Permit', employee.workPermitFilePath),
          _documentDetail('Passport', employee.passportFilePath),
        ]),
        _section('Employment', [
          _detail('Joining Date', _date(employee.joiningDate)),
          _detail('End Date', _date(employee.endDate)),
          _documentDetail('Offer Letter', employee.offerLetterFilePath),
        ]),
        _weeklyReportsSection(employee),
      ],
    );
  }

  Widget _editForm(EmployeeModel employee) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Employee',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _fillEditFields(employee);
                  _isEditing = false;
                }),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saveEmployee,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _field(
                _nameController,
                'Employee Name',
                validator: _required,
                inputFormatters: [
                  AppInputFormatters.textOnly,
                  AppInputFormatters.capitalizeFirst,
                ],
                textCapitalization: TextCapitalization.words,
              ),
              _field(
                _emailController,
                'Email',
                validator: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                _phoneController,
                'Phone',
                keyboardType: TextInputType.phone,
                inputFormatters: [AppInputFormatters.phone],
              ),
              _field(
                _roleController,
                'Designation / Role',
                validator: _required,
                inputFormatters: [
                  AppInputFormatters.textOnly,
                  AppInputFormatters.capitalizeFirst,
                ],
                textCapitalization: TextCapitalization.words,
              ),
              _field(
                _departmentController,
                'Department',
                inputFormatters: [
                  AppInputFormatters.textOnly,
                  AppInputFormatters.capitalizeFirst,
                ],
                textCapitalization: TextCapitalization.words,
              ),
              _field(
                _hourlyRateController,
                'Hourly Rate',
                validator: _positiveNumber,
                keyboardType: TextInputType.number,
                prefixText: r'$',
                inputFormatters: [AppInputFormatters.number],
              ),
              _field(
                _hoursController,
                'Default Working Hours',
                validator: _positiveNumber,
                keyboardType: TextInputType.number,
                inputFormatters: [AppInputFormatters.number],
              ),
              _field(
                _sinController,
                'Social Security / SIN',
                keyboardType: TextInputType.number,
                inputFormatters: [AppInputFormatters.digitsOnly],
              ),
              _field(
                _emergencyNameController,
                'Emergency Contact Name',
                inputFormatters: [
                  AppInputFormatters.textOnly,
                  AppInputFormatters.capitalizeFirst,
                ],
                textCapitalization: TextCapitalization.words,
              ),
              _field(
                _emergencyPhoneController,
                'Emergency Contact Phone',
                keyboardType: TextInputType.phone,
                inputFormatters: [AppInputFormatters.phone],
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  initialValue: _employmentType,
                  decoration: const InputDecoration(
                    labelText: 'Employment Type',
                  ),
                  items: [
                    for (final type in _employmentTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _employmentType = value);
                  },
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  initialValue: _legalStatus,
                  decoration: const InputDecoration(labelText: 'Legal Status'),
                  items: [
                    for (final status in _legalStatuses)
                      DropdownMenuItem(value: status, child: Text(status)),
                  ],
                  onChanged: (value) => setState(() => _legalStatus = value),
                ),
              ),
              _dateButton('Joining Date', _joiningDate, (value) {
                _joiningDate = value;
              }),
              _dateButton('End Date', _endDate, (value) {
                _endDate = value;
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? prefixText,
    FormFieldValidator<String>? validator,
    List<dynamic>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return SizedBox(
      width: 280,
      child: CustomTextField(
        controller: controller,
        label: label,
        keyboardType: keyboardType,
        prefixText: prefixText,
        validator: validator,
        inputFormatters: inputFormatters?.cast(),
        textCapitalization: textCapitalization,
      ),
    );
  }

  Widget _dateButton(
    String label,
    DateTime? value,
    ValueChanged<DateTime?> update,
  ) {
    return SizedBox(
      width: 280,
      child: OutlinedButton.icon(
        onPressed: () => _pickDate(current: value, onChanged: update),
        icon: const Icon(Icons.calendar_month_outlined),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text(value == null ? 'Select' : DateTimeHelper.formatDate(value)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E2EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 12, children: children),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _documentDetail(String label, String? storedReference) {
    final hasDocument =
        storedReference != null && storedReference.trim().isNotEmpty;
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          if (!hasDocument)
            const Text('-', style: TextStyle(fontWeight: FontWeight.w700))
          else
            OutlinedButton.icon(
              onPressed: () => _openEmployeeDocument(
                label: label,
                storedReference: storedReference,
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(
                _fileName(storedReference),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEmployeeDocument({
    required String label,
    required String storedReference,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _EmployeeDocumentDialog(
        title: label,
        storedReference: storedReference,
        service: context.read<FirebaseService>(),
      ),
    );
  }

  String _date(DateTime? value) {
    return value == null ? '-' : DateTimeHelper.formatDate(value);
  }

  String _fileName(String? path) {
    if (path == null || path.isEmpty) return '-';

    try {
      final payload = jsonDecode(path);
      if (payload is Map<String, dynamic> &&
          (payload['storageType'] == 'firestoreBase64' ||
              payload['storageType'] == 'firestoreDocument')) {
        final fileName = payload['fileName'] as String?;
        return fileName == null || fileName.isEmpty
            ? 'Stored document'
            : fileName;
      }
    } catch (_) {
      // Old records may contain a URL/local path instead of the new JSON
      // payload, so keep the legacy display behavior below.
    }

    return path.split(RegExp(r'[\\/]')).last;
  }

  Widget _weeklyReportsSection(EmployeeModel employee) {
    final reports = context.watch<EmployeeProvider>().weeklyReportsFor(
      employee.id,
    );
    final totalDraftHours = _weeklyDraft.fold<double>(
      0,
      (sum, draft) => sum + _draftHours(draft),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E2EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weekly Time Reports',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Employee check-in/check-out creates these reports. Owner can review and update times here.',
          ),
          if (_editingWeeklyReportId != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Editing Week: ${DateTimeHelper.formatDate(_weekStart)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickWeekStart,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Change Week'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Scrollbar(
              controller: _editReportHorizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _editReportHorizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Day')),
                    DataColumn(label: Text('Check In')),
                    DataColumn(label: Text('Check Out')),
                    DataColumn(label: Text('Gross Hours')),
                    DataColumn(label: Text('Unpaid Break')),
                    DataColumn(label: Text('Net Hours')),
                    DataColumn(label: Text('Attendance Note')),
                  ],
                  rows: [
                    for (final draft in _weeklyDraft)
                      DataRow(
                        cells: [
                          DataCell(Text(draft.dayName)),
                          DataCell(
                            OutlinedButton(
                              onPressed: () => _pickTime(draft, checkIn: true),
                              child: Text(_formatTime(draft.checkIn)),
                            ),
                          ),
                          DataCell(
                            OutlinedButton(
                              onPressed: () => _pickTime(draft, checkIn: false),
                              child: Text(_formatTime(draft.checkOut)),
                            ),
                          ),
                          DataCell(
                            Text(_draftGrossHours(draft).toStringAsFixed(2)),
                          ),
                          DataCell(
                            Text(
                              _draftGrossHours(draft) > 0
                                  ? '${_draftBreakMinutes(draft)} min'
                                  : '-',
                            ),
                          ),
                          DataCell(Text(_draftHours(draft).toStringAsFixed(2))),
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: TextField(
                                controller: draft.noteController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  hintText: 'Attendance note',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Weekly Hours: ${totalDraftHours.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _disposeWeeklyDraft();
                    _editingWeeklyReportId = null;
                    _weekStart = _startOfWeek(DateTime.now());
                    _weeklyDraft = _emptyWeeklyDraft();
                  }),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _updateWeeklyReport,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Update Weekly Report'),
                ),
              ],
            ),
            const Divider(height: 30),
          ] else
            const SizedBox(height: 14),
          Text(
            'Saved Weekly Reports',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: Text('No weekly reports saved yet.')),
            )
          else
            Scrollbar(
              controller: _savedReportHorizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _savedReportHorizontalController,
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('Week Start')),
                    DataColumn(label: Text('Monday')),
                    DataColumn(label: Text('Tuesday')),
                    DataColumn(label: Text('Wednesday')),
                    DataColumn(label: Text('Thursday')),
                    DataColumn(label: Text('Friday')),
                    DataColumn(label: Text('Saturday')),
                    DataColumn(label: Text('Sunday')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: [
                    for (final report in reports)
                      DataRow(
                        cells: [
                          DataCell(
                            OutlinedButton.icon(
                              onPressed: () => _editWeeklyReport(report),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                          DataCell(
                            Text(DateTimeHelper.formatDate(report.weekStart)),
                          ),
                          for (final entry in report.entries)
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: Text(_entrySummary(entry)),
                              ),
                            ),
                          DataCell(
                            Text(
                              report.totalHours.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_DailyTimeDraft> _emptyWeeklyDraft() {
    return [for (final day in _weekDays) _DailyTimeDraft(dayName: day)];
  }

  void _disposeWeeklyDraft() {
    for (final draft in _weeklyDraft) {
      draft.noteController.dispose();
    }
  }

  void _editWeeklyReport(WeeklyWorkReportModel report) {
    setState(() {
      _disposeWeeklyDraft();
      _editingWeeklyReportId = report.id;
      _weekStart = report.weekStart;
      _weeklyDraft = [
        for (final entry in report.entries)
          _DailyTimeDraft(
            dayName: entry.dayName,
            checkIn: _timeOfDay(entry.checkInMinutes),
            checkOut: _timeOfDay(entry.checkOutMinutes),
            note: entry.attendanceNote,
            attendanceStatus: entry.attendanceStatus,
            attendanceReason: entry.attendanceReason,
            hourlyRateOverride: entry.hourlyRateOverride,
          ),
      ];
    });
  }

  DateTime _startOfWeek(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  int? _minutes(TimeOfDay? value) {
    if (value == null) return null;
    return (value.hour * 60) + value.minute;
  }

  TimeOfDay? _timeOfDay(int? minutes) {
    if (minutes == null) return null;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  double _draftHours(_DailyTimeDraft draft) {
    return (_draftGrossHours(draft) - (_draftBreakMinutes(draft) / 60)).clamp(
      0,
      double.infinity,
    );
  }

  int _draftBreakMinutes(_DailyTimeDraft draft) {
    final gross = _draftGrossHours(draft);
    if (gross >= 8) return 30;
    if (gross >= 5) return 15;
    return 0;
  }

  double _draftGrossHours(_DailyTimeDraft draft) {
    final start = _minutes(draft.checkIn);
    final end = _minutes(draft.checkOut);
    if (start == null || end == null) return 0;

    final minutes = end >= start ? end - start : (24 * 60 - start) + end;
    return minutes / 60;
  }

  String _formatTime(TimeOfDay? value) {
    if (value == null) return 'Select';
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _entrySummary(DailyWorkEntry entry) {
    final checkIn = _formatTime(_timeOfDay(entry.checkInMinutes));
    final checkOut = _formatTime(_timeOfDay(entry.checkOutMinutes));
    final hours = entry.workingHours.toStringAsFixed(2);
    final note = entry.attendanceNote?.trim();
    final summary =
        '$checkIn - $checkOut\n$hours net hrs '
        '(${entry.breakMinutes} min unpaid break)\n${entry.attendanceStatus}';
    if (note == null || note.isEmpty) return summary;
    return '$summary\nNote: $note';
  }

  Future<void> _openAttendanceRecords(EmployeeModel employee) {
    final onOpenAttendance = widget.onOpenAttendance;
    if (onOpenAttendance != null) {
      onOpenAttendance(employee);
      return Future.value();
    }

    return context.push<void>(AppRoutes.attendanceRecord(employee.id));
  }
}

class _DailyTimeDraft {
  _DailyTimeDraft({
    required this.dayName,
    this.checkIn,
    this.checkOut,
    String? note,
    this.attendanceStatus = 'Present',
    this.attendanceReason,
    this.hourlyRateOverride,
  }) : noteController = TextEditingController(text: note ?? '');

  final String dayName;
  TimeOfDay? checkIn;
  TimeOfDay? checkOut;
  final TextEditingController noteController;
  final String attendanceStatus;
  final String? attendanceReason;
  final double? hourlyRateOverride;
}

class _EmployeeDocumentDialog extends StatefulWidget {
  const _EmployeeDocumentDialog({
    required this.title,
    required this.storedReference,
    required this.service,
  });

  final String title;
  final String storedReference;
  final FirebaseService service;

  @override
  State<_EmployeeDocumentDialog> createState() =>
      _EmployeeDocumentDialogState();
}

class _EmployeeDocumentDialogState extends State<_EmployeeDocumentDialog> {
  late final Future<EmployeeDocumentData> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = widget.service.fetchEmployeeDocument(
      widget.storedReference,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 900,
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: FutureBuilder<EmployeeDocumentData>(
          future: _documentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final document = snapshot.data!;
            if (document.reference.contentType == 'application/pdf') {
              return PdfPreview(
                build: (_) async => document.bytes,
                pdfFileName: document.reference.fileName,
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowSharing: false,
              );
            }
            if (document.reference.contentType.startsWith('image/')) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Center(
                  child: Image.memory(document.bytes, fit: BoxFit.contain),
                ),
              );
            }
            return Center(
              child: Text(
                '${document.reference.fileName}\n'
                '${document.reference.sizeBytes} bytes',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class AttendanceRecordsScreen extends StatefulWidget {
  const AttendanceRecordsScreen({
    required this.employee,
    this.onBack,
    super.key,
  });

  final EmployeeModel employee;
  final VoidCallback? onBack;

  @override
  State<AttendanceRecordsScreen> createState() =>
      _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  static const _attendanceEditPin = '1122';

  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  _AttendanceViewMode _viewMode = _AttendanceViewMode.weekly;
  DateTime _anchorDate = DateTime.now();
  DateTimeRange? _customRange;
  bool _isEditEnabled = false;

  static const _statusOptions = ['Present', 'Absent', 'Holiday'];

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  DateTime get _periodStart {
    if (_viewMode == _AttendanceViewMode.custom) {
      return _customRange?.start ?? _anchorDate;
    }
    final date = DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);
    if (_viewMode == _AttendanceViewMode.monthly) {
      return DateTime(date.year, date.month);
    }
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  DateTime get _periodEnd {
    if (_viewMode == _AttendanceViewMode.custom) {
      return _customRange?.end ?? _anchorDate;
    }
    if (_viewMode == _AttendanceViewMode.monthly) {
      return DateTime(_anchorDate.year, _anchorDate.month + 1, 0);
    }
    return _periodStart.add(const Duration(days: 6));
  }

  Future<void> _pickCalendarDate() async {
    if (_viewMode == _AttendanceViewMode.custom) {
      await _pickCustomRange();
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _anchorDate = picked);
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange:
          _customRange ?? DateTimeRange(start: _periodStart, end: _periodEnd),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select attendance date range',
    );
    if (picked == null) return;
    setState(() {
      _customRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day),
      );
      _anchorDate = _customRange!.start;
    });
  }

  void _movePeriod(int direction) {
    setState(() {
      if (_viewMode == _AttendanceViewMode.custom) {
        final range = _customRange;
        if (range == null) return;
        final length = range.duration.inDays + 1;
        final shift = Duration(days: length * direction);
        _customRange = DateTimeRange(
          start: range.start.add(shift),
          end: range.end.add(shift),
        );
        _anchorDate = _customRange!.start;
      } else {
        _anchorDate = _viewMode == _AttendanceViewMode.weekly
            ? _anchorDate.add(Duration(days: 7 * direction))
            : DateTime(_anchorDate.year, _anchorDate.month + direction, 1);
      }
    });
  }

  void _clearDateFilter() {
    setState(() {
      _viewMode = _AttendanceViewMode.weekly;
      _anchorDate = DateTime.now();
      _customRange = null;
    });
  }

  Future<void> _unlockEditing() async {
    if (_isEditEnabled) {
      setState(() => _isEditEnabled = false);
      return;
    }

    var enteredPin = '';
    final unlocked = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unlock Attendance Editing'),
        content: TextField(
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [AppInputFormatters.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Owner PIN',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onChanged: (value) => enteredPin = value,
          onSubmitted: (_) {
            Navigator.of(dialogContext).pop(enteredPin == _attendanceEditPin);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(enteredPin == _attendanceEditPin);
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (unlocked == true) {
      setState(() => _isEditEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance editing enabled.')),
      );
    } else if (unlocked == false && enteredPin.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect owner PIN.')));
    }
  }

  Future<void> _updateEntry(
    _AttendanceRecord record,
    DailyWorkEntry entry,
  ) async {
    if (!_isEditEnabled) return;
    await context.read<EmployeeProvider>().upsertDailyEntry(
      employeeId: widget.employee.id,
      date: record.date,
      entry: entry,
    );
    if (mounted) setState(() {});
  }

  List<AttendanceReportRow> _printRows(List<_AttendanceRecord> records) {
    return [
      for (final record in records)
        AttendanceReportRow(
          date: record.date,
          entry: record.entry,
          hourlyRate:
              record.entry.hourlyRateOverride ??
              widget.employee.hourlyRateAt(record.date),
        ),
    ];
  }

  Future<void> _print(List<_AttendanceRecord> records) {
    return const PdfService().printAttendanceReport(
      employee: widget.employee,
      rows: _printRows(records),
      periodStart: _periodStart,
      periodEnd: _periodEnd,
    );
  }

  Future<void> _share(List<_AttendanceRecord> records) async {
    if (widget.employee.email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add an email address to this employee profile before sending.',
          ),
        ),
      );
      return;
    }

    final shared = await const PdfService().shareAttendanceReport(
      employee: widget.employee,
      rows: _printRows(records),
      periodStart: _periodStart,
      periodEnd: _periodEnd,
    );
    if (!mounted || shared) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email/share is not available on this device.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to employees',
          onPressed: widget.onBack ?? () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.employee.name} Attendance Records'),
            Text(
              '${widget.employee.id} | ${widget.employee.role}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _unlockEditing,
              icon: Icon(
                _isEditEnabled ? Icons.lock_open : Icons.edit_outlined,
              ),
              label: Text(_isEditEnabled ? 'Lock Editing' : 'Edit Records'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Consumer<EmployeeProvider>(
          builder: (context, employeeProvider, child) {
            final records = _attendanceRecords(employeeProvider);
            final reportRows = _printRows(records);
            final summary = AttendancePeriodSummary.fromRows(reportRows);
            final absenceLabel = _viewMode == _AttendanceViewMode.weekly
                ? 'This Week Absences'
                : 'Period Absences';

            return LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 850;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<_AttendanceViewMode>(
                          segments: const [
                            ButtonSegment(
                              value: _AttendanceViewMode.weekly,
                              icon: Icon(Icons.view_week_outlined),
                              label: Text('Weekly'),
                            ),
                            ButtonSegment(
                              value: _AttendanceViewMode.monthly,
                              icon: Icon(Icons.calendar_month_outlined),
                              label: Text('Monthly'),
                            ),
                            ButtonSegment(
                              value: _AttendanceViewMode.custom,
                              icon: Icon(Icons.date_range_outlined),
                              label: Text('Custom'),
                            ),
                          ],
                          selected: {_viewMode},
                          onSelectionChanged: (selection) {
                            setState(() {
                              final previousStart = _periodStart;
                              final previousEnd = _periodEnd;
                              _viewMode = selection.first;
                              if (_viewMode == _AttendanceViewMode.custom) {
                                _customRange ??= DateTimeRange(
                                  start: previousStart,
                                  end: previousEnd,
                                );
                                _anchorDate = _customRange!.start;
                              }
                            });
                          },
                        ),
                        IconButton(
                          tooltip: 'Previous period',
                          onPressed: () => _movePeriod(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickCalendarDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            '${DateTimeHelper.formatDate(_periodStart)} - '
                            '${DateTimeHelper.formatDate(_periodEnd)}',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _clearDateFilter,
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Date Filter'),
                        ),
                        IconButton(
                          tooltip: 'Next period',
                          onPressed: () => _movePeriod(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _print(records),
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Print'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _share(records),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email Report'),
                        ),
                        Chip(
                          avatar: Icon(
                            _isEditEnabled ? Icons.lock_open : Icons.lock,
                            size: 18,
                          ),
                          label: Text(
                            _isEditEnabled
                                ? 'Editing enabled'
                                : 'Read-only records',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _AttendanceSummaryTile(
                          label: 'Gross Hours',
                          value: summary.totalGrossHours.toStringAsFixed(2),
                          icon: Icons.schedule_outlined,
                          width: compact ? 160 : 185,
                        ),
                        _AttendanceSummaryTile(
                          label: 'Break Deducted',
                          value: '${summary.totalBreakMinutes} min',
                          icon: Icons.free_breakfast_outlined,
                          width: compact ? 160 : 185,
                        ),
                        _AttendanceSummaryTile(
                          label: 'Net Hours',
                          value: summary.totalNetHours.toStringAsFixed(2),
                          icon: Icons.timelapse_outlined,
                          width: compact ? 160 : 185,
                        ),
                        _AttendanceSummaryTile(
                          label: 'Total Earnings',
                          value: DateTimeHelper.currency(summary.totalEarnings),
                          icon: Icons.payments_outlined,
                          width: compact ? 160 : 185,
                        ),
                        _AttendanceSummaryTile(
                          label: absenceLabel,
                          value: summary.absentDays.toString(),
                          icon: Icons.person_off_outlined,
                          width: compact ? 160 : 185,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Break policy: deduct 15 minutes from each shift of at least 5 hours, or 30 minutes from each shift of at least 8 hours.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: 2500,
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                controller: _verticalController,
                                child: DataTable(
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Day')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Reason')),
                                    DataColumn(label: Text('Check In')),
                                    DataColumn(label: Text('Check Out')),
                                    DataColumn(label: Text('Gross Hours')),
                                    DataColumn(label: Text('Break Deducted')),
                                    DataColumn(label: Text('Net Hours')),
                                    DataColumn(label: Text('Hourly Rate')),
                                    DataColumn(label: Text('Break Value')),
                                    DataColumn(label: Text('Net Daily Pay')),
                                    DataColumn(label: Text('Note')),
                                  ],
                                  rows: [
                                    for (final record in records)
                                      _attendanceRow(record),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickRecordTime(
    _AttendanceRecord record, {
    required bool checkIn,
  }) async {
    final currentMinutes = checkIn
        ? record.entry.checkInMinutes
        : record.entry.checkOutMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _timeOfDay(currentMinutes) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;

    final original = record.entry;
    await _updateEntry(
      record,
      DailyWorkEntry(
        dayName: original.dayName,
        checkInMinutes: checkIn ? _minutes(picked) : original.checkInMinutes,
        checkOutMinutes: checkIn ? original.checkOutMinutes : _minutes(picked),
        attendanceNote: original.attendanceNote,
        attendanceStatus: 'Present',
        attendanceReason: original.attendanceReason,
        hourlyRateOverride: original.hourlyRateOverride,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${checkIn ? 'Check-in' : 'Check-out'} updated for '
          '${DateTimeHelper.formatDate(record.date)}',
        ),
      ),
    );
  }

  DataRow _attendanceRow(_AttendanceRecord record) {
    final entry = record.entry;
    final rate =
        entry.hourlyRateOverride ?? widget.employee.hourlyRateAt(record.date);
    return DataRow(
      cells: [
        DataCell(Text(DateTimeHelper.formatDate(record.date))),
        DataCell(Text(entry.dayName)),
        DataCell(
          SizedBox(
            width: 135,
            child: DropdownButton<String>(
              value: _displayStatus(entry.attendanceStatus),
              hint: const Text('Set status'),
              isExpanded: true,
              items: [
                for (final status in _statusOptions)
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: !_isEditEnabled
                  ? null
                  : (value) {
                      if (value == null) return;
                      _updateEntry(
                        record,
                        entry.copyWith(attendanceStatus: value),
                      );
                    },
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 190,
            child: _AttendanceTextField(
              key: ValueKey('reason-${record.date.toIso8601String()}'),
              initialValue: entry.attendanceReason ?? '',
              hintText: 'Status reason',
              enabled: _isEditEnabled,
              onSaved: (value) => _updateEntry(
                record,
                entry.copyWith(
                  attendanceReason: value.trim(),
                  clearAttendanceReason: value.trim().isEmpty,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          OutlinedButton(
            onPressed: _canEditEntryTime(entry)
                ? () => _pickRecordTime(record, checkIn: true)
                : null,
            child: Text(_formatEntryTime(entry.checkInMinutes)),
          ),
        ),
        DataCell(
          OutlinedButton(
            onPressed: _canEditEntryTime(entry)
                ? () => _pickRecordTime(record, checkIn: false)
                : null,
            child: Text(_formatEntryTime(entry.checkOutMinutes)),
          ),
        ),
        DataCell(Text(entry.grossWorkingHours.toStringAsFixed(2))),
        DataCell(Text('${entry.breakMinutes} min')),
        DataCell(Text(entry.workingHours.toStringAsFixed(2))),
        DataCell(
          SizedBox(
            width: 105,
            child: _AttendanceTextField(
              key: ValueKey('rate-${record.date.toIso8601String()}'),
              initialValue: rate.toStringAsFixed(2),
              hintText: 'Rate',
              numeric: true,
              enabled: _isEditEnabled,
              onSaved: (value) {
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed < 0) return;
                _updateEntry(
                  record,
                  entry.copyWith(hourlyRateOverride: parsed),
                );
              },
            ),
          ),
        ),
        DataCell(
          Text(DateTimeHelper.currency((entry.breakMinutes / 60) * rate)),
        ),
        DataCell(Text(DateTimeHelper.currency(entry.workingHours * rate))),
        DataCell(
          SizedBox(
            width: 220,
            child: _AttendanceTextField(
              key: ValueKey('note-${record.date.toIso8601String()}'),
              initialValue: entry.attendanceNote ?? '',
              hintText: 'Attendance note',
              enabled: _isEditEnabled,
              onSaved: (value) => _updateEntry(
                record,
                DailyWorkEntry(
                  dayName: entry.dayName,
                  checkInMinutes: entry.checkInMinutes,
                  checkOutMinutes: entry.checkOutMinutes,
                  attendanceNote: value.trim(),
                  attendanceStatus: entry.attendanceStatus,
                  attendanceReason: entry.attendanceReason,
                  hourlyRateOverride: entry.hourlyRateOverride,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_AttendanceRecord> _attendanceRecords(EmployeeProvider provider) {
    final records = <_AttendanceRecord>[];
    var date = _periodStart;
    while (!date.isAfter(_periodEnd)) {
      final saved = provider.dailyEntryForDate(
        employeeId: widget.employee.id,
        date: date,
      );
      final entry = saved == null
          ? DailyWorkEntry(
              dayName: DateFormat('EEEE').format(date),
              attendanceStatus: 'Not Set',
            )
          : _normalizeLegacyBlankEntry(saved);
      records.add(_AttendanceRecord(date: date, entry: entry));
      date = date.add(const Duration(days: 1));
    }
    return records;
  }

  DailyWorkEntry _normalizeLegacyBlankEntry(DailyWorkEntry entry) {
    final hasNoAttendanceData =
        entry.checkInMinutes == null &&
        entry.checkOutMinutes == null &&
        (entry.attendanceNote?.trim().isEmpty ?? true) &&
        (entry.attendanceReason?.trim().isEmpty ?? true);
    if (entry.attendanceStatus == 'Present' && hasNoAttendanceData) {
      return entry.copyWith(attendanceStatus: 'Not Set');
    }
    return entry;
  }

  String? _displayStatus(String status) {
    return switch (status.toLowerCase()) {
      'present' => 'Present',
      'absent' => 'Absent',
      'holiday' || 'store holiday' || 'festival' => 'Holiday',
      _ => null,
    };
  }

  bool _canEditEntryTime(DailyWorkEntry entry) {
    if (!_isEditEnabled) return false;
    final status = _displayStatus(entry.attendanceStatus);
    return status == null || status == 'Present';
  }

  String _formatEntryTime(int? minutes) {
    if (minutes == null) return '-';
    final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay? _timeOfDay(int? minutes) {
    if (minutes == null) return null;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  int _minutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }
}

class _AttendanceSummaryTile extends StatelessWidget {
  const _AttendanceSummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.18),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AttendanceViewMode { weekly, monthly, custom }

class _AttendanceRecord {
  const _AttendanceRecord({required this.date, required this.entry});

  final DateTime date;
  final DailyWorkEntry entry;
}

class _AttendanceTextField extends StatefulWidget {
  const _AttendanceTextField({
    required this.initialValue,
    required this.hintText,
    required this.onSaved,
    this.numeric = false,
    this.enabled = true,
    super.key,
  });

  final String initialValue;
  final String hintText;
  final ValueChanged<String> onSaved;
  final bool numeric;
  final bool enabled;

  @override
  State<_AttendanceTextField> createState() => _AttendanceTextFieldState();
}

class _AttendanceTextFieldState extends State<_AttendanceTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: widget.numeric ? [AppInputFormatters.decimal4] : null,
      decoration: InputDecoration(hintText: widget.hintText, isDense: true),
      onSubmitted: widget.onSaved,
      onTapOutside: (_) {
        widget.onSaved(_controller.text);
        FocusScope.of(context).unfocus();
      },
    );
  }
}
