import 'package:flutter/material.dart';
import 'todo_screen.dart';
import 'calendar_screen.dart';

// ТОЧКА ВХОДА В ПРИЛОЖЕНИЕ
void main() {
  // Запускаем приложение с главным виджетом MainApp
  runApp(const MainApp());
}

// ГЛАВНЫЙ ВИДЖЕТ ПРИЛОЖЕНИЯ
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Убираем  полоску DEBUG
      home: const MainScreen(), // Первый экран при запуске
      title: 'Calendar', // Название приложения (для системного меню)
      theme: ThemeData(primarySwatch: Colors.blue), // Синяя тема
    );
  }
}

// ЭКРАН С НИЖНЕЙ НАВИГАЦИЕЙ
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ТЕКУЩАЯ ВКЛАДКА:
  // 0 = СПИСКИ ЗАДАЧ (To-Do)
  // 1 = КАЛЕНДАРЬ (главный экран по ТЗ)
  int _selectedIndex = 1; // Стартуем сразу с календаря!

  // СПИСОК ЭКРАНОВ ДЛЯ КАЖДОЙ ВКЛАДКИ:
  static final List<Widget> _pages = <Widget>[
    const ToDoListsScreen(), // Вкладка 0: Все списки задач
    const CalendarScreen(), // Вкладка 1: Месячный календарь
  ];
  // ФУНКЦИЯ: НАЖАТИЕ НА ВКЛАДКУ ВНИЗУ
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Меняем активную вкладку
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ОСНОВНОЕ СОДЕРЖИМОЕ ЭКРАНА
      // Показываем экран в зависимости от выбранной вкладки
      body: _pages[_selectedIndex],

      // НИЖНЯЯ ПАНЕЛЬ НАВИГАЦИИ
      bottomNavigationBar: BottomNavigationBar(
        // ДВЕ КНОПКИ НАВИГАЦИИ:
        items: const [
          // КНОПКА 1: СПИСКИ ЗАДАЧ
          BottomNavigationBarItem(
            icon: Icon(Icons.list), // Иконка списка
            label: 'To-Do', // Надпись под иконкой
          ),
          // КНОПКА 2: КАЛЕНДАРЬ
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today), // Иконка календаря
            label: 'Календарь', // Надпись под иконкой
          ),
        ],
        currentIndex: _selectedIndex, // Какая вкладка активна сейчас
        selectedItemColor: Colors.blue, // Синий цвет для активной вкладки
        unselectedItemColor: Colors.grey, // Серый цвет для неактивных
        onTap: _onItemTapped, // Что происходит при нажатии
      ),
    );
  }
}
