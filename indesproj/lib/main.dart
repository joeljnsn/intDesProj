import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:indesproj/end.dart';
import 'package:indesproj/firebase_communication.dart';
import 'package:indesproj/start.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock/wakelock.dart';
import 'package:provider/provider.dart';

import 'flutterMap.dart';

void main() {
  int id = Random().nextInt(3000);

  runApp(ChangeNotifierProvider(
      create: (context) => FirebaseConnection(id: "$id"),
      lazy: false,
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const StartPage(),
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

  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  int _roundDuration = 1;
  bool eyeOpened = true;

  late Timer _vibrationTimer;

  bool inGoal = false;
  List<LatLng> _goalCoordinates = [];
  bool inStart = false;
  List<LatLng> _startZoneCoordinates = [];

  late LatLng currentLatLng;

  late bool _hasVibration;

  bool playing = false;
  bool started = false;

  int score = 0;
  bool movedLastRedLight = false;
  bool goToStart = false;

  List<Marker> _userMarkers = [];

  List<int> listOfDuration = [
    6,
    6,
    5,
    7,
    5,
    5,
    8,
    6,
    7,
    5,
    6,
    9,
    7,
    5,
    7,
    8,
    7,
    5,
    5
  ];

  int iDur = 0;

  bool _checkForMovement = false;
  late Timer _checkForMovementTimer;

  void initLocation() async {
    Location location = Location();

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

    location.onLocationChanged.listen((LocationData currentLoc) {
      setState(() {
        _markerLat = currentLoc.latitude ?? 0;
        _markerLng = currentLoc.longitude ?? 0;
        double currentZoom = _mapController.zoom;
        currentLatLng = LatLng(_markerLat, _markerLng);
        _mapController.move(currentLatLng,
            currentZoom); //Moves map to current location. Hard transition, do we want this? might be annoying

        inGoal = checkInGoal(currentLatLng, _goalCoordinates);
        inStart = checkInGoal(currentLatLng, _startZoneCoordinates);
      });

      if (inGoal && !eyeOpened && !goToStart) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EndPage(score),
          ),
        );
      }

      if (goToStart && inStart) {
        goToStart = false;
      }
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

        if (totalAe > 2 &&
            playing &&
            _checkForMovement &&
            (eyeOpened || movedLastRedLight)) {
          score++;
          if ((score >= 10) ||
              (score >= 5 && movedLastRedLight && !eyeOpened)) {
            goToStart = true;
          } else if (score >= 5) {
            movedLastRedLight = true;
          }
        }
      });
    });

    Wakelock.enable(); //Does not work?

    ae = UserAccelerometerEvent(0, 0, 0);

    _mapController = MapController();

    initLocation();

    _goalCoordinates = goalCoordinates(
        LatLng(57.70680144781405, 11.941158728073676),
        0.00015); //Set goalCoordinates.

    _startZoneCoordinates =
        goalCoordinates(LatLng(57.706333, 11.939523), 0.00015);

    initVibration();

    //gameStateTimer();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _timer.cancel();
    Wakelock.disable();
    super.dispose();
  }

  void initVibration() async {
    bool? checkVibration = await Vibration.hasVibrator();
    _hasVibration = checkVibration ?? false;
  }

  void gameStateTimer() {
    Provider.of<FirebaseConnection>(context, listen: false)
        .addToDatabase(currentLatLng.latitude, currentLatLng.longitude);
    started = true;
    _checkForMovement = false;
    score = 0;
    if (eyeOpened) {
      movedLastRedLight = false;
    }
    _stopwatch.reset();
    _stopwatch.start();
    _roundDuration = listOfDuration[iDur % listOfDuration.length];
    iDur++;
    //_roundDuration = Random().nextInt(6) + 4;
    vibrationTimer(_roundDuration - 3);
    checkForMovementTimer(1);
    _timer = Timer(
        Duration(seconds: _roundDuration), //random between 4 and 10 seconds
        () {
      eyeOpened = !eyeOpened;
      gameStateTimer();
    });
  }

  void vibrationTimer(int vibDuration) {
    _vibrationTimer = Timer(Duration(seconds: vibDuration), () {
      if (_hasVibration) {
        if (!movedLastRedLight) {
          if (!eyeOpened) {
            //closed -> open.
            Vibration.vibrate(pattern: [0, 500, 500, 500, 500, 1000]);
          } else {
            //open -> closed.
            Vibration.vibrate(pattern: [1975, 125, 100, 800]);
          }
        }
      }
    });
  }

  void checkForMovementTimer(int checkDuration) {
    _checkForMovementTimer = Timer(Duration(seconds: checkDuration), () {
      _checkForMovement = true;
    });
  }

  List<LatLng> goalCoordinates(LatLng center, double size) {
    List<LatLng> goalCoord = [center, center, center, center];
    goalCoord[0] = LatLng(center.latitude + size, center.longitude + 2 * size);
    goalCoord[1] = LatLng(center.latitude + size, center.longitude - 2 * size);
    goalCoord[2] = LatLng(center.latitude - size, center.longitude - 2 * size);
    goalCoord[3] = LatLng(center.latitude - size, center.longitude + 2 * size);
    return goalCoord;
  }

  //Use LatLngBounds.contains instead?
  bool checkInGoal(LatLng userPos, List<LatLng> goalCoord) {
    return (((userPos.latitude < goalCoord[0].latitude) &&
            (userPos.longitude < goalCoord[0].longitude)) &&
        ((userPos.latitude > goalCoord[2].latitude) &&
            (userPos.longitude > goalCoord[2].longitude)));
  }

  @override
  Widget build(BuildContext context) {
    playing = Provider.of<FirebaseConnection>(context, listen: false).playing;

    if (playing && !started) {
      gameStateTimer();
    } else if (!playing && started) {
      _timer.cancel();
      _vibrationTimer.cancel();
      started = false;
      eyeOpened = true;
      movedLastRedLight = false;
      goToStart = false;
      score = 0;
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Container(
        color: goToStart
            ? Colors.blue
            : (movedLastRedLight
                ? Colors.red
                : (eyeOpened
                    ? Colors.black
                    : Color.fromRGBO(
                        0,
                        0,
                        0,
                        _stopwatch.elapsedMilliseconds /
                            (_roundDuration * 1000)))),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              /*const Text("Accelerometer:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              Text("x: ${ae.x.toStringAsFixed(4)} y: ${ae.y.toStringAsFixed(4)} z: ${ae.z.toStringAsFixed(4)}"),*/
              SizedBox(
                  height:
                      (eyeOpened || movedLastRedLight || goToStart) ? 500 : 0,
                  child: flutterMap(
                      mapController: _mapController,
                      context: context,
                      markerLat: _markerLat,
                      markerLng: _markerLng,
                      goalCoordinates: _goalCoordinates,
                      startZoneCoordinates: _startZoneCoordinates)),
              Container(
                margin: const EdgeInsets.only(top: 16.0),
                height: 2,
                width: 200,
                color: Colors.white,
              ),
              (eyeOpened || movedLastRedLight)
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 20,
                      width: totalAe * 100,
                      color: Colors.amber,
                    )
                  : Container(),
              playing
                  ? goToStart
                      ? const Text("GO TO START",
                          style: TextStyle(fontSize: 36, color: Colors.amber))
                      : ((movedLastRedLight
                          ? const Text("ILLEGAL MOVE",
                              style:
                                  TextStyle(fontSize: 36, color: Colors.amber))
                          : (eyeOpened
                              ? const Text("DO NOT MOVE",
                                  style: TextStyle(
                                      fontSize: 36, color: Colors.amber))
                              : const Text("MOVE",
                                  style: TextStyle(
                                      fontSize: 100, color: Colors.amber)))))
                  : TextButton(
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.amber),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white30),
                      ),
                      onPressed: () {
                        if (true) {
                          setState(() {
                            Provider.of<FirebaseConnection>(context,
                                    listen: false)
                                .toggleGame(true);
                            playing = true;
                            score = 0;
                          });
                        } else {
                          const snackbar = SnackBar(
                            content: Text(
                                "Cannot start game when not in starting zone."),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackbar);
                        }
                      },
                      child: const Text('Start Game',
                          style: TextStyle(fontSize: 18)),
                    ),
              /*Text(
                "Score: $score",
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "At goal: $inGoal",
                style: const TextStyle(color: Colors.white),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}
