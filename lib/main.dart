import 'package:flutter/material.dart';
import 'map_screen.dart';

void main() {
  // Обязательная инициализация биндингов перед запуском приложения,
  // если в дальнейшем потребуется асинхронная инициализация (например, баз данных или системных настроек) до runApp.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RoutingMapApp());
}

class RoutingMapApp extends StatelessWidget {
  const RoutingMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIS Навигатор',
      // Настройка базовой визуальной темы приложения с использованием Material 3
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      // Отключение баннера "DEBUG" в правом верхнем углу
      debugShowCheckedModeBanner: false,
      // Установка экрана с картой в качестве главного (стартового) экрана
      home: const MapScreen(),
    );
  }
}