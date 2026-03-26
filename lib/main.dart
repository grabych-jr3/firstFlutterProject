import 'package:flutter/material.dart';

void main(){
  runApp(MyApp());
}


class MyApp extends StatelessWidget{
  MyApp({super.key});

  final List<Task> tasks = [
    Task(title: "Kolokwium", deadline: "poniedziałek", done: false, priority: "wysoki"),
    Task(title: "Zakupy", deadline: "dzisiaj", done: true, priority: "średni"),
    Task(title: "Siłownia", deadline: "jutro", done: false, priority: "średni"),
    Task(title: "Piwko", deadline: "weekend", done: false, priority: "średni"),
  ];

  @override
  Widget build(BuildContext context) {
    int count = tasks.where((task) => task.done).length;
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Masz dziś ${tasks.length} zadania",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Wykonano: $count zadania",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Dzisiejsze zadania",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];

                  return TaskCard(
                    title: task.title,
                    subtitle: "termin: ${task.deadline}, priorytet: ${task.priority}",
                    icon: task.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}