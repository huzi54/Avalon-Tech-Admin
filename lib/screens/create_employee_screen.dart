import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/employee_model.dart';
import '../providers/employee_provider.dart';
import '../services/firebase_service.dart';
import '../utils/app_input_formatters.dart';
import '../utils/date_time_helper.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({this.onBack, this.onSaved, super.key});

  static const routeName = '/create-employee';

  final VoidCallback? onBack;
  final ValueChanged<String>? onSaved;

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _socialSecurityController = TextEditingController();
  final _roleController = TextEditingController(text: 'Employee');
  final _departmentController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _hoursController = TextEditingController(text: '80');

  DateTime? _joiningDate;
  DateTime? _endDate;
  String? _legalStatus;
  String _employmentType = 'Full-time';
  String? _passportFilePath;
  String? _workPermitFilePath;
  String? _offerLetterFilePath;
  bool _isSaving = false;

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
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _socialSecurityController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    _hourlyRateController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  String _nextEmployeeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'EMP-${timestamp.toString().substring(8)}';
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final employeeId = _idController.text.trim();
    final firebaseService = context.read<FirebaseService>();
    final employeeProvider = context.read<EmployeeProvider>();
    try {
      final passportUrl = await _uploadDocument(
        firebaseService,
        employeeId: employeeId,
        path: _passportFilePath,
        type: 'passport',
      );
      final workPermitUrl = await _uploadDocument(
        firebaseService,
        employeeId: employeeId,
        path: _workPermitFilePath,
        type: 'work_permit',
      );
      final offerLetterUrl = await _uploadDocument(
        firebaseService,
        employeeId: employeeId,
        path: _offerLetterFilePath,
        type: 'offer_letter',
      );

      final employee = EmployeeModel(
        id: employeeId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _roleController.text.trim().isEmpty
            ? 'Employee'
            : _roleController.text.trim(),
        hourlyRate: double.parse(_hourlyRateController.text.trim()),
        employmentType: _employmentType,
        defaultHours: double.parse(_hoursController.text.trim()),
        phone: _emptyToNull(_phoneController.text),
        department: _emptyToNull(_departmentController.text),
        socialSecurityNumber: _emptyToNull(_socialSecurityController.text),
        emergencyContactName: _emptyToNull(_emergencyContactController.text),
        joiningDate: _joiningDate,
        endDate: _endDate,
        legalStatus: _legalStatus,
        passportFilePath: passportUrl,
        workPermitFilePath: workPermitUrl,
        offerLetterFilePath: offerLetterUrl,
      );

      await employeeProvider.addEmployee(employee);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${employee.name} employee profile created')),
      );
      final onSaved = widget.onSaved;
      if (onSaved != null) {
        onSaved(employee.id);
        return;
      }
      context.pop(employee.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _uploadDocument(
    FirebaseService firebaseService, {
    required String employeeId,
    required String? path,
    required String type,
  }) {
    if (path == null || path.startsWith('http')) return Future.value(path);
    return firebaseService.uploadEmployeeDocument(
      employeeId: employeeId,
      localPath: path,
      documentType: type,
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _requiredEmail(String? value) {
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
    if (parsed == null || parsed <= 0) return 'Enter a number greater than 0';
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
    if (picked != null) setState(() => onChanged(picked));
  }

  Future<void> _pickFile(ValueChanged<String?> onPicked) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: false,
    );
    setState(() => onPicked(result?.files.single.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _Header(onBack: widget.onBack ?? () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 940),
                    child: Column(
                      children: [
                        _SectionCard(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFF2563EB),
                          title: 'Profile Information',
                          subtitle: 'Basic details about the employee.',
                          children: [
                            _InputField(
                              controller: _nameController,
                              label: 'Employee Name',
                              hint: 'Enter full name',
                              icon: Icons.person_outline,
                              inputFormatters: [
                                AppInputFormatters.textOnly,
                                AppInputFormatters.capitalizeFirst,
                              ],
                              textCapitalization: TextCapitalization.words,
                              required: true,
                              validator: _requiredText,
                            ),
                            const SizedBox(height: 18),
                            _InputField(
                              controller: _idController,
                              label: 'Employee ID',
                              hint: 'Employee ID',
                              icon: Icons.badge_outlined,
                              required: true,
                              validator: _requiredText,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF2563EB),
                          title: 'Contact Information',
                          subtitle: 'Contact details for communication.',
                          children: [
                            _InputField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'Enter email address',
                              icon: Icons.mail_outline,
                              keyboardType: TextInputType.emailAddress,
                              required: true,
                              validator: _requiredEmail,
                            ),
                            const SizedBox(height: 18),
                            _InputField(
                              controller: _phoneController,
                              label: 'Phone',
                              hint: 'Enter phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [AppInputFormatters.phone],
                              required: true,
                              validator: _requiredText,
                            ),
                            const SizedBox(height: 18),
                            _InputField(
                              controller: _emergencyContactController,
                              label: 'Emergency Contact',
                              hint: 'Enter emergency contact name and number',
                              icon: Icons.person_outline,
                              inputFormatters: [
                                AppInputFormatters.sentenceText,
                                AppInputFormatters.capitalizeFirst,
                              ],
                              textCapitalization: TextCapitalization.sentences,
                              helper:
                                  'Provide name and relationship with phone number. (e.g. John Doe - 709-123-4567)',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xFF16A34A),
                          title: 'Identity / Legal',
                          subtitle: 'Identity documents and legal information.',
                          children: [
                            _InputField(
                              controller: _socialSecurityController,
                              label: 'Social Security / SIN',
                              hint: 'Enter SIN number',
                              icon: Icons.badge_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [AppInputFormatters.digitsOnly],
                              required: true,
                              validator: _requiredText,
                            ),
                            const SizedBox(height: 18),
                            _DropdownField(
                              label: 'Legal Status',
                              hint: 'Select legal status',
                              icon: Icons.balance_outlined,
                              value: _legalStatus,
                              required: true,
                              items: _legalStatuses,
                              onChanged: (value) {
                                setState(() => _legalStatus = value);
                              },
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 22),
                            _DocumentDropField(
                              label: 'Work Permit (if applicable)',
                              path: _workPermitFilePath,
                              onBrowse: () => _pickFile(
                                (path) => _workPermitFilePath = path,
                              ),
                              onClear: _workPermitFilePath == null
                                  ? null
                                  : () => setState(
                                      () => _workPermitFilePath = null,
                                    ),
                            ),
                            const SizedBox(height: 18),
                            _DocumentDropField(
                              label: 'Passport (if applicable)',
                              path: _passportFilePath,
                              onBrowse: () =>
                                  _pickFile((path) => _passportFilePath = path),
                              onClear: _passportFilePath == null
                                  ? null
                                  : () => setState(
                                      () => _passportFilePath = null,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionCard(
                          icon: Icons.business_center_outlined,
                          iconColor: const Color(0xFF9333EA),
                          title: 'Employment',
                          subtitle:
                              'Employment dates, payroll setup and related documents.',
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final twoColumns = constraints.maxWidth >= 680;
                                final gap = twoColumns ? 18.0 : 0.0;
                                final width = twoColumns
                                    ? (constraints.maxWidth - gap) / 2
                                    : constraints.maxWidth;

                                return Wrap(
                                  spacing: gap,
                                  runSpacing: 18,
                                  children: [
                                    SizedBox(
                                      width: width,
                                      child: _DateField(
                                        label: 'Joining Date',
                                        value: _joiningDate,
                                        required: true,
                                        onTap: () => _pickDate(
                                          current: _joiningDate,
                                          onChanged: (value) =>
                                              _joiningDate = value,
                                        ),
                                        validator: (_) => _joiningDate == null
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _DateField(
                                        label: 'End Date (if applicable)',
                                        value: _endDate,
                                        onTap: () => _pickDate(
                                          current: _endDate,
                                          onChanged: (value) =>
                                              _endDate = value,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _DropdownField(
                                        label: 'Employment Type',
                                        hint: 'Select employment type',
                                        icon: Icons.badge_outlined,
                                        value: _employmentType,
                                        required: true,
                                        items: _employmentTypes,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _employmentType = value,
                                          );
                                        },
                                        validator: (value) =>
                                            value == null ? 'Required' : null,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _InputField(
                                        controller: _roleController,
                                        label: 'Designation / Role',
                                        hint: 'Enter designation',
                                        icon: Icons.work_outline,
                                        inputFormatters: [
                                          AppInputFormatters.textOnly,
                                          AppInputFormatters.capitalizeFirst,
                                        ],
                                        textCapitalization:
                                            TextCapitalization.words,
                                        required: true,
                                        validator: _requiredText,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _InputField(
                                        controller: _departmentController,
                                        label: 'Department',
                                        hint: 'Enter department',
                                        icon: Icons.apartment_outlined,
                                        inputFormatters: [
                                          AppInputFormatters.textOnly,
                                          AppInputFormatters.capitalizeFirst,
                                        ],
                                        textCapitalization:
                                            TextCapitalization.words,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _InputField(
                                        controller: _hourlyRateController,
                                        label: 'Hourly Rate',
                                        hint: 'Enter hourly rate',
                                        icon: Icons.attach_money_rounded,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          AppInputFormatters.number,
                                        ],
                                        required: true,
                                        validator: _positiveNumber,
                                      ),
                                    ),
                                    SizedBox(
                                      width: width,
                                      child: _InputField(
                                        controller: _hoursController,
                                        label: 'Default Working Hours',
                                        hint: 'Enter default hours',
                                        icon: Icons.schedule_outlined,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          AppInputFormatters.number,
                                        ],
                                        required: true,
                                        validator: _positiveNumber,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            _DocumentDropField(
                              label: 'Offer Letter (if applicable)',
                              path: _offerLetterFilePath,
                              onBrowse: () => _pickFile(
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
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 48,
                              width: 112,
                              child: OutlinedButton(
                                onPressed: () => context.pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              height: 48,
                              width: 152,
                              child: FilledButton(
                                onPressed: _isSaving ? null : _saveEmployee,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save Employee'),
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
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Employee',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a new employee to your organization.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Back to Employees'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9E2EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.required = false,
    this.validator,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final bool required;
  final FormFieldValidator<String>? validator;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 21),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 8),
          Text(
            helper!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
    this.validator,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool required;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 21),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
    this.validator,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool required;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, required: required),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          validator: validator,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: value == null
                ? 'Select ${label.toLowerCase()}'
                : DateTimeHelper.formatDate(value!),
            prefixIcon: const Icon(Icons.calendar_month_outlined, size: 21),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          ),
        ),
      ],
    );
  }
}

class _DocumentDropField extends StatelessWidget {
  const _DocumentDropField({
    required this.label,
    required this.path,
    required this.onBrowse,
    this.onClear,
  });

  final String label;
  final String? path;
  final VoidCallback onBrowse;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final fileName = path?.split(RegExp(r'[\\/]')).last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFCBD5E1),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD9E2EF)),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF64748B),
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      fileName == null
                          ? 'PDF, JPG, PNG (compressed and stored in Firebase, max 550KB)'
                          : path!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: onBrowse,
                child: Text(fileName == null ? 'Browse' : 'Replace'),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove file',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
        ],
      ),
    );
  }
}
