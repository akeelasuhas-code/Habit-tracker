import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HabitListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Habit {
  String name;
  bool isDoneToday;

  Habit({required this.name, this.isDoneToday = false});

  Map<String, dynamic> toMap() => {
        'name': name,
        'isDoneToday': isDoneToday,
      };

  factory Habit.fromMap(Map<String, dynamic> map) =>
      Habit(name: map['name'], isDoneToday: map['isDoneToday']);
}

class HabitListPage extends StatefulWidget {
  const HabitListPage({super.key});

  @override
  State<HabitListPage> createState() => _HabitListPageState();
}

class _HabitListPageState extends State<HabitListPage> {
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();
    loadHabits();
  }

  Future<void> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString('habits');
    if (storedData != null) {
      final List decoded = jsonDecode(storedData);
      setState(() {
        habits = decoded.map((e) => Habit.fromMap(e)).toList();
      });
    }
  }

  Future<void> saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(habits.map((e) => e.toMap()).toList());
    await prefs.setString('habits', encoded);
  }

  void addHabit(String name) {
    setState(() {
      habits.add(Habit(name: name));
    });
    saveHabits();
  }

  void toggleHabit(int index) {
    setState(() {
      habits[index].isDoneToday = !habits[index].isDoneToday;
    });
    saveHabits();
  }

  void deleteHabit(int index) {
    setState(() {
      habits.removeAt(index);
    });
    saveHabits();
  }

  void showAddDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Habit'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter habit name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                addHabit(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void resetHabitsForToday() {
    setState(() {
      for (var h in habits) {
        h.isDoneToday = false;
      }
    });
    saveHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset for Today',
            onPressed: resetHabitsForToday,
          ),
        ],
      ),
      body: habits.isEmpty
          ? const Center(
              child: Text(
                'No habits yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      habit.name,
                      style: TextStyle(
                        decoration: habit.isDoneToday
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            habit.isDoneToday
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: habit.isDoneToday
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onPressed: () => toggleHabit(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => deleteHabit(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
