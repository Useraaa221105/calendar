import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ==============================
// ЭКРАН: КАЛЕНДАРЬ С ЗАДАЧАМИ
// ==============================
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  // ТЕКУЩАЯ ДАТА (для отображения месяца и года)
  DateTime selectedDate = DateTime.now();

  // ВСЕ ЗАДАЧИ ИЗ ВСЕХ СПИСКОВ:
  // Ключ: название списка, Значение: список задач
  Map<String, List<Map<String, dynamic>>> toDoLists = {};

  @override
  void initState() {
    super.initState();
    // Добавляем наблюдателя за состоянием приложения
    WidgetsBinding.instance.addObserver(this);
    _loadTasks(); // Загружаем задачи при первом открытии
  }

  @override
  void dispose() {
    // Убираем наблюдателя при закрытии экрана
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Загружка задачи ПРИ КАЖДОМ ПОКАЗЕ ЭКРАНА
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTasks(); // Это решает проблему необновления календаря!
  }

  // ФУНКЦИЯ: ЗАГРУЗКА ЗАДАЧ ИЗ ПАМЯТИ ТЕЛЕФОНА
  Future<void> _loadTasks() async {
    // Получаем доступ к хранилищу
    final prefs = await SharedPreferences.getInstance();
    // Читаем данные по ключу 'toDoLists' (там хранятся все списки)
    final String? data = prefs.getString('toDoLists');

    if (data != null) {
      // ПРЕОБРАЗОВАНИЕ JSON → MAP:
      // 1. Декодируем JSON строку
      final Map<String, dynamic> decoded = jsonDecode(data);

      // 2. Обновляем состояние с новыми данными
      setState(() {
        toDoLists = decoded.map((key, value) {
          // Для каждого списка преобразуем задачи
          return MapEntry(
            key, // Название списка
            List<Map<String, dynamic>>.from(
              (value as List).map((item) => Map<String, dynamic>.from(item)),
            ),
          );
        });
      });
    } else {
      // Если данных нет - создаем пустой словарь
      setState(() => toDoLists = {});
    }
  }

  // ФУНКЦИЯ: ФОРМАТИРОВАНИЕ ДАТЫ В КЛЮЧ
  // Преобразует год, месяц, день в строку формата "YYYY-MM-DD"
  String _formatDateKey(int year, int month, int day) {
    // padLeft добавляет нули: 3 → "03", 12 → "12"
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  // ФУНКЦИЯ: СКОЛЬКО ДНЕЙ В МЕСЯЦЕ

  int _daysInMonth(int year, int month) {
    // Хитрость: 0 день следующего месяца = последний день текущего
    return DateTime(year, month + 1, 0).day;
  }

  // ФУНКЦИЯ: ПЕРВЫЙ ДЕНЬ НЕДЕЛИ МЕСЯЦА

  // Возвращает: 1 = понедельник, 7 = воскресенье
  int _firstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday;
  }

  // ==============================
  // ФУНКЦИЯ: СОЗДАНИЕ ЯЧЕЕК КАЛЕНДАРЯ
  // ==============================
  List<Widget> _buildCalendarDays() {
    List<Widget> dayWidgets = []; // Список виджетов дней
    final year = selectedDate.year;
    final month = selectedDate.month;
    final today = DateTime.now(); // Сегодняшняя дата

    // Вычисляем:
    final int totalDays = _daysInMonth(year, month); // Сколько дней в месяце
    final int firstWeekday =
        _firstWeekdayOfMonth(year, month); // С какого дня недели начинается

    // ШАГ 1: ПУСТЫЕ ЯЧЕЙКИ ДО НАЧАЛА МЕСЯЦА

    // Например, если месяц начинается со среды (3),
    // то нужно 2 пустых ячейки для понедельника и вторника
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox()); // Пустой виджет
    }

    // ШАГ 2: ЯЧЕЙКИ ДЛЯ КАЖДОГО ДНЯ МЕСЯЦА

    for (int day = 1; day <= totalDays; day++) {
      // Создаем ключ для поиска задач: "2024-03-20"
      final dateKey = _formatDateKey(year, month, day);

      // Проверяем: это сегодняшний день?
      final isToday =
          today.year == year && today.month == month && today.day == day;

      // ПРОВЕРКА: ЕСТЬ ЛИ ЗАДАЧИ НА ЭТОТ ДЕНЬ?

      bool hasTasks = false;

      // Перебираем ВСЕ списки задач
      for (var tasks in toDoLists.values) {
        // Ищем хотя бы одну задачу с этой датой
        hasTasks = tasks.any((task) {
          if (task['date'] == null) return false; // Если у задачи нет даты

          final taskDate = task['date'] as String; // Дата задачи в формате ISO
          // Сравниваем первые 10 символов (YYYY-MM-DD)
          return taskDate.length >= 10 && taskDate.substring(0, 10) == dateKey;
        });

        if (hasTasks) break; // Нашли задачу - дальше не ищем
      }

      // СОЗДАЕМ ВИДЖЕТ ЯЧЕЙКИ ДНЯ

      dayWidgets.add(
        // КНОПКА: НАЖАТИЕ НА ДЕНЬ
        GestureDetector(
          onTap: () => _showTasksForDay(dateKey, day), // Показываем задачи
          child: Container(
            margin: const EdgeInsets.all(4), // Отступы вокруг
            decoration: BoxDecoration(
              // Цвет фона: сегодня - синий, остальные - серый
              color: isToday ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(10), // Закругленные углы
              // КРАСНАЯ РАМКА если есть задачи на этот день!
              border:
                  hasTasks ? Border.all(color: Colors.red, width: 2.5) : null,
            ),
            child: Center(
              child: Text(
                '$day', // Число дня
                style: TextStyle(
                  // Цвет текста: сегодня - белый, остальные - черный
                  color: isToday ? Colors.white : Colors.black87,
                  // Сегодняшний день - жирный шрифт
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return dayWidgets; // Возвращаем список ячеек
  }

  // ФУНКЦИЯ: ПОКАЗ ЗАДАЧ НА ВЫБРАННЫЙ ДЕНЬ

  void _showTasksForDay(String dateKey, int day) {
    List<Map<String, dynamic>> tasksOnDay = []; // Задачи на этот день

    // ПЕРЕБИРАЕМ ВСЕ СПИСКИ И ВСЕ ЗАДАЧИ:
    toDoLists.forEach((listName, tasks) {
      for (var task in tasks) {
        if (task['date'] != null) {
          final taskDate = task['date'] as String;
          // Если дата задачи совпадает с выбранным днем
          if (taskDate.length >= 10 && taskDate.substring(0, 10) == dateKey) {
            // Добавляем задачу + имя её списка
            tasksOnDay.add({...task, 'listName': listName});
          }
        }
      }
    });

    // ДИАЛОГОВОЕ ОКНО С ЗАДАЧАМИ

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // Заголовок: "Задачи на 20 марта"
        title: Text(
            'Задачи на $day ${getMonthName(selectedDate.month).toLowerCase()}'),

        // Содержимое диалога:
        content: tasksOnDay.isEmpty
            ? const Text('Нет задач') // Если задач нет
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true, // Список занимает только нужную высоту
                  itemCount: tasksOnDay.length,
                  itemBuilder: (ctx, i) {
                    final t = tasksOnDay[i];
                    return ListTile(
                      title: Text(t['task']), // Название задачи
                      subtitle:
                          Text('Список: ${t['listName']}'), // Из какого списка
                    );
                  },
                ),
              ),

        // КНОПКИ В ДИАЛОГЕ:
        actions: [
          // КНОПКА "ЗАКРЫТЬ"
          TextButton(
            onPressed: () => Navigator.pop(context), // Закрывает диалог
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // КНОПКА: ПРЕДЫДУЩИЙ МЕСЯЦ

  void _goToPreviousMonth() {
    setState(() {
      // Уменьшаем месяц на 1
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  // КНОПКА: СЛЕДУЮЩИЙ МЕСЯЦ

  void _goToNextMonth() {
    setState(() {
      // Увеличиваем месяц на 1
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  // КНОПКА: ВЕРНУТЬСЯ К СЕГОДНЯШНЕМУ ДНЮ

  void _goToToday() {
    setState(() {
      selectedDate = DateTime.now(); // Устанавливаем текущую дату
    });
  }

  // КНОПКА: ВЫБРАТЬ ГОД

  void _selectYear() {
    // Поле ввода с текущим годом
    final controller =
        TextEditingController(text: selectedDate.year.toString());

    // ДИАЛОГ ДЛЯ ВВОДА ГОДА
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Введите год'),
        content: TextField(
          controller: controller, // Поле для ввода
          keyboardType: TextInputType.number, // Цифровая клавиатура
          decoration: const InputDecoration(hintText: 'Например: 2025'),
        ),
        actions: [
          // КНОПКА "ОТМЕНА"
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),

          // КНОПКА "ОК" - сохраняет выбранный год
          TextButton(
            onPressed: () {
              final year = int.tryParse(
                  controller.text); // Пытаемся преобразовать в число
              // Проверяем что год в разумных пределах
              if (year != null && year > 1900 && year < 2100) {
                setState(() {
                  // Меняем год, но оставляем текущий месяц
                  selectedDate = DateTime(year, selectedDate.month);
                });
              }
              Navigator.pop(context); // Закрываем диалог
            },
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  // ФУНКЦИЯ: ПОЛУЧИТЬ НАЗВАНИЕ МЕСЯЦА

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
    return months[month - 1]; // month = 1..12, индексы = 0..11
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем: показываем ли мы текущий месяц?
    final isCurrentMonth = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month;

    return Scaffold(
      // ВЕРХНЯЯ ПАНЕЛЬ (APP BAR)

      appBar: AppBar(
        title: Text('${getMonthName(selectedDate.month)} ${selectedDate.year}'),
        centerTitle: true, // Заголовок по центру

        // КНОПКИ СПРАВА В APP BAR:
        actions: [
          // КНОПКА "СЕГОДНЯ" - показываем только если НЕ текущий месяц
          if (!isCurrentMonth)
            IconButton(
              icon: const Icon(Icons.today), // Иконка календаря с галочкой
              onPressed: _goToToday, // Возвращает к текущему месяцу
            ),

          // КНОПКА "ВЫБРАТЬ ГОД" - всегда доступна
          IconButton(
            icon: const Icon(Icons.date_range), // Иконка календаря
            onPressed: _selectYear, // Открывает диалог выбора года
          ),
        ],
      ),

      // ОСНОВНОЕ СОДЕРЖИМОЕ ЭКРАНА

      body: Column(
        children: [
          // СТРОКА: УПРАВЛЕНИЕ МЕСЯЦАМИ

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // КНОПКА "НАЗАД" (предыдущий месяц)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _goToPreviousMonth,
                ),

                // НАЗВАНИЕ ТЕКУЩЕГО МЕСЯЦА И ГОДА
                Text(
                  '${getMonthName(selectedDate.month)} ${selectedDate.year}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                // КНОПКА "ВПЕРЕД" (следующий месяц)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
          ),

          // СТРОКА: ДНИ НЕДЕЛИ

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'ВС']
                .map((day) => Text(day,
                    style: const TextStyle(fontWeight: FontWeight.bold)))
                .toList(),
          ),
          const SizedBox(height: 10), // Небольшой отступ

          // СЕТКА КАЛЕНДАРЯ (7x6 ячеек)

          Expanded(
            child: GridView.count(
              crossAxisCount: 7, // 7 колонок = 7 дней недели
              padding: const EdgeInsets.all(8),
              children: _buildCalendarDays(), // Все ячейки дней
            ),
          ),
        ],
      ),
    );
  }
}
