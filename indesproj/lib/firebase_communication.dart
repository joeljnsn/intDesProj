import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

var rng = Random();

class FirebaseConnection with ChangeNotifier {
  late FirebaseDatabase database;
  late DatabaseReference ref;
  late DatabaseReference refMe;
  late Map<String, dynamic> _playerPositions;
  List<Marker> _userMarkers = [];

  late DatabaseReference refUsers;
  String id = "";
  FirebaseConnection({required this.id}) {
    initConnection();
  }

  void initConnection() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    database = FirebaseDatabase.instance;
    ref = FirebaseDatabase.instance.ref();

    refMe = FirebaseDatabase.instance.ref("Users/$id");
    refUsers = FirebaseDatabase.instance.ref("Users");

    refUsers.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if(data != null){
        updatePlayers(data);
      }
    });

    refMe.onDisconnect().remove();

  }

  addToDatabase(double lat, double long) async {
    await refMe.set({'latitude': lat, 'longitude': long});
  }

  void updatePlayers(Object data) {
    _playerPositions = Map<String, dynamic>.from(data as Map);
    populateMarkers();
    notifyListeners();
  }

  void populateMarkers(){
    List<Marker> newUserMarkers = [];
    _playerPositions.forEach((key, value) {
      if(key != value){
        Marker newMarker = Marker(
          point: LatLng(value["latitude"] ?? 0, value["longitude"] ?? 0), //User marker
          width: 20,
          height: 20,
          builder: (context) => Container(
            decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 6)),
          ),
        );
        newUserMarkers.add(newMarker);
      }
    });
    _userMarkers = newUserMarkers;
  }

  Map<String, dynamic> get playerPositions => _playerPositions;
  List<Marker> get userMarkers => _userMarkers;
}
