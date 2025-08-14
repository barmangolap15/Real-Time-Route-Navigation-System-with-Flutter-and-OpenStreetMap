import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:route_navigation/route_viewer.dart';
import 'package:route_navigation/service/location_service.dart';
import 'package:route_navigation/service/place_service.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controller/location_controller.dart';
import 'model/place.dart';


class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final PlaceService _placeService = PlaceService();
  late Future<PlacesResponse> _futurePlaces;
  final LocationController locationController = Get.find<LocationController>();

  @override
  void initState() {
    super.initState();
    _futurePlaces = _placeService.fetchAssamPlaces();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    await LocationService.instance.getUserLocation(
      controller: locationController,
    );
  }

  Future<void> _launchMaps(Place place) async {
    if (locationController.userLocation.value == null) {
      await _getUserLocation();
      if (locationController.userLocation.value == null) return;
    }

    final currentLocation = locationController.userLocation.value!;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouteViewer(
          start: LatLng(currentLocation.latitude!, currentLocation.longitude!),
          end: LatLng(place.latitude, place.longitude),
        ),
      ),
    );
  }

  // Future<void> _launchMaps(Place place) async {
  //   if (locationController.userLocation.value == null) {
  //     await _getUserLocation();
  //     if (locationController.userLocation.value == null) return;
  //   }
  //
  //   final currentLocation = locationController.userLocation.value!;
  //
  //   // Using OSRM (Open Source Routing Machine) for shortest path calculation
  //   final osrmUrl = Uri.parse(
  //       'https://www.openstreetmap.org/directions?'
  //           'engine=osrm_car&'  // Uses OSRM for route calculation
  //           'route=${currentLocation.latitude}%2C${currentLocation.longitude}%3B'
  //           '${place.latitude}%2C${place.longitude}'
  //   );
  //
  //   // Alternative using GraphHopper (another OSM routing engine)
  //   final graphHopperUrl = Uri.parse(
  //       'https://graphhopper.com/maps/?'
  //           'point=${currentLocation.latitude}%2C${currentLocation.longitude}'
  //           '&point=${place.latitude}%2C${place.longitude}'
  //           '&vehicle=car&weighting=fastest'  // Ensures shortest route
  //   );
  //
  //   // Try OSRM first
  //   if (await canLaunchUrl(osrmUrl)) {
  //     try {
  //       await launchUrl(osrmUrl, mode: LaunchMode.externalApplication);
  //       return;
  //     } catch (e) {
  //       print('OSRM launch failed: $e');
  //     }
  //   }
  //
  //   // Fallback to GraphHopper
  //   if (await canLaunchUrl(graphHopperUrl)) {
  //     await launchUrl(graphHopperUrl, mode: LaunchMode.externalApplication);
  //   } else {
  //     // Ultimate fallback to basic OSM with markers
  //     final fallbackUrl = Uri.parse(
  //         'https://www.openstreetmap.org/directions?'
  //             'from=${currentLocation.latitude},${currentLocation.longitude}'
  //             '&to=${place.latitude},${place.longitude}'
  //     );
  //     await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
  //   }
  // }

  Widget _buildLocationHeader() {
    return Obx(() {
      if (locationController.isAccessingLocation.value) {
        return const ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Fetching your location...'),
        );
      }

      if (locationController.errorDescription.value.isNotEmpty) {
        return ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(locationController.errorDescription.value),
          trailing: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getUserLocation,
          ),
        );
      }

      if (locationController.userLocation.value != null) {
        final loc = locationController.userLocation.value!;
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.my_location, color: Colors.blue),
            title: const Text('Your Current Location'),
            subtitle: Text(
              'Lat: ${loc.latitude?.toStringAsFixed(4)}, '
                  'Lng: ${loc.longitude?.toStringAsFixed(4)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getUserLocation,
            ),
          ),
        );
      }

      return ListTile(
        leading: const Icon(Icons.location_off),
        title: const Text('Location not available'),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _getUserLocation,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places in Assam'),
      ),
      body: FutureBuilder<PlacesResponse>(
        future: _futurePlaces,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                _buildLocationHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.places.length,
                    itemBuilder: (context, index) {
                      final place = snapshot.data!.places[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(place.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lat: ${place.latitude}, Lng: ${place.longitude}'),
                              if (locationController.userLocation.value != null)
                                Text(
                                  '${_calculateDistance(place).toStringAsFixed(1)} km away',
                                  style: const TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            onPressed: () => _launchMaps(place),
                            tooltip: 'Get Directions',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  double _calculateDistance(Place destination) {
    final current = locationController.userLocation.value;
    if (current?.latitude == null || current?.longitude == null) return 0.0;

    return _haversineDistance(
      current!.latitude!,
      current.longitude!,
      destination.latitude,
      destination.longitude,
    );
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}