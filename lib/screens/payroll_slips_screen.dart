import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payroll_model.dart';
import '../providers/payroll_provider.dart';
import '../utils/date_time_helper.dart';
import '../widgets/payroll_table.dart';
import 'pay_slip_preview_screen.dart';

class PayrollSlipsArgs {
  const PayrollSlipsArgs({this.statusFilter});

  final String? statusFilter;
}

class PayrollSlipsScreen extends StatefulWidget {
  const PayrollSlipsScreen({super.key});

  static const routeName = '/payroll-slips';

  @override
  State<PayrollSlipsScreen> createState() => _PayrollSlipsScreenState();
}

class _PayrollSlipsScreenState extends State<PayrollSlipsScreen> {
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
    if (args is PayrollSlipsArgs && args.statusFilter != null) {
      _statusFilter = args.statusFilter!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PayrollModel> _filteredPayrolls(List<PayrollModel> payrolls) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return payrolls.where((payroll) {
      final matchesSearch =
          query.isEmpty ||
          payroll.employeeName.toLowerCase().contains(query) ||
          payroll.employeeId.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == 'All' ||
          payroll.slipStatus.toLowerCase() == _statusFilter.toLowerCase();

      final created = payroll.createdAt;
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

  void _openPreview(PayrollModel payroll) {
    context.read<PayrollProvider>().preview(payroll);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaySlipPreviewScreen(payrollId: payroll.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payroll Slips')),
      body: Consumer<PayrollProvider>(
        builder: (context, provider, _) {
          final filtered = _filteredPayrolls(provider.payrolls);
          final total = filtered.fold<double>(
            0,
            (sum, payroll) => sum + payroll.finalPayableAmount,
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
                      width: 360,
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
                    Text('${filtered.length} slips'),
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
                    child: PayrollTable(
                      payrolls: filtered,
                      onPreview: _openPreview,
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
