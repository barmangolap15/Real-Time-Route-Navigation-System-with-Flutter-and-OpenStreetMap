import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:route_navigation/places_screen.dart';

import 'controller/location_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LocationController());
    return GetMaterialApp(
      title: 'CropSS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PlacesScreen(),
    );
  }
}