import 'TaskApiService.dart';
import 'TaskLocalDatabase.dart';

class TaskSyncService {

  static Future<void> loadInitialDataIfNeeded() async {

    if (!TaskLocalDatabase.isEmpty()) {
      return;
    }

    final tasks =
    await TaskApiService.fetchTasks();

    await TaskLocalDatabase.saveTasks(tasks);
  }
}