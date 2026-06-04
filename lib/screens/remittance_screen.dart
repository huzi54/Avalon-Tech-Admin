import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/remittance_model.dart';
import '../providers/payroll_provider.dart';
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

  String _statusFilter = 'All';
  String _dateFilter = 'All';
  bool _handledArgs = false;

  static const _statusOptions = ['All', 'Paid', 'Unpaid'];
  static const _dateOptions = [
    'All',
    'Today',
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
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

  List<RemittanceModel> _filtered(List<RemittanceModel> remittances) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return remittances.where((remittance) {
      final matchesSearch =
          query.isEmpty ||
          remittance.employeeName.toLowerCase().contains(query) ||
          remittance.employeeId.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == 'All' ||
          remittance.status.toLowerCase() == _statusFilter.toLowerCase();

      final created = remittance.createdAt;
      final matchesDate = switch (_dateFilter) {
        'Today' =>
          created.year == now.year &&
              created.month == now.month &&
              created.day == now.day,
        'Last 7 Days' => created.isAfter(now.subtract(const Duration(days: 7))),
        'Last 30 Days' => created.isAfter(
          now.subtract(const Duration(days: 30)),
        ),
        'This Month' => created.year == now.year && created.month == now.month,
        _ => true,
      };

      return matchesSearch && matchesStatus && matchesDate;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remittance')),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, _) {
          final filtered = _filtered(provider.remittances);
          final total = filtered.fold<double>(
            0,
            (sum, remittance) => sum + remittance.totalRemittance,
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
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        initialValue: _dateFilter,
                        decoration: const InputDecoration(labelText: 'Date'),
                        items: [
                          for (final option in _dateOptions)
                            DropdownMenuItem(
                              value: option,
                              child: Text(option),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _dateFilter = value);
                        },
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _statusFilter = 'All';
                          _dateFilter = 'All';
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text('${filtered.length} remittances'),
                    const SizedBox(width: 16),
                    Text('Total: ${DateTimeHelper.currency(total)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _RemittanceTable(remittances: filtered),
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

class _RemittanceTable extends StatelessWidget {
  const _RemittanceTable({required this.remittances});

  final List<RemittanceModel> remittances;

  @override
  Widget build(BuildContext context) {
    if (remittances.isEmpty) {
      return const Center(child: Text('No remittance records found.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
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
          DataColumn(label: Text('Status')),
        ],
        rows: [
          for (final remittance in remittances)
            DataRow(
              cells: [
                DataCell(
                  Text('${remittance.employeeName} (${remittance.employeeId})'),
                ),
                DataCell(Text(remittance.payFrequency)),
                DataCell(
                  Text(
                    '${DateTimeHelper.formatDate(remittance.payPeriodStart)} - '
                    '${DateTimeHelper.formatDate(remittance.payPeriodEnd)}',
                  ),
                ),
                DataCell(Text(DateTimeHelper.currency(remittance.grossPay))),
                DataCell(
                  Text(DateTimeHelper.currency(remittance.employeeIncomeTax)),
                ),
                DataCell(Text(DateTimeHelper.currency(remittance.employeeCpp))),
                DataCell(Text(DateTimeHelper.currency(remittance.employerCpp))),
                DataCell(Text(DateTimeHelper.currency(remittance.employeeEi))),
                DataCell(Text(DateTimeHelper.currency(remittance.employerEi))),
                DataCell(Text(DateTimeHelper.currency(remittance.netPay))),
                DataCell(
                  Text(DateTimeHelper.currency(remittance.totalRemittance)),
                ),
                DataCell(
                  SizedBox(
                    width: 130,
                    child: DropdownButton<String>(
                      value: remittance.status,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'Unpaid',
                          child: Text('Unpaid'),
                        ),
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        context.read<PayrollProvider>().updateRemittanceStatus(
                          remittanceId: remittance.id,
                          status: value,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
