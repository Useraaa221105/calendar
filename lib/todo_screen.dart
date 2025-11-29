import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MaterialApp(
    home: ToDoListsScreen(),
    theme: ThemeData(primarySwatch: Colors.blue),
  ));
}

// ЭКРАН 1: Список всех списков задач
class ToDoListsScreen extends StatefulWidget {
  @override
  _ToDoListsScreenState createState() => _ToDoListsScreenState();
}

class _ToDoListsScreenState extends State<ToDoListsScreen> {
  // Структура данных: Словарь, где ключ - имя списка, значение - список задач
  Map<String, List<Map<String, dynamic>>> toDoLists = {};
  TextEditingController listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLists(); // Загружаем данные при запуске
  }

  // Загрузка из памяти телефона
  Future<void> loadLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLists = prefs.getString('toDoLists');
    if (storedLists != null) {
      setState(() {
        // Декодируем JSON обратно в Map
        toDoLists = Map<String, List<Map<String, dynamic>>>.from(
          jsonDecode(storedLists).map(
            (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(
                value.map((task) => Map<String, dynamic>.from(task)),
              ),
            ),
          ),
        );
      });
    }
  }

  // Сохранение в память телефона
  Future<void> saveLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('toDoLists', jsonEncode(toDoLists));
  }

  // Добавление нового списка
  void addList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создать список'),
        content: TextField(
          controller: listNameController,
          decoration: InputDecoration(hintText: 'Название списка'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              String listName = listNameController.text.trim();
              if (listName.isNotEmpty && !toDoLists.containsKey(listName)) {
                setState(() {
                  toDoLists[listName] = [];
                });
                saveLists();
              }
              listNameController.clear();
              Navigator.pop(context);
            },
            child: Text('Создать'),
          ),
        ],
      ),
    );
  }

  // Переход к конкретному списку задач
  void openList(String listName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(
          listName: listName,
          tasks: toDoLists[listName]!,
          // Callback для обновления списка при возврате или изменении
          onUpdate: (updatedTasks) {
            setState(() {
              toDoLists[listName] = updatedTasks;
            });
            saveLists();
          },
          // Callback для удаления списка целиком
          onDelete: () {
            setState(() {
              toDoLists.remove(listName);
            });
            saveLists();
            Navigator.pop(context);
          },
          // Callback для переименования списка
          onRename: (newName) {
            setState(() {
              toDoLists[newName] = toDoLists.remove(listName)!;
            });
            saveLists();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Мои списки')),
      body: ListView(
        children: toDoLists.keys.map((listName) {
          return ListTile(
            title: Text(listName),
            trailing: Icon(Icons.chevron_right),
            onTap: () => openList(listName),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addList,
        child: Icon(Icons.add),
      ),
    );
  }
}

// ЭКРАН 2: Список задач внутри конкретного списка
class TaskListScreen extends StatefulWidget {
  final String listName;
  final List<Map<String, dynamic>> tasks;
  final ValueChanged<List<Map<String, dynamic>>> onUpdate;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  TaskListScreen({
    required this.listName,
    required this.tasks,
    required this.onUpdate,
    required this.onDelete,
    required this.onRename,
  });

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TextEditingController taskController = TextEditingController();
  TextEditingController renameController = TextEditingController();

  // --- ФУНКЦИЯ ДОБАВЛЕНИЯ ЗАДАЧИ (С ИСПРАВЛЕНИЕМ) ---
  void addTask() {
    // Локальная переменная для хранения выбранной даты, пока диалог открыт
    DateTime? selectedDate;

    showDialog(
      context: context,
      // ВАЖНО: Используем StatefulBuilder, чтобы обновлять интерфейс внутри диалога
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Добавить задачу'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: InputDecoration(hintText: 'Название задачи'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      // Обновляем переменную через setDialogState
                      // Это заставит перерисоваться ТОЛЬКО диалог
                      setDialogState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Выбрать дату выполнения'
                        : 'Дата: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  taskController.clear();
                  Navigator.pop(context);
                },
                child: Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  // Сохранение происходит здесь
                  String taskName = taskController.text.trim();
                  if (taskName.isNotEmpty) {
                    setState(() {
                      widget.tasks.add({
                        'task': taskName,
                        'date': selectedDate?.toIso8601String(),
                        'completed': false,
                      });
                    });
                    widget.onUpdate(widget.tasks);
                  }
                  taskController.clear();
                  Navigator.pop(context);
                },
                child: Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ФУНКЦИЯ РЕДАКТИРОВАНИЯ ЗАДАЧИ (С ИСПРАВЛЕНИЕМ) ---
  void manageTask(int index) {
    taskController.text = widget.tasks[index]['task'];

    // Инициализируем временную переменную текущей датой задачи
    DateTime? currentDate = widget.tasks[index]['date'] != null
        ? DateTime.parse(widget.tasks[index]['date'])
        : null;

    showDialog(
      context: context,
      // ВАЖНО: StatefulBuilder нужен, чтобы кнопка с датой обновлялась
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Редактировать задачу'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskController,
                  decoration: InputDecoration(
                    hintText: 'Название задачи',
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: currentDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      // setDialogState перерисовывает этот AlertDialog
                      setDialogState(() {
                        currentDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    currentDate != null
                        ? 'Дата: ${DateFormat('dd.MM.yyyy').format(currentDate!)}'
                        : 'Выбрать дату',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  // При нажатии "Сохранить" обновляем данные в главном виджете
                  String updatedTask = taskController.text.trim();
                  if (updatedTask.isNotEmpty) {
                    setState(() {
                      widget.tasks[index]['task'] = updatedTask;
                      // Сохраняем дату из временной переменной в реальные данные
                      widget.tasks[index]['date'] =
                          currentDate?.toIso8601String();
                    });
                    widget.onUpdate(widget.tasks);
                  }
                  taskController.clear();
                  Navigator.pop(context);
                },
                child: Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void deleteTask(int index) {
    setState(() {
      widget.tasks.removeAt(index);
    });
    widget.onUpdate(widget.tasks);
  }

  // Меню действий со списком (переименовать/удалить)
  void openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Переименовать список'),
            onTap: () {
              Navigator.pop(context);
              renameList();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Удалить список'),
            onTap: () {
              Navigator.pop(context);
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }

  void renameList() {
    renameController.text = widget.listName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переименовать список'),
        content: TextField(
          controller: renameController,
          decoration: InputDecoration(hintText: 'Новое название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              String newName = renameController.text.trim();
              if (newName.isNotEmpty && newName != widget.listName) {
                widget.onRename(newName);
                Navigator.pop(context);
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: openMenu,
          ),
        ],
      ),
      body: widget.tasks.isEmpty
          ? Center(child: Text("Задач пока нет"))
          : ListView.builder(
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    widget.tasks[index]['task'],
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: widget.tasks[index]['date'] != null
                      ? Text(
                          'Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(widget.tasks[index]['date']))}')
                      : Text('Без даты'),
                  onTap: () => manageTask(index), // Редактирование по нажатию
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTask(index),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        child: Icon(Icons.add),
      ),
    );
  }
}
