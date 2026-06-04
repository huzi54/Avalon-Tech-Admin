import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../providers/employee_provider.dart';
import '../utils/date_time_helper.dart';
import '../utils/responsive.dart';
import '../widgets/custom_textfield.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});

  static const routeName = '/create-employee';

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _hoursController = TextEditingController(text: '80');
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _socialSecurityController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  DateTime? _joiningDate;
  DateTime? _endDate;
  String _legalStatus = 'Work Permit';
  String? _passportFilePath;
  String? _workPermitFilePath;
  String? _offerLetterFilePath;
  final List<String> _additionalDocumentPaths = [];

  static const _legalStatuses = [
    'Work Permit',
    'Citizen',
    'Permanent Resident',
    'Student Permit',
    'Visitor Record',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _idController.text = _nextEmployeeId();
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _hourlyRateController.dispose();
    _hoursController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _socialSecurityController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  String _nextEmployeeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EMP-${timestamp.toString().substring(8)}';
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    final employee = EmployeeModel(
      id: _idController.text.trim(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _roleController.text.trim(),
      hourlyRate: double.parse(_hourlyRateController.text.trim()),
      defaultHours: double.parse(_hoursController.text.trim()),
      phone: _emptyToNull(_phoneController.text),
      department: _emptyToNull(_departmentController.text),
      socialSecurityNumber: _emptyToNull(_socialSecurityController.text),
      emergencyContactName: _emptyToNull(_emergencyNameController.text),
      emergencyContactPhone: _emptyToNull(_emergencyPhoneController.text),
      joiningDate: _joiningDate,
      endDate: _endDate,
      legalStatus: _legalStatus,
      passportFilePath: _passportFilePath,
      workPermitFilePath: _workPermitFilePath,
      offerLetterFilePath: _offerLetterFilePath,
      additionalDocumentPaths: List.unmodifiable(_additionalDocumentPaths),
    );

    await context.read<EmployeeProvider>().addEmployee(employee);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${employee.name} profile created')));
    Navigator.pop(context, employee.id);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _email(String? value) {
    final required = _requiredText(value);
    if (required != null) return required;
    final trimmed = value!.trim();
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Enter a number greater than 0';
    }
    return null;
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
    if (picked != null) {
      setState(() => onChanged(picked));
    }
  }

  Future<void> _pickFile(ValueChanged<String> onPicked) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return;
    setState(() => onPicked(path));
  }

  Future<void> _pickAdditionalFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;
    final paths = result.files
        .map((file) => file.path)
        .whereType<String>()
        .where((path) => path.isNotEmpty);
    setState(() => _additionalDocumentPaths.addAll(paths));
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Employee Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Employee Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _field(
                            _idController,
                            'Employee ID',
                            validator: _requiredText,
                          ),
                          _field(
                            _nameController,
                            'Full Name',
                            validator: _requiredText,
                          ),
                          _field(
                            _emailController,
                            'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: _email,
                          ),
                          _field(
                            _socialSecurityController,
                            'Social Security / SIN',
                            keyboardType: TextInputType.text,
                          ),
                          _field(
                            _roleController,
                            'Designation / Role',
                            validator: _requiredText,
                          ),
                          _field(_departmentController, 'Department'),
                          _field(
                            _phoneController,
                            'Phone',
                            keyboardType: TextInputType.phone,
                          ),
                          _field(
                            _emergencyNameController,
                            'Emergency Contact Name',
                          ),
                          _field(
                            _emergencyPhoneController,
                            'Emergency Contact Phone',
                            keyboardType: TextInputType.phone,
                          ),
                          _field(
                            _hourlyRateController,
                            'Hourly Rate',
                            keyboardType: TextInputType.number,
                            prefixText: r'$',
                            validator: _positiveNumber,
                          ),
                          _field(
                            _hoursController,
                            'Default Working Hours',
                            keyboardType: TextInputType.number,
                            validator: _positiveNumber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Employment & Legal',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _dateField(
                            label: 'Joining Date',
                            value: _joiningDate,
                            onPick: () => _pickDate(
                              current: _joiningDate,
                              onChanged: (value) => _joiningDate = value,
                            ),
                            onClear: _joiningDate == null
                                ? null
                                : () => setState(() => _joiningDate = null),
                          ),
                          _dateField(
                            label: 'End Date',
                            value: _endDate,
                            onPick: () => _pickDate(
                              current: _endDate,
                              onChanged: (value) => _endDate = value,
                            ),
                            onClear: _endDate == null
                                ? null
                                : () => setState(() => _endDate = null),
                          ),
                          SizedBox(
                            width: 280,
                            child: DropdownButtonFormField<String>(
                              initialValue: _legalStatus,
                              decoration: const InputDecoration(
                                labelText: 'Legal Status',
                              ),
                              items: [
                                for (final status in _legalStatuses)
                                  DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _legalStatus = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Documents',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _documentPicker(
                            label: 'Passport',
                            path: _passportFilePath,
                            onPick: () =>
                                _pickFile((path) => _passportFilePath = path),
                            onClear: _passportFilePath == null
                                ? null
                                : () =>
                                      setState(() => _passportFilePath = null),
                          ),
                          _documentPicker(
                            label: 'Work Permit',
                            path: _workPermitFilePath,
                            onPick: () =>
                                _pickFile((path) => _workPermitFilePath = path),
                            onClear: _workPermitFilePath == null
                                ? null
                                : () => setState(
                                    () => _workPermitFilePath = null,
                                  ),
                          ),
                          _documentPicker(
                            label: 'Offer Letter',
                            path: _offerLetterFilePath,
                            onPick: () => _pickFile(
                              (path) => _offerLetterFilePath = path,
                            ),
                            onClear: _offerLetterFilePath == null
                                ? null
                                : () => setState(
                                    () => _offerLetterFilePath = null,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickAdditionalFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach Additional Documents'),
                      ),
                      if (_additionalDocumentPaths.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final path in _additionalDocumentPaths)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.description_outlined),
                            title: Text(
                              path.split(RegExp(r'[\\/]')).last,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              path,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(
                                () => _additionalDocumentPaths.remove(path),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton.icon(
                              onPressed: _saveEmployee,
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Create Profile'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? prefixText,
    FormFieldValidator<String>? validator,
  }) {
    return SizedBox(
      width: 280,
      child: CustomTextField(
        controller: controller,
        label: label,
        keyboardType: keyboardType,
        prefixText: prefixText,
        validator: validator,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return SizedBox(
      width: 280,
      child: OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.calendar_month_outlined),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value == null ? 'Select' : DateTimeHelper.formatDate(value),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              InkWell(onTap: onClear, child: const Icon(Icons.close, size: 18)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _documentPicker({
    required String label,
    required String? path,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    final filename = path == null
        ? 'Attach'
        : path.split(RegExp(r'[\\/]')).last;

    return SizedBox(
      width: 300,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(filename, overflow: TextOverflow.ellipsis, maxLines: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPick,
                      icon: const Icon(Icons.attach_file),
                      label: Text(path == null ? 'Attach' : 'Replace'),
                    ),
                  ),
                  if (onClear != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: onClear,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
