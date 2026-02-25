import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/expense.dart';

class ExpenseController extends GetxController {
  final box = GetStorage();

  final expenses = <Expense>[].obs;
  final totalSpent = 0.0.obs;
  final budget = 200000.0.obs;
  final filter = 'Todos'.obs;

  final categories = [
    'Comida',
    'Transporte',
    'Ocio',
    'Estudio',
    'Otros'
  ];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // ================= LOAD / SAVE =================

  void loadData() {
    final data = box.read('expenses');
    final savedBudget = box.read('budget');

    if (savedBudget != null) {
      budget.value = savedBudget;
    }

    if (data != null) {
      expenses.value =
          (data as List).map((e) => Expense.fromJson(e)).toList();
      calculateTotal();
    }
  }

  void saveData() {
    box.write(
        'expenses', expenses.map((e) => e.toJson()).toList());
    box.write('budget', budget.value);
  }

  // ================= CRUD =================

  void addExpense(
      String description, double amount, String category) {
    expenses.insert(
      0,
      Expense(
        description: description,
        amount: amount,
        category: category,
        date: DateTime.now(),
      ),
    );
    calculateTotal();
    saveData();
  }

  void removeExpense(int index) {
    expenses.removeAt(index);
    calculateTotal();
    saveData();
  }

  void updateBudget(double value) {
    budget.value = value;
    saveData();
  }

  // ================= CALCULOS =================

  void calculateTotal() {
    totalSpent.value =
        expenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get remaining => budget.value - totalSpent.value;

  // ================= FILTRO =================

  List<Expense> get filteredExpenses {
    if (filter.value == 'Hoy') {
      final today = DateTime.now();
      return expenses.where((e) =>
          e.date.day == today.day &&
          e.date.month == today.month &&
          e.date.year == today.year).toList();
    }

    if (filter.value == 'Mes') {
      final now = DateTime.now();
      return expenses.where((e) =>
          e.date.month == now.month &&
          e.date.year == now.year).toList();
    }

    return expenses;
  }
}