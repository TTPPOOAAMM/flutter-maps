import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/route_model.dart';
import '../services/osrm_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  LatLng? _currentLocation;
  LatLng? _pointA;
  LatLng? _pointB;
  List<LatLng> _routePoints = [];
  
  bool _isLoading = false;
  RouteResult? _routeInfo;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Получение текущего местоположения пользователя
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    
    // Центрируем карту на пользователе
    _mapController.move(_currentLocation!, 13.0);
  }

  // Обработка нажатия на карту для установки точек А и В
  void _onMapTap(TapPosition tapPosition, LatLng point) { // [cite: 23]
    setState(() {
      if (_pointA == null) {
        _pointA = point; // [cite: 24, 26]
      } else if (_pointB == null) {
        _pointB = point; // [cite: 27]
      } else {
        // Если обе точки стоят, сбрасываем и ставим А заново
        _resetRoute();
        _pointA = point;
      }
    });
  }

  // Построение маршрута
  Future<void> _buildRoute() async {
    if (_pointA == null || _pointB == null) return;

    setState(() => _isLoading = true);

    final route = await OsrmService.getRoute(_pointA!, _pointB!);

    if (route != null) {
      setState(() {
        _routePoints = route.points;
        _routeInfo = route;
        _isLoading = false;
      });

      // Автомасштабирование, чтобы маршрут поместился на экране
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(_routePoints),
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при построении маршрута')),
      );
    }
  }

  void _resetRoute() {
    setState(() {
      _pointA = null;
      _pointB = null;
      _routePoints = [];
      _routeInfo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Маршрут по дорогам'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetRoute,
            tooltip: 'Сбросить маршрут',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(55.75, 37.61), // Москва по умолчанию
                initialZoom: 11,
                onTap: _onMapTap, // 
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // [cite: 19]
                  userAgentPackageName: 'com.example.route_app',
                ),
                PolylineLayer(
                  polylines: [
                    if (_routePoints.isNotEmpty)
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.blue, // [cite: 21]
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    // Маркер текущего местоположения
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                      ),
                    // Точка А
                    if (_pointA != null)
                      Marker(
                        point: _pointA!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.green, size: 40), // [cite: 20]
                      ),
                    // Точка В
                    if (_pointB != null)
                      Marker(
                        point: _pointB!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Панель управления маршрутом
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_routeInfo != null) ...[
                  Text('Длина маршрута: ${(_routeInfo!.distanceMeters / 1000).toStringAsFixed(2)} км',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Время в пути: ${(_routeInfo!.durationSeconds / 60).toStringAsFixed(0)} мин',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
                ElevatedButton( // [cite: 28]
                  onPressed: (_isLoading || _pointA == null || _pointB == null) 
                      ? null 
                      : _buildRoute,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Построить маршрут"),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _determinePosition,
        child: const Icon(Icons.my_location),
        tooltip: 'Мое местоположение',
      ),
    );
  }
}