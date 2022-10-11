import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

var rng = Random();

class FirebaseConnection {
  late FirebaseDatabase database;
  late DatabaseReference ref;
  late DatabaseReference refUsers;

  late DatabaseReference refAge;
  FirebaseConnection();

  void initConnection() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    database = FirebaseDatabase.instance;
    ref = FirebaseDatabase.instance.ref();

    refUsers = FirebaseDatabase.instance.ref("Users/1/1");
    refAge = refUsers.child("age");
    refAge.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      print("$data was recived from listener");
    });
  }

  addToDatabase() async {
    int x = rng.nextInt(80);
    print("randomized and uploaded: $x");
    await refUsers.set({'name': 'Nils', 'age': x});
  }
}
