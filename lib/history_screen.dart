import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<RouteHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    // Инициализация асинхронного вызова к слою данных
    _historyFuture = _dbHelper.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История маршрутизации'),
      ),
      // Подписка на завершение операции ввода-вывода из SQLite
      body: FutureBuilder<List<RouteHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Сбой чтения хранилища: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) { // Исправлен разрыв ||
            return const Center(child: Text('База данных маршрутов пуста.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // Локализация и форматирование метки времени
              final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt);
              // Конвертация сырых физических величин
              final distKm = (item.distance / 1000).toStringAsFixed(2);
              final durMin = (item.duration / 60).toStringAsFixed(0);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Исправлено: добавлены скобки и восстановлены виджеты для отображения данных
                    children: [
                      Text(
                        'Дата: $dateStr',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.my_location, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('А: ${item.startAddress.isEmpty ? "Неизвестно" : item.startAddress}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Б: ${item.endAddress.isEmpty ? "Неизвестно" : item.endAddress}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Дистанция: $distKm км',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Время: $durMin мин',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}