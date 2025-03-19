import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LocationData? _currentLocation;
  final Location _locationService = Location();
  List<LatLng> _additionalPoints = [];
  List<LatLng> _customPoints = [];
  final MapController _mapController =
      MapController(); 

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final hasPermission = await _locationService.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      await _locationService.requestPermission();
    }
    final locationData = await _locationService.getLocation();
    setState(() {
      _currentLocation = locationData;
    });

    _locationService.onLocationChanged.listen((LocationData result) {
      setState(() {
        _currentLocation = result;
      });
    });
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ubicación Actual"),
          content: Text(
            "Latitud: ${_currentLocation?.latitude}\n"
            "Longitud: ${_currentLocation?.longitude}",
          ),
          actions: [
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _generateAdditionalPoints() {
    if (_currentLocation != null) {
      setState(() {
        _additionalPoints = [
          LatLng(
              _currentLocation!.latitude! + 0.01, _currentLocation!.longitude!),
          LatLng(
              _currentLocation!.latitude! - 0.01, _currentLocation!.longitude!),
          LatLng(
              _currentLocation!.latitude!, _currentLocation!.longitude! + 0.01),
          LatLng(
              _currentLocation!.latitude!, _currentLocation!.longitude! - 0.01),
        ];
      });
    }
  }

  void _openAddLocationDialog() {
    TextEditingController latController = TextEditingController();
    TextEditingController lonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Agregar Nueva Ubicación"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Latitud"),
              ),
              TextField(
                controller: lonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Longitud"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Guardar"),
              onPressed: () {
                double? lat = double.tryParse(latController.text);
                double? lon = double.tryParse(lonController.text);
                if (lat != null && lon != null) {
                  setState(() {
                    _customPoints.add(LatLng(lat, lon));
                  });

                  _mapController.move(LatLng(lat, lon), 13.0);

                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map OpenStreetMap')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(
                  _currentLocation!.latitude!,
                  _currentLocation!.longitude!,
                ),
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(
                        _currentLocation!.latitude!,
                        _currentLocation!.longitude!,
                      ),
                      builder: (ctx) => GestureDetector(
                        onTap: _showLocationDialog,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                    ..._additionalPoints.map((point) => Marker(
                          width: 80.0,
                          height: 80.0,
                          point: point,
                          builder: (ctx) => const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 30,
                          ),
                        )),
                    ..._customPoints.map((point) => Marker(
                          width: 80.0,
                          height: 80.0,
                          point: point,
                          builder: (ctx) => const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 30,
                          ),
                        )),
                  ],
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _generateAdditionalPoints,
            child: const Icon(Icons.add_location_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _openAddLocationDialog,
            child: const Icon(Icons.edit_location),
          ),
        ],
      ),
    );
  }
}
