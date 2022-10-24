import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:indesproj/end.dart';
import 'package:indesproj/firebase_communication.dart';
import 'package:indesproj/start.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'flutterMap.dart';

double scaleImages = 1.53;
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
        primarySwatch: Colors.orange,
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
  late MapController _mapController;
  double _markerLat = 0;
  double _markerLng = 0;

  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  int _roundDuration = 1;
  bool eyeOpened = true;

  bool inGoal = false;
  List<LatLng> _goalCoordinates = [];
  bool inStart = false;
  List<LatLng> _startZoneCoordinates = [];

  late LatLng currentLatLng;

  bool playing = false;
  bool started = false;
  bool finished = false;

  int score = 0;
  bool movedLastRedLight = false;
  bool goToStart = false;

  bool _checkForMovement = false;
  late Timer _checkForMovementTimer;

  int _currentGoalIndex = 0;
  int points = 0;

  List<LatLng> _crystalCoordinates = [];

  //BUTTON VARS
  String pathImg = "assets/buttons/png";
  String interactState = "interactionButton.png";

  bool invisibilityQueued = false;
  bool invisibilityActivated = false;
  bool crystalballActivated = false;

  final List<LatLng> goalZones = [
    LatLng(57.70680144781405, 11.941158728073676),
    LatLng(57.70652503728925, 11.940347613243238),
    LatLng(57.706023612872755, 11.940756720610546),
    LatLng(57.705805041084346, 11.94015509216082),
    LatLng(57.706333, 11.939523),
  ];

  final List<LatLng> _powerUpZones = [
    LatLng(57.70642924986367, 11.939885890601499),
    LatLng(57.70596056302828, 11.94080948681495),
    LatLng(57.70582419454079, 11.94032390472206),
    LatLng(57.70653651888252, 11.941387120560112),
    LatLng(57.70694083772142, 11.941112203974354),
    LatLng(57.70607597611035, 11.941823375453465),
  ];

  List<List<LatLng>> _currentPowerUpCoordinates = [];

  int inPowerUp = -1;
  bool ableToPickUp = false;

  //Users powerups 0 is invisibility, 1 is crystal ball
  List<int> powerUps = [];

  List<int> puIndex = [0, 1, 2, 3];

  Random random = Random(42);

  final player = AudioPlayer();

  bool goalTaken = false;

  int iDur = 0;
  
  List<int> phaseDuration = [6, 6, 7, 8, 7, 6, 5, 7, 8, 6, 7, 7, 6, 5, 8, 9, 6, 6, 9, 7, 8];

  @override
  initState() {

    _mapController = MapController();

    //_currentGoalIndex = Random(66).nextInt(goalZones.length-2);

    //Set goal zone
    _goalCoordinates = goalCoordinates(goalZones[_currentGoalIndex], 0.00015);

    _startZoneCoordinates = goalCoordinates(
        LatLng(57.706229326292004, 11.940576232075628), 0.00015);

    _crystalCoordinates = goalCoordinates(
        goalZones[(_currentGoalIndex + 1) % goalZones.length], 0.00015);

    //gameStateTimer();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _timer.cancel();
    player.dispose();
    super.dispose();
  }

  void gameStateTimer() {
    started = true;
    _checkForMovement = false;
    score = 0;
    if (eyeOpened) {
      movedLastRedLight = false;
      if (invisibilityQueued) {
        invisibilityQueued = false;
        invisibilityActivated = true;
      }
    }
    _stopwatch.reset();
    _stopwatch.start();
    _roundDuration = phaseDuration[iDur%phaseDuration.length];
    iDur++;
    checkForMovementTimer(1);
    _timer = Timer(
        Duration(seconds: _roundDuration), //random between 4 and 10 seconds
        () {
          setState(() {
            eyeOpened = !eyeOpened;
          });
      gameStateTimer();
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

  int checkInPowerUp(LatLng userPos, List<List<LatLng>> powerUpCoords) {
    for (int i = 0; i < powerUpCoords.length; i++) {
      if (checkInGoal(userPos, powerUpCoords[i])) {
        return i;
      }
    }
    return -1;
  }

  void checkIfPlaying() {
    if (playing && !started) {
      player.play(AssetSource("sounds/start_game.wav"));
      gameStateTimer();
    } else if (!playing && started) {
      _timer.cancel();
      started = false;
      eyeOpened = true;
      movedLastRedLight = false;
      goToStart = false;
      score = 0;
      points = 0;
      iDur = 0;
      invisibilityQueued = false;
      invisibilityActivated = false;
      crystalballActivated = false;
    }

    if (finished) {
      Future.delayed(const Duration(seconds: 0), () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EndPage(points),
          ),
        );
        Provider.of<FirebaseConnection>(context, listen: false)
            .toggleGame(false);
      });
    }
  }

  void setNewGoalIndex() {
    //_currentGoalIndex = newIndex;
    goalTaken = true;
    inGoal = false;
    int newGoalIndex = (_currentGoalIndex + 1) % goalZones.length;
    Provider.of<FirebaseConnection>(context, listen: false)
        .newGoal((newGoalIndex), points);
  }

  void goalManager() {
    int dbCurrentGoal =
        Provider.of<FirebaseConnection>(context).currentGoalIndex;
    if ((dbCurrentGoal != -1) && (dbCurrentGoal != _currentGoalIndex)) {
      setState(() {
        //_startZoneCoordinates = goalCoordinates(goalZones[_currentGoalIndex], 0.00015);

        if (crystalballActivated) {
          crystalballActivated = false;
        }

        _currentGoalIndex = dbCurrentGoal;
        _goalCoordinates =
            goalCoordinates(goalZones[_currentGoalIndex], 0.00015);
        _crystalCoordinates = goalCoordinates(
            goalZones[(_currentGoalIndex + 1) % goalZones.length], 0.00015);
      });

      if (goalTaken) {
        points++;
      }

      if (points >= 3) {
        player.play(AssetSource("sounds/win_screen.wav"));

        Provider.of<FirebaseConnection>(context, listen: false).endGame();
      } else {
        player.play(AssetSource("sounds/recive_point.mp3"));
      }

      goalTaken = false;
    }
  }

  void activateInvisibility() {
    if (!(invisibilityActivated || invisibilityQueued)) {
      invisibilityQueued = true;
    }
  }

  void activateCrystalball() {
    if (!crystalballActivated) {
      crystalballActivated = true;
    }
  }

  void pickUpPowerUp(int powerUpIndex) {
    if (powerUps.length < 2) {
      if (powerUpIndex != -1) {
        player.play(AssetSource("sounds/pick_up_powerup.mp3"));
        powerUps.add(random.nextInt(2));
      }
    }
  }

  void powerUpManager() {
    List<int> dbPowerUp = Provider.of<FirebaseConnection>(context).powerUpIndex;
    if ((dbPowerUp != puIndex)) {
      setState(() {
        puIndex = dbPowerUp;
        _currentPowerUpCoordinates.clear();
        for (int value in puIndex) {
          _currentPowerUpCoordinates.add(goalCoordinates(
              (_powerUpZones[value % _powerUpZones.length]), 0.00015 / 2));
        }
      });
    }
  }

  Widget powerUpButtons() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          TextButton(
            style: ButtonStyle(
              foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.transparent),
              backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.transparent),
            ),
            onPressed: () {
              if (powerUps.length > 0) {
                if ((powerUps[0] == 0)) {
                  activateInvisibility();
                } else {
                  activateCrystalball();
                  powerUps.removeAt(0);
                }
                player.play(AssetSource("sounds/use_powerup.wav"));
              }
            },
            child: (powerUps.length > 0)
                ? (powerUps[0] == 0)
                    ? Image.asset(
                        scale: scaleImages,
                        (!invisibilityActivated)
                            ? "$pathImg/invisibilityButton.png"
                            : "$pathImg/invisibilityButton_active.png",
                        //fit: BoxFit.cover
                      )
                    : Image.asset(
                        scale: scaleImages,
                        "$pathImg/crystalBallButton.png",
                        //fit: BoxFit.cover
                      )
                : Image.asset(
                    scale: scaleImages,
                    "$pathImg/nullButton.png",
                    //fit: BoxFit.cover
                  ),
          ),
          const SizedBox(
            width: 10,
          ),
          interactButton(),
          const SizedBox(
            width: 10,
          ),
          TextButton(
            // style: ButtonStyle(
            //   foregroundColor: MaterialStateProperty.all<Color>(Colors.amber),
            //   backgroundColor: MaterialStateProperty.all<Color>(Colors.white30),
            // ),
            onPressed: () {
              if (powerUps.length > 1) {
                if ((powerUps[1] == 0)) {
                  activateInvisibility();
                } else {
                  activateCrystalball();
                  powerUps.removeAt(1);
                }
                player.play(AssetSource("sounds/use_powerup.wav"));
              }
            },
            child: (powerUps.length > 1)
                ? (powerUps[1] == 0)
                    ? Image.asset(
                        scale: scaleImages,
                        "$pathImg/invisibilityButton.png",
                        //fit: BoxFit.cover
                      )
                    : Image.asset(
                        scale: scaleImages,
                        "$pathImg/crystalBallButton.png",
                        //fit: BoxFit.cover
                      )
                : Image.asset(
                    scale: scaleImages,
                    "$pathImg/nullButton.png",
                    //fit: BoxFit.cover
                  ),
          ),
        ]);
  }

  Widget interactButton() {
    return ((inPowerUp != -1 && !goToStart)) //pick up powerUp
        ? GestureDetector(
            onTapDown: (tap) {
              setState(() {
                interactState = "interactionButton_pressed.png";
              });
            },
            onTapCancel: () {
              setState(() {
                interactState = "interactionButton.png";
              });
            },
            onTapUp: (tap) {
              setState(() {
                interactState = "interactionButton.png";
              });
              pickUpPowerUp(inPowerUp);
            },
            child: Image.asset(
                scale: scaleImages,
                "$pathImg/$interactState",
                fit: BoxFit.cover),
          )
        // TextButton(
        //     style: ButtonStyle(
        //       foregroundColor: MaterialStateProperty.all<Color>(Colors.amber),
        //       backgroundColor: MaterialStateProperty.all<Color>(Colors.white30),
        //     ),
        //     onPressed: () {
        //       pickUpPowerUp(inPowerUp);
        //     },
        //     child: Text("Pick up powerUp"),
        //   )
        : ((inGoal && !goToStart)) // Pick up goal zone
            ? GestureDetector(
                onTapDown: (tap) {
                  setState(() {
                    interactState = "interactionButton_pressed.png";
                  });
                },
                onTapCancel: () {
                  setState(() {
                    interactState = "interactionButton.png";
                  });
                },
                onTapUp: (tap) {
                  setState(() {
                    interactState = "interactionButton.png";
                  });
                  if (!goalTaken) {
                    setNewGoalIndex();
                  }
                },
                child: Image.asset(
                  scale: scaleImages,
                  "$pathImg/$interactState",
                  fit: BoxFit.cover,
                ),
              )
            : GestureDetector(
                onTap: () {},
                child: Image.asset(
                    scale: scaleImages,
                    "$pathImg/interactionButton_null.png",
                    fit: BoxFit.cover),
              );
  }

  @override
  Widget build(BuildContext context) {
    playing = Provider.of<FirebaseConnection>(context).playing;
    finished = Provider.of<FirebaseConnection>(context).finished;

    checkIfPlaying();

    goalManager();

    powerUpManager();

    if (goToStart) {
      player.play(AssetSource("sounds/tic_toc.mp3"));
    }

    return Stack(children: [
      Image.asset("assets/backGround_image.png",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover),
      Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                    margin: const EdgeInsets.all(16),
                    child: Image.asset("assets/logo.png", fit: BoxFit.cover)),
                /*const Text("Accelerometer:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              Text("x: ${ae.x.toStringAsFixed(4)} y: ${ae.y.toStringAsFixed(4)} z: ${ae.z.toStringAsFixed(4)}"),*/
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 150,
                  child: eyeOpened ? Image.asset("$pathImg/eye_open.png", fit: BoxFit.cover) : Image.asset("$pathImg/eye_closed.png", fit: BoxFit.cover),
                ),
                SizedBox(
                  height: 400,
                  width: 400,
                  child: flutterMap(
                      mapController: _mapController,
                      context: context,
                      markerLat: _markerLat,
                      markerLng: _markerLng,
                      goalCoordinates: _goalCoordinates,
                      startZoneCoordinates: _startZoneCoordinates,
                      crystalCoordinates: crystalballActivated
                          ? (_crystalCoordinates)
                          : [],
                      powerUpCoordinates: _currentPowerUpCoordinates),
                ),
                Container(
                    margin: const EdgeInsets.all(16),
                  child: playing
                      ? eyeOpened
                      ? const Text("FREEZE PHASE",
                      style: TextStyle(
                          fontSize: 36, color: Colors.black))
                      : const Text("MOVE PHASE",
                      style: TextStyle(
                          fontSize: 36, color: Colors.black))
                      : const Text("GAME HAS NOT STARTED", style: TextStyle(fontSize: 36, color: Colors.black))
                ),
              ],
            ),
          ),
        ),
      )
    ]);
  }
}
