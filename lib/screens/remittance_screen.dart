import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/remittance_model.dart';
import '../providers/payroll_provider.dart';
import '../services/pdf_service.dart';
import '../utils/date_time_helper.dart';

class RemittanceArgs {
  const RemittanceArgs({this.statusFilter});

  final String? statusFilter;
}

class RemittanceScreen extends StatefulWidget {
  const RemittanceScreen({super.key});

  static const routeName = '/remittances';

  @override
  State<RemittanceScreen> createState() => _RemittanceScreenState();
}

class _RemittanceScreenState extends State<RemittanceScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedIds = {};

  String _statusFilter = 'All';
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _handledArgs = false;

  static const _statusOptions = ['All', 'Paid', 'Unpaid'];
  static const _paidViaOptions = [
    'Cash',
    'Check',
    'Direct Deposit',
    'E-Transfer',
    'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledArgs) return;
    _handledArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is RemittanceArgs && args.statusFilter != null) {
      _statusFilter = args.statusFilter!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RemittanceModel> _filtered(List<RemittanceModel> records) {
    final query = _searchController.text.trim().toLowerCase();
    final from = _dateOnly(_fromDate);
    final to = _dateOnly(_toDate);

    return records.where((record) {
      final created = _dateOnly(record.createdAt)!;
      final searchMatches =
          query.isEmpty ||
          record.employeeName.toLowerCase().contains(query) ||
          record.employeeId.toLowerCase().contains(query);
      final statusMatches =
          _statusFilter == 'All' ||
          record.status.toLowerCase() == _statusFilter.toLowerCase();
      final dateMatches =
          (from == null || !created.isBefore(from)) &&
          (to == null || !created.isAfter(to));
      return searchMatches && statusMatches && dateMatches;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  DateTime? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final current = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
      } else {
        _toDate = picked;
        if (_fromDate != null && _fromDate!.isAfter(picked)) {
          _fromDate = picked;
        }
      }
    });
  }

  Future<void> _print(List<RemittanceModel> records) async {
    if (records.isEmpty) return;
    await const PdfService().printRemittanceList(records);
  }

  Future<void> _export(List<RemittanceModel> records) async {
    if (records.isEmpty) return;
    final csv = _buildCsv(records);
    final path = await FilePicker.saveFile(
      dialogTitle: 'Export remittance records',
      fileName:
          'remittance-export-${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: utf8.encode(csv),
    );
    if (path == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${records.length} remittances exported')),
    );
  }

  String _buildCsv(List<RemittanceModel> records) {
    final rows = <List<String>>[
      [
        'Employee Name',
        'Employee ID',
        'Created Date',
        'Pay Frequency',
        'Pay Period Start',
        'Pay Period End',
        'Gross Pay',
        'Employee Income Tax',
        'Employee CPP',
        'Employer CPP',
        'Employee EI',
        'Employer EI',
        'Net Pay',
        'Total Remittance',
        'Status',
        'Paid Via',
        'Notes',
      ],
      for (final record in records)
        [
          record.employeeName,
          record.employeeId,
          DateTimeHelper.formatDate(record.createdAt),
          record.payFrequency,
          DateTimeHelper.formatDate(record.payPeriodStart),
          DateTimeHelper.formatDate(record.payPeriodEnd),
          record.grossPay.toStringAsFixed(2),
          record.employeeIncomeTax.toStringAsFixed(2),
          record.employeeCpp.toStringAsFixed(2),
          record.employerCpp.toStringAsFixed(2),
          record.employeeEi.toStringAsFixed(2),
          record.employerEi.toStringAsFixed(2),
          record.netPay.toStringAsFixed(2),
          record.totalRemittance.toStringAsFixed(2),
          record.status,
          record.paidVia ?? '',
          record.notes ?? '',
        ],
    ];
    return rows
        .map((row) => row.map(_csvCell).join(','))
        .join(Platform.lineTerminator);
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remittance')),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, _) {
          final filtered = _filtered(provider.remittances);
          final selected = filtered
              .where((record) => _selectedIds.contains(record.id))
              .toList();
          final totalRecords = selected.isEmpty ? filtered : selected;
          final total = totalRecords.fold<double>(
            0,
            (sum, record) => sum + record.totalRemittance,
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 380,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search by employee name or ID',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: [
                          for (final option in _statusOptions)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                      ),
                    ),
                    _DateFilterButton(
                      label: 'From Date',
                      value: _fromDate,
                      onPressed: () => _pickDate(isFrom: true),
                    ),
                    _DateFilterButton(
                      label: 'To Date',
                      value: _toDate,
                      onPressed: () => _pickDate(isFrom: false),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _statusFilter = 'All';
                          _fromDate = null;
                          _toDate = null;
                          _selectedIds.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                    FilledButton.icon(
                      onPressed: selected.isEmpty
                          ? null
                          : () => _export(selected),
                      icon: const Icon(Icons.table_view_outlined),
                      label: Text(
                        selected.isEmpty
                            ? 'Export to Excel'
                            : 'Export to Excel (${selected.length})',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: selected.isEmpty
                          ? null
                          : () => _print(selected),
                      icon: const Icon(Icons.print_outlined),
                      label: Text(
                        selected.isEmpty
                            ? 'Print Selected'
                            : 'Print Selected (${selected.length})',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        selected.isEmpty
                            ? '${filtered.length} remittances'
                            : '${selected.length} selected',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        'TOTAL: ${DateTimeHelper.currency(total)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _RemittanceTable(
                      records: filtered,
                      selectedIds: _selectedIds,
                      paidViaOptions: _paidViaOptions,
                      hasSelection: selected.isNotEmpty,
                      onPrint: (record) => _print([record]),
                      onSelectionChanged: (id, isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.add(id);
                          } else {
                            _selectedIds.remove(id);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.date_range_outlined),
        label: Text(
          value == null ? label : DateTimeHelper.formatDate(value!),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RemittanceTable extends StatefulWidget {
  const _RemittanceTable({
    required this.records,
    required this.selectedIds,
    required this.paidViaOptions,
    required this.hasSelection,
    required this.onPrint,
    required this.onSelectionChanged,
  });

  final List<RemittanceModel> records;
  final Set<String> selectedIds;
  final List<String> paidViaOptions;
  final bool hasSelection;
  final ValueChanged<RemittanceModel> onPrint;
  final void Function(String id, bool selected) onSelectionChanged;

  @override
  State<_RemittanceTable> createState() => _RemittanceTableState();
}

class _RemittanceTableState extends State<_RemittanceTable> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return const Center(child: Text('No remittance records found.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          thickness: 10,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 2300,
              height: constraints.maxHeight,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                trackVisibility: true,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  padding: const EdgeInsets.only(bottom: 18, right: 12),
                  child: DataTable(
                    columnSpacing: 28,
                    horizontalMargin: 16,
                    showCheckboxColumn: true,
                    columns: const [
                      DataColumn(label: Text('Action')),
                      DataColumn(label: Text('Remittance Status')),
                      DataColumn(label: Text('Paid Via')),
                      DataColumn(label: Text('Employee')),
                      DataColumn(label: Text('Pay Frequency')),
                      DataColumn(label: Text('Period')),
                      DataColumn(label: Text('Gross Pay')),
                      DataColumn(label: Text('Income Tax')),
                      DataColumn(label: Text('Employee CPP')),
                      DataColumn(label: Text('Employer CPP')),
                      DataColumn(label: Text('Employee EI')),
                      DataColumn(label: Text('Employer EI')),
                      DataColumn(label: Text('Net Pay')),
                      DataColumn(label: Text('Total Remittance')),
                      DataColumn(label: Text('Notes')),
                    ],
                    rows: [
                      for (final record in widget.records)
                        DataRow(
                          selected: widget.selectedIds.contains(record.id),
                          onSelectChanged: (selected) => widget
                              .onSelectionChanged(record.id, selected ?? false),
                          cells: [
                            DataCell(
                              widget.hasSelection
                                  ? const Text('-')
                                  : OutlinedButton.icon(
                                      onPressed: () => widget.onPrint(record),
                                      icon: const Icon(
                                        Icons.print_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Print'),
                                    ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 140,
                                child: DropdownButton<String>(
                                  value: record.status,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Unpaid',
                                      child: Text('Unpaid'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Paid',
                                      child: Text('Paid'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    context
                                        .read<PayrollProvider>()
                                        .updateRemittancePayment(
                                          remittanceId: record.id,
                                          status: value,
                                          paidVia: value == 'Paid'
                                              ? record.paidVia ??
                                                    widget.paidViaOptions.first
                                              : null,
                                        );
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: DropdownButton<String>(
                                  value:
                                      widget.paidViaOptions.contains(
                                        record.paidVia,
                                      )
                                      ? record.paidVia
                                      : widget.paidViaOptions.first,
                                  isExpanded: true,
                                  items: [
                                    for (final option in widget.paidViaOptions)
                                      DropdownMenuItem(
                                        value: option,
                                        child: Text(option),
                                      ),
                                  ],
                                  onChanged: record.status == 'Paid'
                                      ? (value) {
                                          if (value == null) return;
                                          context
                                              .read<PayrollProvider>()
                                              .updateRemittancePayment(
                                                remittanceId: record.id,
                                                status: 'Paid',
                                                paidVia: value,
                                              );
                                        }
                                      : null,
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 210,
                                child: Text(
                                  '${record.employeeName}\n(${record.employeeId})',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(record.payFrequency)),
                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  '${DateTimeHelper.formatDate(record.payPeriodStart)} - '
                                  '${DateTimeHelper.formatDate(record.payPeriodEnd)}',
                                ),
                              ),
                            ),
                            DataCell(
                              Text(DateTimeHelper.currency(record.grossPay)),
                            ),
                            DataCell(
                              Text(
                                DateTimeHelper.currency(
                                  record.employeeIncomeTax,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(DateTimeHelper.currency(record.employeeCpp)),
                            ),
                            DataCell(
                              Text(DateTimeHelper.currency(record.employerCpp)),
                            ),
                            DataCell(
                              Text(DateTimeHelper.currency(record.employeeEi)),
                            ),
                            DataCell(
                              Text(DateTimeHelper.currency(record.employerEi)),
                            ),
                            DataCell(
                              Text(DateTimeHelper.currency(record.netPay)),
                            ),
                            DataCell(
                              Text(
                                DateTimeHelper.currency(record.totalRemittance),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 250,
                                child: _NotesField(record: record),
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
        );
      },
    );
  }
}

class _NotesField extends StatefulWidget {
  const _NotesField({required this.record});

  final RemittanceModel record;

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  String _savedValue = '';

  @override
  void initState() {
    super.initState();
    _savedValue = widget.record.notes ?? '';
    _controller = TextEditingController(text: _savedValue);
  }

  @override
  void didUpdateWidget(covariant _NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.id != widget.record.id) {
      _savedValue = widget.record.notes ?? '';
      _controller.text = _savedValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _queueSave(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), () => _save(value));
  }

  Future<void> _save(String value) async {
    if (!mounted || value.trim() == _savedValue.trim()) return;
    _savedValue = value;
    await context.read<PayrollProvider>().updateRemittanceNotes(
      remittanceId: widget.record.id,
      notes: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: 1,
      maxLines: 2,
      decoration: const InputDecoration(hintText: 'Add notes', isDense: true),
      onChanged: _queueSave,
      onSubmitted: _save,
      onTapOutside: (_) {
        _debounce?.cancel();
        _save(_controller.text);
        FocusScope.of(context).unfocus();
      },
    );
  }
}
