import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

var rng = Random();

class FirebaseConnection with ChangeNotifier {
  late FirebaseDatabase database;
  late DatabaseReference ref;
  late DatabaseReference refMe;
  late Map _playerPositions;

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
      print("listener triggerd");
      updatePlayers();
    });
  }

  addToDatabase(double lat, double long) async {
    await refMe.set({'latitude': lat, 'longitude': long});
  }

  void updatePlayers() async {
    DataSnapshot dbSnapshot = await refUsers.get();
    print(dbSnapshot.value);
    print("hejehej");
    notifyListeners();
  }

  Map get playerPositions => _playerPositions;
}
