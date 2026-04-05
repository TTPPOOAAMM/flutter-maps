import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  // Реализация потокобезопасного паттерна Singleton
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Инициализация базы данных с ленивой загрузкой
  Future<Database> get database async {
    if (_database!= null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Получение защищенной директории приложения в ОС
    String path = join(await getDatabasesPath(), 'routing_history.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // DDL-инструкции создания реляционной структуры
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE route_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_address TEXT,
        end_address TEXT,
        distance REAL,
        duration REAL,
        created_at INTEGER
      )
    ''');
  }

  // Асинхронная вставка новой записи истории
  Future<int> insertRoute(RouteHistoryItem item) async {
    final db = await database;
    return await db.insert('route_history', item.toMap());
  }

  // Выборка с сортировкой на стороне ядра SQLite (ORDER BY DESC)
  Future<List<RouteHistoryItem>> getHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'route_history',
      orderBy: 'created_at DESC',
    );
    // Маппинг полученных ассоциативных массивов в DTO объекты
    return List.generate(maps.length, (i) => RouteHistoryItem.fromMap(maps[i]));
  }
}