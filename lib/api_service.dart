import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'models.dart';

class ApiService {
  // Метод взаимодействия с OSRM API для извлечения дистанции и геометрии
  static Future<RouteData> getRoute(LatLng start, LatLng end) async {
    // Архитектурная особенность: OSRM парсит параметры в порядке "Долгота, Широта"
    final String url = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Анализ флага успешности маршрутизации OSRM
        if (data['code'] == 'Ok') {
          final route = data['routes'];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Трансформация GeoJSON: конвертация массива массивов [lon, lat] в объекты LatLng(lat, lon)
          List<LatLng> points = coordinates.map((coord) {
            return LatLng(coord as double, coord as double);
          }).toList();

          return RouteData(
            polylinePoints: points,
            distanceInMeters: (route['distance'] as num).toDouble(),
            durationInSeconds: (route['duration'] as num).toDouble(),
          );
        } else {
          // OSRM может вернуть HTTP 200, но код 'NoRoute', если дорожный граф разорван
          throw Exception('Топологическая ошибка: ${data['message']}');
        }
      } else {
        throw Exception('Внутренняя ошибка сервиса маршрутизации (код ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Сетевая ошибка: отсутствует соединение с сервером.');
    } catch (e) {
      throw Exception('Критический сбой построения маршрута: $e');
    }
  }

  // Метод обратного геокодирования через экосистему Nominatim
  static Future<String> getAddress(LatLng point) async {
    final String url = 'https://nominatim.openstreetmap.org/reverse?'
        'lat=${point.latitude}&lon=${point.longitude}&format=jsonv2';

    try {
      // Идентификация клиента обязательна согласно Terms of Use серверов OSM
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FlutterMapRoutingEduApp/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Попытка семантического извлечения адреса для минимизации длины строки
        if (data.containsKey('address')) {
          final address = data['address'];
          String road = address['road']?? address['pedestrian']?? address['path']?? '';
          String houseNumber = address['house_number']?? '';
          String city = address['city']?? address['town']?? address['village']?? '';
          
          String formatted = [road, houseNumber, city]
             .where((element) => element.isNotEmpty)
             .join(', ');
              
          // Фолбэк на display_name, если детальный адрес недоступен
          return formatted.isNotEmpty? formatted : (data['display_name']?? 'Неизвестная локация');
        }
        return data['display_name']?? 'Неизвестный адрес';
      } else {
        throw Exception('Ошибка геокодирования: код ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Сетевая ошибка: геокодирование недоступно.');
    } catch (e) {
      // В случае любых исключений система должна гарантировать возврат строкового значения для UI
      return 'Координаты: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
    }
  }
}