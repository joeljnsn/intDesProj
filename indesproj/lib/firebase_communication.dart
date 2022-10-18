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
  late DatabaseReference refGameState;
  late Map<String, dynamic> _playerPositions;
  List<Marker> _userMarkers = [];

  late DatabaseReference refUsers;
  String id = "";

  bool playing = false;
  int currentGoalIndex = 0;
  int powerUpIndex = 0;

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

    refUsers.remove();

    refUsers.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if(data != null){
        updatePlayers(data);
      }
    });

    refGameState = FirebaseDatabase.instance.ref("Gamestate");

    refGameState.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if(data != null){
        updateGamestate(data);
      }
    });

    refMe.onDisconnect().remove();
    refGameState.onDisconnect().set({'playing' : false, 'powerUpIndex' : 1});

  }

  addToDatabase(double lat, double long, int points) async {
    await refMe.update({'latitude': lat, 'longitude': long, 'points' : points});
  }

  void updatePlayers(Object data) {
    _playerPositions = Map<String, dynamic>.from(data as Map);
    populateMarkers();
    notifyListeners();
  }

  void populateMarkers(){
    List<Marker> newUserMarkers = [];
    _playerPositions.forEach((key, value) {
      if(key != id){
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

  void newGoal(int i, int points) {
    refGameState.update({'goalIndex' : i});
    refMe.update({'points' : points});
  }

  void newPowerUpIndex(int i) {
    refGameState.update({'powerUpIndex' : i});
  }

  void updateGamestate(Object data) {
    Map<String, dynamic> GameStateMap = Map<String, dynamic>.from(data as Map);
    playing = GameStateMap["playing"];
    currentGoalIndex = GameStateMap["goalIndex"] ?? -1;
    powerUpIndex = GameStateMap["powerUpIndex"] ?? -1;

    notifyListeners();
  }

  void toggleGame(bool state) {
    refGameState.set({"playing" : state});
  }

  Map<String, dynamic> get playerPositions => _playerPositions;
  List<Marker> get userMarkers => _userMarkers;
}
