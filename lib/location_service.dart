import 'package:geolocator/geolocator.dart';

class LocationService {
  // Асинхронная операция с глубоким контролем системных разрешений ОС
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Проверка физического состояния GPS-модуля (включен/выключен)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Службы геолокации аппаратно отключены. Активируйте GPS в настройках.');
    }

    // 2. Проверка статуса прав доступа на уровне манифеста и пользователя
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Динамический запрос системного диалога ОС
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Доступ к геолокации отклонен пользователем.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Доступ заблокирован навсегда. Требуется изменение прав в системных настройках.');
    }

    // 3. Запрос позиции с параметром LocationAccuracy.high для активации GPS-антенны
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}