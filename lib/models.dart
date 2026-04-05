import 'package:latlong2/latlong.dart';

// DTO (Data Transfer Object) для хранения разобранного ответа от сервиса OSRM
class RouteData {
  // Список вершин геометрии маршрута для PolylineLayer
  final List<LatLng> polylinePoints;
  // Дистанция, полученная из свойства distance (в метрах)
  final double distanceInMeters;
  // Длительность, полученная из свойства duration (в секундах)
  final double durationInSeconds;
  
  RouteData({
    required this.polylinePoints,
    required this.distanceInMeters,
    required this.durationInSeconds,
  });
}

// Сущность базы данных для записи в таблицу route_history
class RouteHistoryItem {
  final int? id;
  final String startAddress;
  final String endAddress;
  final double distance;
  final double duration;
  final DateTime createdAt;

  RouteHistoryItem({
    this.id,
    required this.startAddress,
    required this.endAddress,
    required this.distance,
    required this.duration,
    required this.createdAt,
  });

  // Сериализация объекта для метода db.insert() пакета sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_address': startAddress,
      'end_address': endAddress,
      'distance': distance,
      'duration': duration,
      // Трансформация DateTime в Unix Timestamp для хранения в поле типа INTEGER
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // Десериализация из структуры базы данных при выборке
  factory RouteHistoryItem.fromMap(Map<String, dynamic> map) {
    return RouteHistoryItem(
      id: map['id'],
      startAddress: map['start_address'],
      endAddress: map['end_address'],
      distance: map['distance'],
      duration: map['duration'],
      // Восстановление объекта DateTime из Timestamp
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}