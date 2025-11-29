import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarScreen extends StatefulWidget {
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  DateTime selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> toDoLists = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTasks(); // Загружаем задачи при старте
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ВАЖНО: вызывается каждый раз, когда экран становится видимым
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTasks(); // ← Это решает проблему с необновлением календаря!
  }

  // Загрузка всех списков задач из SharedPreferences
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('toDoLists');

    if (data != null) {
      final Map<String, dynamic> decoded = jsonDecode(data);
      setState(() {
        toDoLists = decoded.map((key, value) {
          return MapEntry(
            key,
            List<Map<String, dynamic>>.from(
              (value as List).map((item) => Map<String, dynamic>.from(item)),
            ),
          );
        });
      });
    } else {
      setState(() => toDoLists = {});
    }
  }

  // Форматирует дату в строку YYYY-MM-DD (всегда с нулями)
  String _formatDateKey(int year, int month, int day) {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  int _firstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday; // 1 = понедельник, 7 = воскресенье
  }

  // Генерация ячеек календаря
  List<Widget> _buildCalendarDays() {
    List<Widget> dayWidgets = [];
    final year = selectedDate.year;
    final month = selectedDate.month;
    final today = DateTime.now();

    final int totalDays = _daysInMonth(year, month);
    final int firstWeekday = _firstWeekdayOfMonth(year, month);

    // Пустые ячейки до начала месяца
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Дни месяца
    for (int day = 1; day <= totalDays; day++) {
      final dateKey = _formatDateKey(year, month, day);
      final isToday =
          today.year == year && today.month == month && today.day == day;

      // Проверяем, есть ли задачи на этот день
      bool hasTasks = false;
      for (var tasks in toDoLists.values) {
        hasTasks = tasks.any((task) {
          if (task['date'] == null) return false;
          final taskDate = task['date'] as String;
          return taskDate.length >= 10 && taskDate.substring(0, 10) == dateKey;
        });
        if (hasTasks) break;
      }

      dayWidgets.add(
        GestureDetector(
          onTap: () => _showTasksForDay(dateKey, day),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isToday ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
              border:
                  hasTasks ? Border.all(color: Colors.red, width: 2.5) : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isToday ? Colors.white : Colors.black87,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return dayWidgets;
  }

  void _showTasksForDay(String dateKey, int day) {
    List<Map<String, dynamic>> tasksOnDay = [];

    toDoLists.forEach((listName, tasks) {
      for (var task in tasks) {
        if (task['date'] != null) {
          final taskDate = task['date'] as String;
          if (taskDate.length >= 10 && taskDate.substring(0, 10) == dateKey) {
            tasksOnDay.add({...task, 'listName': listName});
          }
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Задачи на $day ${getMonthName(selectedDate.month).toLowerCase()}'),
        content: tasksOnDay.isEmpty
            ? const Text('Нет задач')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasksOnDay.length,
                  itemBuilder: (ctx, i) {
                    final t = tasksOnDay[i];
                    return ListTile(
                      title: Text(t['task']),
                      subtitle: Text('Список: ${t['listName']}'),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  void _selectYear() {
    final controller =
        TextEditingController(text: selectedDate.year.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Введите год'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Например: 2025'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              final year = int.tryParse(controller.text);
              if (year != null && year > 1900 && year < 2100) {
                setState(() {
                  selectedDate = DateTime(year, selectedDate.month);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  String getMonthName(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month;

    return Scaffold(
      appBar: AppBar(
        title: Text('${getMonthName(selectedDate.month)} ${selectedDate.year}'),
        centerTitle: true,
        actions: [
          if (!isCurrentMonth)
            IconButton(icon: const Icon(Icons.today), onPressed: _goToToday),
          IconButton(
              icon: const Icon(Icons.date_range), onPressed: _selectYear),
        ],
      ),
      body: Column(
        children: [
          // Стрелки и название месяца
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _goToPreviousMonth),
                Text(
                  '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _goToNextMonth),
              ],
            ),
          ),

          // Дни недели
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
                .map((day) =>
                    Text(day, style: TextStyle(fontWeight: FontWeight.bold)))
                .toList(),
          ),
          const SizedBox(height: 10),

          // Сетка календаря
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              padding: const EdgeInsets.all(8),
              children: _buildCalendarDays(),
            ),
          ),
        ],
      ),
    );
  }
}
