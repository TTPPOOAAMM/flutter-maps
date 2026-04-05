import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'database_helper.dart';
import 'models.dart';
import 'history_screen.dart'; // Теперь импорт используется для навигации

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Контроллер для манипуляций с камерой карты
  final MapController _mapController = MapController();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Локальные переменные состояния
  LatLng? _currentLocation;
  LatLng? _pointA;
  LatLng? _pointB;
  List<LatLng> _routePoints = []; // Исправлено: добавлены скобки []

  String _addressA = '';
  String _addressB = '';
  double _distance = 0.0;
  double _duration = 0.0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // При запуске инициируется поиск геолокации пользователя
    _initCurrentLocation();
  }

  Future<void> _initCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await LocationService.getCurrentLocation();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
      });
      // Центрирование камеры на позиции пользователя
      _mapController.move(latLng, 15.0);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Механизм выбора точек маршрута касанием карты
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_pointA == null) {
      setState(() {
        _pointA = point;
        _routePoints.clear();
      });
      _resolveAddressA(point);
    } else if (_pointB == null) {
      setState(() {
        _pointB = point;
      });
      _resolveAddressB(point).then((_) => _buildRoute());
    }
  }

  Future<void> _resolveAddressA(LatLng point) async {
    try {
      final addr = await ApiService.getAddress(point);
      setState(() => _addressA = addr);
    } catch (e) {
      _showError('Не удалось выполнить геокодирование начальной точки');
    }
  }

  Future<void> _resolveAddressB(LatLng point) async {
    try {
      final addr = await ApiService.getAddress(point);
      setState(() => _addressB = addr);
    } catch (e) {
      _showError('Не удалось выполнить геокодирование конечной точки');
    }
  }

  // Построение маршрута и вызов сохранения в БД
  Future<void> _buildRoute() async {
    // Исправлено: убран разрыв логического оператора ||
    if (_pointA == null || _pointB == null) return;

    setState(() => _isLoading = true);
    try {
      final routeData = await ApiService.getRoute(_pointA!, _pointB!);
      setState(() {
        _routePoints = routeData.polylinePoints;
        _distance = routeData.distanceInMeters;
        _duration = routeData.durationInSeconds;
      });
      
      _fitRouteBounds();
      _saveToHistory();
    } catch (e) {
      _showError(e.toString());
      // Сброс только проблемной точки при сбое
      setState(() {
        _pointB = null;
        _routePoints.clear();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Математическая подгонка камеры для отображения всего маршрута на экране
  void _fitRouteBounds() {
    if (_routePoints.isEmpty) return;
    
    final bounds = LatLngBounds.fromPoints(_routePoints);
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(left: 50, right: 50, top: 50, bottom: 200),
      ),
    );
  }

  Future<void> _saveToHistory() async {
    final item = RouteHistoryItem(
      startAddress: _addressA,
      endAddress: _addressB,
      distance: _distance,
      duration: _duration,
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertRoute(item);
  }

  // Переход к текущему местоположению и назначение его точкой А
  void _goToCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await LocationService.getCurrentLocation();
      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = latLng;
        // Если карта сброшена, координата пользователя становится "Точкой А"
        if (_pointA == null) {
          _pointA = latLng;
          _resolveAddressA(latLng);
        }
      });
      _mapController.move(latLng, 16.0);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Сброс выбранных точек и маршрута
  void _resetMap() {
    setState(() {
      _pointA = null;
      _pointB = null;
      _routePoints.clear();
      _addressA = '';
      _addressB = '';
      _distance = 0.0;
      _duration = 0.0;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Формирование списка маркеров для слоя карты
    List<Marker> markers = []; // Исправлено: добавлены скобки []
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    }
    if (_pointA != null) {
      markers.add(
        Marker(
          point: _pointA!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.green, size: 40),
        ),
      );
    }
    if (_pointB != null) {
      markers.add(
        Marker(
          point: _pointB!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS Навигатор'),
        actions: [
          // Исправлено: теперь импорт history_screen задействован
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Исправлено: восстановлено дерево FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(0, 0),
              initialZoom: 15.0,
              onTap: _onMapTap, // Метод теперь используется
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          ),
          
          // Индикатор загрузки
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Панель отображения данных
          if (_pointA != null)
            Positioned(
              bottom: 20,
              left: 10,
              right: 10,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Исправлено: восстановлен вывод адресов и дистанции
                    children: [
                      Text('Точка А: ${_addressA.isEmpty ? "Определяется..." : _addressA}'),
                      if (_pointB != null) ...[
                        const SizedBox(height: 8),
                        Text('Точка Б: ${_addressB.isEmpty ? "Определяется..." : _addressB}'),
                        const SizedBox(height: 8),
                        Text('Дистанция: ${(_distance / 1000).toStringAsFixed(2)} км'),
                        Text('Время в пути: ${(_duration / 60).toStringAsFixed(0)} мин'),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Кнопки управления
          Positioned(
            top: 20,
            right: 10,
            child: Column(
              // Исправлено: восстановлены виджеты кнопок и задействованы методы
              children: [
                FloatingActionButton(
                  heroTag: 'my_location_btn',
                  mini: true,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'reset_btn',
                  mini: true,
                  onPressed: _resetMap,
                  child: const Icon(Icons.refresh),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}