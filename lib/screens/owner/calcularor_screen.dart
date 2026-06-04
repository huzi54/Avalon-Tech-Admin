// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'package:intl/intl.dart';

// import '../../app_config.dart';
// import '../../models/employee_model.dart';
// import '../../providers/employee_provider.dart';
// import '../../providers/payroll_provider.dart';

// class SalaryCalculatorScreen extends StatefulWidget {
//   static const routeName = '/salary-calculator';
//   @override
//   _SalaryCalculatorScreenState createState() => _SalaryCalculatorScreenState();
// }

// class _SalaryCalculatorScreenState extends State<SalaryCalculatorScreen> {
//   EmployeeModel? selectedEmployee;
//   String payFrequency = 'Biweekly';
//   int numberOfPeriods = 26;

//   final hoursController = TextEditingController();
//   final otherTaxableController = TextEditingController();
//   final otherNonTaxableController = TextEditingController();

//   DateTime payPeriodStart = DateTime.now();
//   DateTime payPeriodEnd = DateTime.now();
//   DateTime payDate = DateTime.now();

//   double grossPay = 0, federalTax = 0, provincialTax = 0, cpp = 0, ei = 0, netPay = 0;

//   @override
//   Widget build(BuildContext context) {
//     final employeeProvider = Provider.of<EmployeeProvider>(context);
//     final payrollProvider = Provider.of<PayrollProvider>(context);

//     return Scaffold(
//       appBar: AppBar(title: Text("Salary Calculator NL 2026")),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Employee selection dropdown
//             DropdownButton<EmployeeModel>(
//               value: selectedEmployee,
//               hint: Text("Select Employee"),
//               items: employeeProvider.employees.map((emp) {
//                 return DropdownMenuItem(
//                   value: emp,
//                   child: Text(emp.name),
//                 );
//               }).toList(),
//               onChanged: (emp) {
//                 setState(() {
//                   selectedEmployee = emp;
//                   if (emp != null) {
//                     hoursController.text = emp.hourlyRate.toString(); // Optional default
//                   }
//                 });
//               },
//             ),
//             SizedBox(height: 10),

//             // Pay Period and Pay Date
//             Row(
//               children: [
//                 Expanded(
//                   child: ListTile(
//                     title: Text("Pay Period Start"),
//                     subtitle: Text(DateFormat('yyyy-MM-dd').format(payPeriodStart)),
//                     onTap: () async {
//                       final date = await showDatePicker(
//                         context: context,
//                         initialDate: payPeriodStart,
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (date != null) setState(() => payPeriodStart = date);
//                     },
//                   ),
//                 ),
//                 Expanded(
//                   child: ListTile(
//                     title: Text("Pay Period End"),
//                     subtitle: Text(DateFormat('yyyy-MM-dd').format(payPeriodEnd)),
//                     onTap: () async {
//                       final date = await showDatePicker(
//                         context: context,
//                         initialDate: payPeriodEnd,
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (date != null) setState(() => payPeriodEnd = date);
//                     },
//                   ),
//                 ),
//                 Expanded(
//                   child: ListTile(
//                     title: Text("Pay Date"),
//                     subtitle: Text(DateFormat('yyyy-MM-dd').format(payDate)),
//                     onTap: () async {
//                       final date = await showDatePicker(
//                         context: context,
//                         initialDate: payDate,
//                         firstDate: DateTime(2000),
//                         lastDate: DateTime(2100),
//                       );
//                       if (date != null) setState(() => payDate = date);
//                     },
//                   ),
//                 ),
//               ],
//             ),

//             // Pay Frequency Dropdown
//             DropdownButton<String>(
//               value: payFrequency,
//               items: ['Biweekly','Weekly','Monthly'].map((freq){
//                 return DropdownMenuItem(
//                   value: freq,
//                   child: Text(freq),
//                 );
//               }).toList(),
//               onChanged: (val){
//                 setState(() {
//                   payFrequency = val!;
//                   numberOfPeriods = val=='Biweekly'?26:(val=='Weekly'?52:12);
//                 });
//               },
//             ),
//             Text("Number of Pay Periods: $numberOfPeriods"),

//             // Hours Input
//             TextField(controller: hoursController, decoration: InputDecoration(labelText: "Total Hours / Rate"), keyboardType: TextInputType.number),
//             TextField(controller: otherTaxableController, decoration: InputDecoration(labelText: "Other Taxable Income / Overtime"), keyboardType: TextInputType.number),
//             TextField(controller: otherNonTaxableController, decoration: InputDecoration(labelText: "Other Non-Taxable Deduction"), keyboardType: TextInputType.number),

//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 if(selectedEmployee == null) return;

//                 // Gross Pay
//                 final hours = double.tryParse(hoursController.text) ?? 0;
//                 final rate = selectedEmployee!.hourlyRate;
//                 final otherTaxable = double.tryParse(otherTaxableController.text) ?? 0;
//                 final otherNonTaxable = double.tryParse(otherNonTaxableController.text) ?? 0;

//                 grossPay = hours * rate + otherTaxable;

//                 // NL 2026 Federal Tax simplified example
//                 federalTax = grossPay * 0.15; // first $55k, more accurate can use brackets
//                 provincialTax = grossPay * 0.087; // NL first bracket

//                 cpp = (grossPay * AppConfig.cppRate).clamp(0, AppConfig.cppMax);
//                 ei = (grossPay * AppConfig.eiRate).clamp(0, AppConfig.eiMax);

//                 netPay = grossPay - (federalTax + provincialTax + cpp + ei + otherNonTaxable);

//                 // Save payroll
//                 final payroll = PayrollModel(
//                   id: DateTime.now().millisecondsSinceEpoch.toString(),
//                   employeeId: selectedEmployee!.id,
//                   employeeName: selectedEmployee!.name,
//                   hours: hours,
//                   rate: rate,
//                   grossPay: grossPay,
//                   federalTax: federalTax,
//                   provincialTax: provincialTax,
//                   cpp: cpp,
//                   ei: ei,
//                   totalDeductions: federalTax + provincialTax + cpp + ei + otherNonTaxable,
//                   netPay: netPay,
//                   payPeriodStart: payPeriodStart,
//                   payPeriodEnd: payPeriodEnd,
//                   createdAt: DateTime.now(),
//                 );

//                 Provider.of<PayrollProvider>(context, listen:false).addPayroll(payroll);

//                 // Show result
//                 showDialog(context: context, builder: (_){
//                   return AlertDialog(
//                     title: Text("Payroll Calculated"),
//                     content: Text("Net Pay: \$${netPay.toStringAsFixed(2)}"),
//                     actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text("OK"))],
//                   );
//                 });

//               },
//               child: Text("Calculate Payroll"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
