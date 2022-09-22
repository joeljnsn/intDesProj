import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late UserAccelerometerEvent ae;
  double totalAe = 0;
  double aeX = 0;
  double aeY = 0;
  double aeZ = 0;
  late MapController _mapController;
  double _markerLat = 0;
  double _markerLng = 0;

  void initLocation() async{
    Location location = new Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen((LocationData crntLoc) {
      setState(() {
        _markerLat = crntLoc.latitude ?? 0;
        _markerLng = crntLoc.longitude ?? 0;
        _mapController.move(LatLng(_markerLat, _markerLng), 16);
      });
    });

  }

  @override
  initState() {
    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        ae = event;
        aeX = (event.x).abs();
        aeY = (event.y).abs();
        aeZ = (event.z).abs();
        totalAe = aeX + aeY + aeZ;
      });
    });

    ae = UserAccelerometerEvent(0, 0, 0);

    _mapController = MapController();

    initLocation();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Widget flutterMap(){
    return FlutterMap(
    options: MapOptions(
      center: LatLng(0, 0),
      zoom: 16,
    ),
    mapController: _mapController,
    nonRotatedChildren: [
      AttributionWidget.defaultWidget(
        source: 'OpenStreetMap contributors',
        onSourceTapped: null,
      ),
    ],
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        //userAgentPackageName: 'com.example.app',
      ),
      MarkerLayer(
        markers: [
          Marker(
            point: LatLng(_markerLat, _markerLng),
            width: 20,
            height: 20,
            builder: (context) => Container(color: Colors.red,),
          ),
        ],
      ),
    ],
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: (totalAe > 2) ? Colors.red : Colors.white,
      appBar: AppBar(
        title: const Text("Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text("Accelerometer:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            Text("x: ${ae.x.toStringAsFixed(4)} y: ${ae.y.toStringAsFixed(4)} z: ${ae.z.toStringAsFixed(4)}"),
            const SizedBox(height: 25, width: double.infinity,),
            SizedBox(
              height: 500,
                child: flutterMap()
            ),
          ],
        ),
      ),
    );
  }
}
