import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../models/payroll_model.dart';
import '../providers/payroll_slips_screen_provider.dart';
import '../providers/payroll_provider.dart';
import '../utils/date_time_helper.dart';
import '../utils/record_date_sort.dart';
import '../widgets/payroll_table.dart';

class PayrollSlipsArgs {
  const PayrollSlipsArgs({this.statusFilter});

  final String? statusFilter;
}

class PayrollSlipsScreen extends StatefulWidget {
  const PayrollSlipsScreen({this.onOpenPreview, this.onCreateSlip, super.key});

  static const routeName = '/payroll-slips';

  final ValueChanged<PayrollModel>? onOpenPreview;
  final VoidCallback? onCreateSlip;

  @override
  State<PayrollSlipsScreen> createState() => _PayrollSlipsScreenState();
}

class _PayrollSlipsScreenState extends State<PayrollSlipsScreen> {
  final _searchController = TextEditingController();
  final _screenProvider = PayrollSlipsScreenProvider();
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
      _screenProvider.applyInitialStatus(args.statusFilter);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _screenProvider.dispose();
    super.dispose();
  }

  void _openPreview(PayrollModel payroll) {
    context.read<PayrollProvider>().preview(payroll);
    final onOpenPreview = widget.onOpenPreview;
    if (onOpenPreview != null) {
      onOpenPreview(payroll);
      return;
    }
    context.push(AppRoutes.paySlipPreview(payroll.id));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PayrollSlipsScreenProvider>.value(
      value: _screenProvider,
      child: Scaffold(
        appBar: AppBar(title: const Text('Payroll Slips')),
        body: Consumer2<PayrollProvider, PayrollSlipsScreenProvider>(
          builder: (context, provider, screenProvider, _) {
            final filtered = screenProvider.filtered(provider.payrolls);
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
                      FilledButton.icon(
                        onPressed:
                            widget.onCreateSlip ??
                            () => context.push(AppRoutes.salaryCalculator),
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Slip'),
                      ),
                      SizedBox(
                        width: 360,
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by employee name or ID',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: screenProvider.updateQuery,
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          initialValue: screenProvider.statusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: [
                            for (final option in _statusOptions)
                              DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            screenProvider.updateStatus(value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<String>(
                          initialValue: screenProvider.dateFilter,
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
                            screenProvider.updateDateFilter(value);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<RecordDateSort>(
                          key: ValueKey(screenProvider.dateSort),
                          initialValue: screenProvider.dateSort,
                          decoration: const InputDecoration(
                            labelText: 'Date Order',
                            prefixIcon: Icon(Icons.sort),
                          ),
                          items: [
                            for (final option in RecordDateSort.values)
                              DropdownMenuItem(
                                value: option,
                                child: Text(option.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            screenProvider.updateDateSort(value);
                          },
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          screenProvider.clearFilters();
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
      ),
    );
  }
}
