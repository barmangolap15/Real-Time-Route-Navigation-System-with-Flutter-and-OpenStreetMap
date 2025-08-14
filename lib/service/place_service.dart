import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/place.dart';


class PlaceService {
  static const String _apiUrl = 'https://mocki.io/v1/22797d1e-cf16-4300-936b-f73df9138437';

  Future<PlacesResponse> fetchAssamPlaces() async {
    final response = await http.get(Uri.parse(_apiUrl));

    if (response.statusCode == 200) {
      return PlacesResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load places');
    }
  }
}