class Place {
  final String name;
  final double latitude;
  final double longitude;

  Place({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class PlacesResponse {
  final List<Place> places;
  final int totalPlaces;

  PlacesResponse({
    required this.places,
    required this.totalPlaces,
  });

  factory PlacesResponse.fromJson(Map<String, dynamic> json) {
    var placesList = json['places'] as List;
    List<Place> places = placesList.map((i) => Place.fromJson(i)).toList();

    return PlacesResponse(
      places: places,
      totalPlaces: json['metadata']['total_places'],
    );
  }
}