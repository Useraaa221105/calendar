import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// ЭКРАН 1: ВСЕ СПИСКИ ЗАДАЧ (ГЛАВНЫЙ ЭКРАН To-Do)

class ToDoListsScreen extends StatefulWidget {
  const ToDoListsScreen({super.key});

  @override
  _ToDoListsScreenState createState() => _ToDoListsScreenState();
}

class _ToDoListsScreenState extends State<ToDoListsScreen> {
  // СТРУКТУРА ДАННЫХ:

  // Ключ: Название списка (String)
  // Значение: Список задач в этом списке (List<Map>)
  Map<String, List<Map<String, dynamic>>> toDoLists = {};

  // Контроллер для поля ввода названия нового списка
  TextEditingController listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLists(); // Загружаем все списки при запуске экрана
  }

  // ФУНКЦИЯ: ЗАГРУЗИТЬ СПИСКИ ИЗ ПАМЯТИ ТЕЛЕФОНА

  Future<void> loadLists() async {
    // 1. Получаем доступ к SharedPreferences (локальное хранилище)
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 2. Читаем данные по ключу 'toDoLists'
    String? storedLists = prefs.getString('toDoLists');

    // 3. Если данные есть - преобразуем их из JSON
    if (storedLists != null) {
      setState(() {
        toDoLists = Map<String, List<Map<String, dynamic>>>.from(
          jsonDecode(storedLists).map(
            (key, value) => MapEntry(
              key, // Название списка (например: "Работа")
              // Список задач этого списка
              List<Map<String, dynamic>>.from(
                value.map((task) => Map<String, dynamic>.from(task)),
              ),
            ),
          ),
        );
      });
    }
  }

  // ФУНКЦИЯ: СОХРАНИТЬ СПИСКИ В ПАМЯТЬ ТЕЛЕФОНА

  Future<void> saveLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Преобразуем Map → JSON → Сохраняем по ключу 'toDoLists'
    await prefs.setString('toDoLists', jsonEncode(toDoLists));
  }

  // КНОПКА: СОЗДАТЬ НОВЫЙ СПИСОК ЗАДАЧ

  void addList() {
    // Показываем диалоговое окно для ввода названия списка
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать список'),
        content: TextField(
          controller: listNameController, // Поле для ввода
          decoration: const InputDecoration(hintText: 'Название списка'),
        ),
        actions: [
          // КНОПКА "ОТМЕНА" - закрывает диалог
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          // КНОПКА "СОЗДАТЬ" - создает новый список
          TextButton(
            onPressed: () {
              String listName = listNameController.text.trim();

              // Проверяем: название не пустое и такого списка еще нет
              if (listName.isNotEmpty && !toDoLists.containsKey(listName)) {
                setState(() {
                  toDoLists[listName] = []; // Создаем пустой список задач
                });
                saveLists(); // Сохраняем изменения
              }

              listNameController.clear(); // Очищаем поле ввода
              Navigator.pop(context); // Закрываем диалог
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  // ФУНКЦИЯ: ОТКРЫТЬ КОНКРЕТНЫЙ СПИСОК ЗАДАЧ

  void openList(String listName) {
    // Переходим на экран с задачами этого списка
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(
          listName: listName, // Название списка
          tasks: toDoLists[listName]!, // Задачи этого списка

          // CALLBACK 1: ОБНОВИТЬ ЗАДАЧИ

          // Вызывается когда задачи в списке меняются
          onUpdate: (updatedTasks) {
            setState(() {
              toDoLists[listName] = updatedTasks; // Обновляем задачи
            });
            saveLists(); // Сохраняем изменения
          },

          // CALLBACK 2: УДАЛИТЬ ВЕСЬ СПИСОК

          // Вызывается когда список удаляется целиком
          onDelete: () {
            setState(() {
              toDoLists.remove(listName); // Удаляем список
            });
            saveLists(); // Сохраняем
            Navigator.pop(context); // Возвращаемся назад
          },

          // CALLBACK 3: ПЕРЕИМЕНОВАТЬ СПИСОК

          // Вызывается когда меняется название списка
          onRename: (newName) {
            setState(() {
              // Меняем ключ в Map: старый → новый
              toDoLists[newName] = toDoLists.remove(listName)!;
            });
            saveLists(); // Сохраняем
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ВЕРХНЯЯ ПАНЕЛЬ (APP BAR)

      appBar: AppBar(
        title: const Text('Мои списки'),
      ),

      // ОСНОВНОЕ СОДЕРЖИМОЕ: СПИСОК ВСЕХ СПИСКОВ

      body: ListView(
        children: toDoLists.keys.map((listName) {
          // КАРТОЧКА ОДНОГО СПИСКА:
          return ListTile(
            title: Text(listName), // Название списка
            trailing: const Icon(Icons.chevron_right), // Стрелка "вперед"
            onTap: () => openList(listName), // Открыть этот список
          );
        }).toList(),
      ),

      // КНОПКА "+" В ПРАВОМ НИЖНЕМ УГЛУ ЭКРАНА

      floatingActionButton: FloatingActionButton(
        onPressed: addList, // Открывает диалог создания нового списка
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ЭКРАН 2: ЗАДАЧИ В КОНКРЕТНОМ СПИСКЕ

class TaskListScreen extends StatefulWidget {
  final String listName; // Название текущего списка
  final List<Map<String, dynamic>> tasks; // Все задачи этого списка

  // ТРИ ВАЖНЫЕ ФУНКЦИИ ДЛЯ СВЯЗИ С РОДИТЕЛЬСКИМ ЭКРАНОМ:
  final ValueChanged<List<Map<String, dynamic>>> onUpdate; // Обновить задачи
  final VoidCallback onDelete; // Удалить список
  final ValueChanged<String> onRename; // Переименовать список

  const TaskListScreen({
    super.key,
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
  // Контроллеры для полей ввода:
  TextEditingController taskController = TextEditingController(); // Для задач
  TextEditingController renameController =
      TextEditingController(); // Для переименования

  // КНОПКА: ДОБАВИТЬ НОВУЮ ЗАДАЧУ

  void addTask() {
    // Временная переменная для хранения выбранной даты
    DateTime? selectedDate;

    // Диалоговое окно добавления задачи
    showDialog(
      context: context,
      // StatefulBuilder позволяет обновлять диалог изнутри
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Добавить задачу'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ПОЛЕ ВВОДА: название задачи
                TextField(
                  controller: taskController,
                  decoration:
                      const InputDecoration(hintText: 'Название задачи'),
                ),
                const SizedBox(height: 10),

                // КНОПКА "ВЫБРАТЬ ДАТУ ВЫПОЛНЕНИЯ"
                ElevatedButton(
                  onPressed: () async {
                    // Открываем стандартный выборщик даты Flutter
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(), // Начинаем с сегодня
                      firstDate: DateTime(2000), // Минимальная дата
                      lastDate: DateTime(2101), // Максимальная дата
                    );
                    if (pickedDate != null) {
                      // Обновляем только этот диалог
                      setDialogState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    // Меняем текст кнопки в зависимости от выбора
                    selectedDate == null
                        ? 'Выбрать дату выполнения'
                        : 'Дата: ${DateFormat('dd.MM.yyyy').format(selectedDate!)}',
                  ),
                ),
              ],
            ),
            actions: [
              // КНОПКА "ОТМЕНА"
              TextButton(
                onPressed: () {
                  taskController.clear(); // Очищаем поле
                  Navigator.pop(context); // Закрываем диалог
                },
                child: const Text('Отмена'),
              ),

              // КНОПКА "ДОБАВИТЬ"
              TextButton(
                onPressed: () {
                  String taskName = taskController.text.trim();
                  if (taskName.isNotEmpty) {
                    setState(() {
                      // ДОБАВЛЯЕМ НОВУЮ ЗАДАЧУ В СПИСОК:
                      widget.tasks.add({
                        'task': taskName, // Название задачи
                        'date': selectedDate
                            ?.toIso8601String(), // Дата в ISO формате
                        'completed': false, // Статус: не выполнена
                      });
                    });
                    // Сообщаем родительскому экрану об изменениях
                    widget.onUpdate(widget.tasks);
                  }
                  taskController.clear(); // Очищаем поле
                  Navigator.pop(context); // Закрываем диалог
                },
                child: const Text('Добавить'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ФУНКЦИЯ: РЕДАКТИРОВАТЬ ЗАДАЧУ

  void manageTask(int index) {
    // Заполняем поле текущим названием задачи
    taskController.text = widget.tasks[index]['task'];

    // Получаем текущую дату задачи (если есть)
    DateTime? currentDate = widget.tasks[index]['date'] != null
        ? DateTime.parse(widget.tasks[index]['date'])
        : null;

    // Диалоговое окно редактирования
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Редактировать задачу'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ПОЛЕ ВВОДА: новое название задачи
                TextField(
                  controller: taskController,
                  decoration: const InputDecoration(
                    hintText: 'Название задачи',
                  ),
                ),
                const SizedBox(height: 10),

                // КНОПКА "ВЫБРАТЬ/ИЗМЕНИТЬ ДАТУ"
                ElevatedButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: currentDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        currentDate = pickedDate; // Обновляем дату
                      });
                    }
                  },
                  child: Text(
                    // Показываем текущую дату или приглашение к выбору
                    currentDate != null
                        ? 'Дата: ${DateFormat('dd.MM.yyyy').format(currentDate!)}'
                        : 'Выбрать дату',
                  ),
                ),
              ],
            ),
            actions: [
              // КНОПКА "ОТМЕНА"
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),

              // КНОПКА "СОХРАНИТЬ"
              TextButton(
                onPressed: () {
                  String updatedTask = taskController.text.trim();
                  if (updatedTask.isNotEmpty) {
                    setState(() {
                      // ОБНОВЛЯЕМ ЗАДАЧУ:
                      widget.tasks[index]['task'] =
                          updatedTask; // Новое название
                      widget.tasks[index]['date'] =
                          currentDate?.toIso8601String(); // Новая дата
                    });
                    // Сообщаем об изменениях
                    widget.onUpdate(widget.tasks);
                  }
                  taskController.clear(); // Очищаем поле
                  Navigator.pop(context); // Закрываем диалог
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  // КНОПКА: УДАЛИТЬ ЗАДАЧУ

  void deleteTask(int index) {
    setState(() {
      widget.tasks.removeAt(index); // Удаляем задачу по индексу
    });
    widget.onUpdate(widget.tasks); // Сохраняем изменения
  }

  // КНОПКА "⋮" МЕНЮ ДЕЙСТВИЙ СО СПИСКОМ
  void openMenu() {
    // Показываем меню снизу экрана (Bottom Sheet)
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // КНОПКА "ПЕРЕИМЕНОВАТЬ СПИСОК"
          ListTile(
            leading: const Icon(Icons.edit), // Иконка карандаша
            title: const Text('Переименовать список'),
            onTap: () {
              Navigator.pop(context); // Закрываем меню
              renameList(); // Открываем диалог переименования
            },
          ),
          // КНОПКА "УДАЛИТЬ СПИСОК"
          ListTile(
            leading: const Icon(Icons.delete), // Иконка корзины
            title: const Text('Удалить список'),
            onTap: () {
              Navigator.pop(context); // Закрываем меню
              widget.onDelete(); // Удаляем весь список
            },
          ),
        ],
      ),
    );
  }

  // ФУНКЦИЯ: ПЕРЕИМЕНОВАТЬ СПИСОК
  void renameList() {
    renameController.text = widget.listName; // Заполняем текущим названием
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать список'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(hintText: 'Новое название'),
        ),
        actions: [
          // КНОПКА "ОТМЕНА"
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          // КНОПКА "СОХРАНИТЬ"
          TextButton(
            onPressed: () {
              String newName = renameController.text.trim();
              // Проверяем: новое название не пустое и отличается от старого
              if (newName.isNotEmpty && newName != widget.listName) {
                widget.onRename(newName); // Переименовываем список
                Navigator.pop(context); // Закрываем диалог
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ВЕРХНЯЯ ПАНЕЛЬ С НАЗВАНИЕМ СПИСКА
      appBar: AppBar(
        title: Text(widget.listName), // Название текущего списка
        actions: [
          // КНОПКА "⋮" (три точки) в правом верхнем углу
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: openMenu, // Открывает меню действий со списком
          ),
        ],
      ),

      // СПИСОК ВСЕХ ЗАДАЧ ЭТОГО СПИСКА
      // ============================================
      body: widget.tasks.isEmpty
          ? const Center(child: Text("Задач пока нет")) // Если задач нет
          : ListView.builder(
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                return ListTile(
                  // НАЗВАНИЕ ЗАДАЧИ (жирным шрифтом)
                  title: Text(
                    widget.tasks[index]['task'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // ДАТА ВЫПОЛНЕНИЯ (если есть)
                  subtitle: widget.tasks[index]['date'] != null
                      ? Text(
                          'Дата: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(widget.tasks[index]['date']))}')
                      : const Text('Без даты'),

                  // НАЖАТИЕ НА ЗАДАЧУ → РЕДАКТИРОВАНИЕ
                  onTap: () => manageTask(index),

                  // КНОПКА "УДАЛИТЬ" справа от задачи
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteTask(index),
                  ),
                );
              },
            ),

      // КНОПКА "+" ДЛЯ ДОБАВЛЕНИЯ НОВОЙ ЗАДАЧИ

      floatingActionButton: FloatingActionButton(
        onPressed: addTask, // Открывает диалог добавления задачи
        child: const Icon(Icons.add),
      ),
    );
  }
}
