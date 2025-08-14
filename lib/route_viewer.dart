import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class RouteViewer extends StatefulWidget {
  final LatLng start;
  final LatLng end;

  const RouteViewer({Key? key, required this.start, required this.end})
      : super(key: key);

  @override
  _RouteViewerState createState() => _RouteViewerState();
}

class _RouteViewerState extends State<RouteViewer> {
  late List<LatLng> routePoints = [];
  late int currentPointIndex = 0;
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    try {
      final response = await http.get(Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
              '${widget.start.longitude},${widget.start.latitude};'
              '${widget.end.longitude},${widget.end.latitude}?overview=full'
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final geometry = data['routes'][0]['geometry'];
        routePoints = _decodePolyline(geometry);

        setState(() => isLoading = false);
        _animateCar();
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load route: $e';
        isLoading = false;
      });
    }
  }

  void _animateCar() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && currentPointIndex < routePoints.length - 1) {
        setState(() => currentPointIndex++);
        _animateCar();
      }
    });
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = _toRadians(from.latitude);
    final lon1 = _toRadians(from.longitude);
    final lat2 = _toRadians(to.latitude);
    final lon2 = _toRadians(to.longitude);

    final y = sin(lon2 - lon1) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    return _toDegrees(atan2(y, x));
  }

  double _toRadians(double degree) => degree * pi / 180;
  double _toDegrees(double radian) => radian * 180 / pi;

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Navigation')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : FlutterMap(
        options: MapOptions(
          initialCenter: routePoints.isNotEmpty
              ? routePoints[currentPointIndex]
              : widget.start,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: Colors.blue,
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: routePoints.isNotEmpty
                    ? routePoints[currentPointIndex]
                    : widget.start,
                width: 40,
                height: 40,
                child: Transform.rotate(
                  angle: currentPointIndex > 0 && currentPointIndex < routePoints.length - 1
                      ? _toRadians(_calculateBearing(
                    routePoints[currentPointIndex],
                    routePoints[currentPointIndex + 1],
                  ))
                      : 0,
                  child: const Icon(
                    Icons.directions_car_filled,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}