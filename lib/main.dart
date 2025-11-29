import 'package:flutter/material.dart';
import 'todo_screen.dart';
import 'calendar_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
      title: 'Calendar', // Название приложения — как в ТЗ
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

// Главный экран с нижней навигацией: To-Do и Календарь
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex =
      1; // Открываем сразу календарь (по ТЗ главное — календарь)

  // Список экранов
  static final List<Widget> _pages = <Widget>[
    ToDoListsScreen(),
    CalendarScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'To-Do'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Календарь'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
