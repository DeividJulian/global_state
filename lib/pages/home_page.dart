import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/expense_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final controller = Get.put(ExpenseController());
  final descCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final currency =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$');

  String selectedCategory = 'Comida';

  // ================= DIALOG GASTO =================

  void _showExpenseDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text("Nuevo gasto"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: "Descripción"),
                ),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: "Monto"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: controller.categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedCategory = v!),
                  decoration:
                      const InputDecoration(labelText: "Categoría"),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final desc = descCtrl.text.trim();
              final amount =
                  double.tryParse(amountCtrl.text) ?? 0;

              if (desc.isNotEmpty && amount > 0) {
                controller.addExpense(
                    desc, amount, selectedCategory);
                descCtrl.clear();
                amountCtrl.clear();
                Get.back();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // ================= DIALOG PRESUPUESTO =================

  void _editBudget() {
    final budgetCtrl = TextEditingController(
        text: controller.budget.value.toStringAsFixed(0));

    Get.dialog(
      AlertDialog(
        title: const Text("Editar presupuesto"),
        content: TextField(
          controller: budgetCtrl,
          keyboardType: TextInputType.number,
          decoration:
              const InputDecoration(labelText: "Nuevo presupuesto"),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final value =
                  double.tryParse(budgetCtrl.text) ?? 0;
              if (value > 0) {
                controller.updateBudget(value);
                Get.back();
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text("Control de Gastos"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editBudget,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text("Agregar"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 RESUMEN
            Obx(() => _summaryCard()),

            const SizedBox(height: 16),

            // 🔥 FILTROS
            Obx(() => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'Todos', label: Text('Todos')),
                    ButtonSegment(
                        value: 'Hoy', label: Text('Hoy')),
                    ButtonSegment(
                        value: 'Mes', label: Text('Mes')),
                  ],
                  selected: {controller.filter.value},
                  onSelectionChanged: (s) =>
                      controller.filter.value = s.first,
                )),

            const SizedBox(height: 12),

            // 🔥 LISTA
            Expanded(
              child: Obx(() {
                final list = controller.filteredExpenses;

                if (list.isEmpty) {
                  return const Center(
                      child: Text("No hay gastos"));
                }

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, index) {
                    final e = list[index];

                    return Dismissible(
                      key: Key('${e.description}$index'),
                      background: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding:
                            const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white),
                      ),
                      onDismissed: (_) =>
                          controller.removeExpense(index),
                      child: Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: Text(
                              e.category[0],
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),
                          title: Text(e.description),
                          subtitle: Text(e.category),
                          trailing: Text(
                            currency.format(e.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blue],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _moneyRow("Presupuesto",
              currency.format(controller.budget.value)),
          _moneyRow(
              "Gastado", currency.format(controller.totalSpent.value)),
          const Divider(color: Colors.white70),
          _moneyRow(
            "Restante",
            currency.format(controller.remaining),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 20 : 16,
          ),
        ),
      ],
    );
  }
}