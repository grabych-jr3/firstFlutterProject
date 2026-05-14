import 'dart:math';

import 'package:flutter/material.dart';
import 'package:v_h/models/task.dart';
import 'package:v_h/services/TaskLocalDatabase.dart';
import 'package:v_h/services/TaskSyncService.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Hive.openBox("tasks");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'KrakFlow',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Potwierdzenie"),
                    content: const Text(
                      "Czy na pewno chcesz usunąć wszystkie zadania?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await TaskLocalDatabase.deleteAllTasks();

                          setState(() {
                            tasksFuture = loadTasks();
                          });

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Usunięto wszystkie zadania"),
                            ),
                          );
                        },
                        child: const Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Task>>(
        future: tasksFuture,

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Błąd: ${snapshot.error}"),
            );
          }

          final tasks = snapshot.data ?? [];

          int count = tasks.where((task) => task.done).length;

          List<Task> filteredTasks;

          if (selectedFilter == "wykonane") {
            filteredTasks =
                tasks.where((task) => task.done).toList();
          } else if (selectedFilter == "do zrobienia") {
            filteredTasks =
                tasks.where((task) => !task.done).toList();
          } else {
            filteredTasks = tasks;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Masz dziś ${filteredTasks.length} zadania",
                      style: const TextStyle(fontSize: 16),
                    ),

                    Text(
                      "Wykonano: $count zadania",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Dzisiejsze zadania",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = "wszystkie";
                            });
                          },

                          child: Text(
                            "Wszystkie",
                            style: TextStyle(
                              color: selectedFilter == "wszystkie"
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = "do zrobienia";
                            });
                          },

                          child: Text(
                            "Do zrobienia",
                            style: TextStyle(
                              color: selectedFilter == "do zrobienia"
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = "wykonane";
                            });
                          },

                          child: Text(
                            "Wykonane",
                            style: TextStyle(
                              color: selectedFilter == "wykonane"
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredTasks.length,

                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];

                    return Dismissible(
                      key: ValueKey(task.id),

                      direction: DismissDirection.endToStart,

                      onDismissed: (direction) async {

                        await TaskLocalDatabase.deleteTask(
                          task.id,
                        );

                        setState(() {
                          tasksFuture = loadTasks();
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Usunięto zadanie: ${task.title}",
                            ),
                          ),
                        );
                      },

                      child: TaskCard(
                        title: task.title,

                        subtitle:
                        "termin: ${task.deadline}, priorytet: ${task.priority}",

                        done: task.done,

                        onChanged: (value) async {

                          final updatedTask = Task(
                            id: task.id,
                            title: task.title,
                            deadline: task.deadline,
                            priority: task.priority,
                            done: value ?? false,
                          );

                          await TaskLocalDatabase.updateTask(
                            updatedTask,
                          );

                          setState(() {
                            tasksFuture = loadTasks();
                          });
                        },

                        onTap: () async {
                          final Task? updatedTask =
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditTaskScreen(task: task),
                            ),
                          );

                          if (updatedTask != null) {

                            await TaskLocalDatabase.updateTask(
                              updatedTask,
                            );

                            setState(() {
                              tasksFuture = loadTasks();
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,

            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                  AddTaskScreen(),

              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {

                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );

          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);

            setState(() {
              tasksFuture = loadTasks();
            });
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      child: ListTile(
        onTap: onTap,

        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),

        title: Text(
          title,

          style: TextStyle(
            decoration:
            done
                ? TextDecoration.lineThrough
                : TextDecoration.none,

            color:
            done
                ? Colors.grey
                : Colors.black,
          ),
        ),

        subtitle: Text(
          subtitle,

          style: TextStyle(
            color:
            done
                ? Colors.grey
                : Colors.black,
          ),
        ),

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController deadlineController =
  TextEditingController();

  final TextEditingController priorityController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nowe zadanie"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: titleController,

              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: deadlineController,

              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priorityController,

              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  final newTask = Task(
                    id: Random().nextInt(1000000),
                    title: titleController.text,
                    deadline: deadlineController.text,
                    priority: priorityController.text,
                    done: false,
                  );

                  Navigator.pop(context, newTask);
                },

                child: const Text("Zapisz"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  const EditTaskScreen({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {

    final TextEditingController titleController =
    TextEditingController(text: task.title);

    final TextEditingController deadlineController =
    TextEditingController(text: task.deadline);

    final TextEditingController priorityController =
    TextEditingController(text: task.priority);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edycja zadania"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [

            TextField(
              controller: titleController,

              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: deadlineController,

              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priorityController,

              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {

                  final updatedTask = Task(
                    id: task.id,
                    title: titleController.text,
                    deadline: deadlineController.text,
                    done: task.done,
                    priority: priorityController.text,
                  );

                  Navigator.pop(context, updatedTask);
                },

                child: const Text("Zapisz zmiany"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}