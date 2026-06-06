import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../models/weekly_work_report_model.dart';
import '../providers/employee_provider.dart';
import '../utils/app_input_formatters.dart';
import '../utils/date_time_helper.dart';
import '../utils/responsive.dart';
import '../widgets/custom_textfield.dart';
import 'create_employee_screen.dart';
import 'salary_calculator_screen.dart';

class EmployeeInfoScreen extends StatefulWidget {
  const EmployeeInfoScreen({this.onCreateEmployee, super.key});

  static const routeName = '/employee-info';

  final VoidCallback? onCreateEmployee;

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
  }

  Future<void> _openCreateEmployee() async {
    final onCreateEmployee = widget.onCreateEmployee;
    if (onCreateEmployee != null) {
      onCreateEmployee();
      return;
    }

    final employeeId = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const CreateEmployeeScreen()),
    );
    if (!mounted || employeeId == null) return;

    final employee = context.read<EmployeeProvider>().findById(employeeId);
    if (employee != null) _selectEmployee(employee);
  }

  void _openCalculator() {
    final employee = _selectedEmployee;
    if (employee == null) return;

    Navigator.pushNamed(
      context,
      SalaryCalculatorScreen.routeName,
      arguments: SalaryCalculatorArgs(employeeId: employee.id),
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
        ),
    ];
    final totalHours = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.workingHours,
    );
    if (totalHours <= 0) {
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
    );

    await context.read<EmployeeProvider>().updateEmployee(updated);
    setState(() {
      _selectedEmployee = updated;
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
          _detail('Department', employee.department ?? '-'),
          _detail('Hourly Rate', DateTimeHelper.currency(employee.hourlyRate)),
          _detail(
            'Default Working Hours',
            employee.defaultHours.toStringAsFixed(2),
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
          _detail('Work Permit', _fileName(employee.workPermitFilePath)),
          _detail('Passport', _fileName(employee.passportFilePath)),
        ]),
        _section('Employment', [
          _detail('Joining Date', _date(employee.joiningDate)),
          _detail('End Date', _date(employee.endDate)),
          _detail('Offer Letter', _fileName(employee.offerLetterFilePath)),
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

  String _date(DateTime? value) {
    return value == null ? '-' : DateTimeHelper.formatDate(value);
  }

  String _fileName(String? path) {
    if (path == null || path.isEmpty) return '-';

    try {
      final payload = jsonDecode(path);
      if (payload is Map<String, dynamic> &&
          payload['storageType'] == 'firestoreBase64') {
        final fileName = payload['fileName'] as String?;
        return fileName == null || fileName.isEmpty
            ? 'Stored in profile'
            : '$fileName - stored in profile';
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
                    DataColumn(label: Text('Working Hours')),
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
    if (note == null || note.isEmpty) return '$checkIn - $checkOut\n$hours hrs';
    return '$checkIn - $checkOut\n$hours hrs\nNote: $note';
  }

  Future<void> _openAttendanceRecords(EmployeeModel employee) {
    return showDialog<void>(
      context: context,
      builder: (_) => _AttendanceRecordsDialog(employee: employee),
    );
  }
}

class _DailyTimeDraft {
  _DailyTimeDraft({
    required this.dayName,
    this.checkIn,
    this.checkOut,
    String? note,
  }) : noteController = TextEditingController(text: note ?? '');

  final String dayName;
  TimeOfDay? checkIn;
  TimeOfDay? checkOut;
  final TextEditingController noteController;
}

class _AttendanceRecordsDialog extends StatefulWidget {
  const _AttendanceRecordsDialog({required this.employee});

  final EmployeeModel employee;

  @override
  State<_AttendanceRecordsDialog> createState() =>
      _AttendanceRecordsDialogState();
}

class _AttendanceRecordsDialogState extends State<_AttendanceRecordsDialog> {
  final _filterNotifier = ValueNotifier<_AttendanceDateFilter>(
    const _AttendanceDateFilter(),
  );
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _filterNotifier.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.employee.name} Attendance Records'),
      content: SizedBox(
        width: 1020,
        height: 620,
        child: ValueListenableBuilder<_AttendanceDateFilter>(
          valueListenable: _filterNotifier,
          builder: (context, filter, _) {
            final records = _attendanceRecords(filter);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(
                        current: filter.fromDate,
                        onPicked: (value) {
                          _filterNotifier.value = filter.copyWith(
                            fromDate: value,
                          );
                        },
                      ),
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        filter.fromDate == null
                            ? 'From Date'
                            : DateTimeHelper.formatDate(filter.fromDate!),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(
                        current: filter.toDate,
                        onPicked: (value) {
                          _filterNotifier.value = filter.copyWith(
                            toDate: value,
                          );
                        },
                      ),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        filter.toDate == null
                            ? 'To Date'
                            : DateTimeHelper.formatDate(filter.toDate!),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _filterNotifier.value = const _AttendanceDateFilter();
                      },
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear Filter'),
                    ),
                    Text('${records.length} records'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: records.isEmpty
                      ? const Center(
                          child: Text(
                            'No attendance records found for this filter.',
                          ),
                        )
                      : Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _verticalController,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Day')),
                                    DataColumn(label: Text('Check In')),
                                    DataColumn(label: Text('Check Out')),
                                    DataColumn(label: Text('Hours')),
                                    DataColumn(label: Text('Daily Pay')),
                                    DataColumn(label: Text('Note')),
                                  ],
                                  rows: [
                                    for (final record in records)
                                      DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              DateTimeHelper.formatDate(
                                                record.date,
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(record.entry.dayName)),
                                          DataCell(
                                            OutlinedButton(
                                              onPressed: () => _pickRecordTime(
                                                record,
                                                checkIn: true,
                                              ),
                                              child: Text(
                                                _formatEntryTime(
                                                  record.entry.checkInMinutes,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            OutlinedButton(
                                              onPressed: () => _pickRecordTime(
                                                record,
                                                checkIn: false,
                                              ),
                                              child: Text(
                                                _formatEntryTime(
                                                  record.entry.checkOutMinutes,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              record.entry.workingHours
                                                  .toStringAsFixed(2),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              DateTimeHelper.currency(
                                                record.entry.workingHours *
                                                    widget.employee.hourlyRate,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 280,
                                              child: Text(
                                                record.entry.attendanceNote ??
                                                    '-',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _pickRecordTime(
    _AttendanceRecord record, {
    required bool checkIn,
  }) async {
    final employeeProvider = context.read<EmployeeProvider>();
    final currentMinutes = checkIn
        ? record.entry.checkInMinutes
        : record.entry.checkOutMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _timeOfDay(currentMinutes) ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked == null) return;

    final entries = [...record.report.entries];
    final original = entries[record.entryIndex];
    entries[record.entryIndex] = DailyWorkEntry(
      dayName: original.dayName,
      checkInMinutes: checkIn ? _minutes(picked) : original.checkInMinutes,
      checkOutMinutes: checkIn ? original.checkOutMinutes : _minutes(picked),
      attendanceNote: original.attendanceNote,
    );

    await employeeProvider.updateWeeklyReport(
      record.report.copyWith(entries: entries),
    );
    _filterNotifier.value = _filterNotifier.value.copyWith();

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

  List<_AttendanceRecord> _attendanceRecords(_AttendanceDateFilter filter) {
    final reports = context.read<EmployeeProvider>().weeklyReportsFor(
      widget.employee.id,
    );
    final records = <_AttendanceRecord>[];

    for (final report in reports) {
      for (var index = 0; index < report.entries.length; index++) {
        final entry = report.entries[index];
        if (!_hasAttendance(entry)) continue;

        final date = report.weekStart.add(Duration(days: index));
        if (!_isWithinDateFilter(date, filter)) continue;

        records.add(
          _AttendanceRecord(
            date: date,
            entry: entry,
            report: report,
            entryIndex: index,
          ),
        );
      }
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  bool _hasAttendance(DailyWorkEntry entry) {
    return entry.checkInMinutes != null ||
        entry.checkOutMinutes != null ||
        (entry.attendanceNote?.trim().isNotEmpty ?? false);
  }

  bool _isWithinDateFilter(DateTime date, _AttendanceDateFilter filter) {
    final current = DateTime(date.year, date.month, date.day);
    final from = filter.fromDate == null
        ? null
        : DateTime(
            filter.fromDate!.year,
            filter.fromDate!.month,
            filter.fromDate!.day,
          );
    final to = filter.toDate == null
        ? null
        : DateTime(
            filter.toDate!.year,
            filter.toDate!.month,
            filter.toDate!.day,
          );

    if (from != null && current.isBefore(from)) return false;
    if (to != null && current.isAfter(to)) return false;
    return true;
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

class _AttendanceDateFilter {
  const _AttendanceDateFilter({this.fromDate, this.toDate});

  final DateTime? fromDate;
  final DateTime? toDate;

  _AttendanceDateFilter copyWith({DateTime? fromDate, DateTime? toDate}) {
    return _AttendanceDateFilter(
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

class _AttendanceRecord {
  const _AttendanceRecord({
    required this.date,
    required this.entry,
    required this.report,
    required this.entryIndex,
  });

  final DateTime date;
  final DailyWorkEntry entry;
  final WeeklyWorkReportModel report;
  final int entryIndex;
}
