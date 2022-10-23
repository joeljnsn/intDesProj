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
import 'package:audioplayers/audioplayers.dart';

import 'flutterMap.dart';

double scaleImages = 1.15;
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
    LatLng(57.706333, 11.939523),
    LatLng(57.706023612872755, 11.940756720610546),
    LatLng(57.705805041084346, 11.94015509216082),
  ];

  List<List<LatLng>> _currentPowerUpCoordinates = [];

  int inPowerUp = -1;
  bool ableToPickUp = false;

  //Users powerups 0 is invisibility, 1 is crystal ball
  List<int> powerUps = [];

  List<int> puIndex = [0, 1];

  Random random = Random(42);
  Random randomPhase = Random(8);

  final player = AudioPlayer();

  bool goalTaken = false;

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
        currentLatLng = LatLng(_markerLat, _markerLng);

        inGoal = checkInGoal(currentLatLng, _goalCoordinates);
        inStart = checkInGoal(currentLatLng, _startZoneCoordinates);
        inPowerUp = checkInPowerUp(currentLatLng, _currentPowerUpCoordinates);
      });

      if ((inPowerUp != -1) && !eyeOpened && !goToStart) {
        ableToPickUp = true;
      } else {
        ableToPickUp = false;
      }

      if (goToStart && inStart) {
        score = 0;
        movedLastRedLight = false;
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
            ((eyeOpened && !invisibilityActivated) || movedLastRedLight) &&
            !goToStart) {
          score++;
          if ((score >= 10) ||
              (score > 5 &&
                  movedLastRedLight &&
                  (eyeOpened && !invisibilityActivated))) {
            goToStart = true;
            player.play(AssetSource("sounds/go_back.wav"));
            score = 0;
            movedLastRedLight = false;
          } else if (score >= 5 && score < 10) {
            player.play(AssetSource("sounds/strike.wav"));
            movedLastRedLight = true;
          }
        }
      });
    });

    Wakelock.enable(); //Does not work?

    ae = UserAccelerometerEvent(0, 0, 0);

    _mapController = MapController();

    initLocation();

    //_currentGoalIndex = Random(66).nextInt(goalZones.length-2);

    //Set goal zone
    _goalCoordinates = goalCoordinates(goalZones[_currentGoalIndex], 0.00015);

    _startZoneCoordinates = goalCoordinates(
        LatLng(57.706229326292004, 11.940576232075628), 0.00015);

    _crystalCoordinates = goalCoordinates(
        goalZones[(_currentGoalIndex + 1) % goalZones.length], 0.00015);

    initVibration();

    //gameStateTimer();
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _timer.cancel();
    player.dispose();
    Wakelock.disable();
    super.dispose();
  }

  void initVibration() async {
    bool? checkVibration = await Vibration.hasVibrator();
    _hasVibration = checkVibration ?? false;
  }

  void gameStateTimer() {
    Provider.of<FirebaseConnection>(context, listen: false)
        .addToDatabase(currentLatLng.latitude, currentLatLng.longitude, points);
    if (invisibilityActivated) {
      invisibilityActivated = false;
      if ((powerUps[0] == 0)) {
        powerUps.removeAt(0);
      } else {
        powerUps.removeAt(1);
      }
    }
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
    _roundDuration = randomPhase.nextInt(5) + 5;
    vibrationTimer(_roundDuration - 2);
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
        if (!movedLastRedLight && !goToStart) {
          if (!eyeOpened) {
            //closed -> open.

            //check if invi is queued
            if (!invisibilityQueued) {
              player.play(AssetSource("sounds/red_swap.wav"));
              Vibration.vibrate(duration: 2000);
            }
          } else {
            //open -> closed.
            Future.delayed(const Duration(milliseconds: 1750), () {
              player.play(AssetSource("sounds/green_phase.wav"));
            });
            Vibration.vibrate(pattern: [1750, 110, 30, 110]);
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
      _vibrationTimer.cancel();
      started = false;
      eyeOpened = true;
      movedLastRedLight = false;
      goToStart = false;
      score = 0;
      points = 0;
      invisibilityQueued = false;
      invisibilityActivated = false;
      crystalballActivated = false;
      Provider.of<FirebaseConnection>(context, listen: false)
          .addToDatabase(_markerLat, _markerLng, points);
    }

    if (finished) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EndPage(points),
        ),
      );
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
        Provider.of<FirebaseConnection>(context, listen: false)
            .newPowerUpIndex(powerUpIndex);
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
                child:
                    Image.asset("$pathImg/$interactState", fit: BoxFit.cover),
              )
            : GestureDetector(
                onTap: () {},
                child: Image.asset("$pathImg/interactionButton_null.png",
                    fit: BoxFit.cover),
              );
  }

  @override
  Widget build(BuildContext context) {
    playing = Provider.of<FirebaseConnection>(context).playing;
    finished = Provider.of<FirebaseConnection>(context).finished;

    checkIfPlaying();

    bool dontMove = (eyeOpened && !invisibilityActivated) || movedLastRedLight;

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
        body: Container(
          color: goToStart
              ? Colors.blue
              : (movedLastRedLight
                  ? Colors.red
                  : (eyeOpened
                      ? Colors.transparent
                      : Color.fromRGBO(
                          (84 +
                                  165 *
                                      (_stopwatch.elapsedMilliseconds /
                                          (_roundDuration * 1000)))
                              .toInt(),
                          (140 -
                                  53 *
                                      (_stopwatch.elapsedMilliseconds /
                                          (_roundDuration * 1000)))
                              .toInt(),
                          (47 +
                                  18 *
                                      (_stopwatch.elapsedMilliseconds /
                                          (_roundDuration * 1000)))
                              .toInt(),
                          1, //_stopwatch.elapsedMilliseconds /(_roundDuration * 1000)
                        ))),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                /*const Text("Accelerometer:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              Text("x: ${ae.x.toStringAsFixed(4)} y: ${ae.y.toStringAsFixed(4)} z: ${ae.z.toStringAsFixed(4)}"),*/
                SizedBox(
                  height: (dontMove || goToStart) ? 500 : 150,
                  child: (dontMove || goToStart)
                      ? Stack(
                        children: <Widget>[
                          flutterMap(
                            mapController: _mapController,
                            context: context,
                            markerLat: _markerLat,
                            markerLng: _markerLng,
                            goalCoordinates: _goalCoordinates,
                            startZoneCoordinates: _startZoneCoordinates,
                            crystalCoordinates:
                                crystalballActivated ? (_crystalCoordinates) : [],
                            powerUpCoordinates: _currentPowerUpCoordinates),
                          Container(
                            margin: const EdgeInsets.all(8),
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  height: 40,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    ),
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 30,
                                        height: 30,
                                        margin: EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: (points >= 1) ? Image.asset("$pathImg/Coin.png", fit: BoxFit.cover,) : Container(),
                                      ),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        margin: EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: (points >= 2) ? Image.asset("$pathImg/Coin.png", fit: BoxFit.cover,) : Container(),
                                      ),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        margin: EdgeInsets.symmetric(horizontal: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: (points >= 2) ? Image.asset("$pathImg/Coin.png", fit: BoxFit.cover,) : Container(),
                                      ),
                                    ]
                                  ),
                                  ),
                                Image.asset("$pathImg/eye_open.png", fit: BoxFit.cover),
                                const SizedBox(height: 50, width: 120,),
                              ],
                            ),
                          ),
                        ],
                      )
                      : Image.asset("$pathImg/eye_closed.png",
                          fit: BoxFit.cover),
                ),
                Column(
                  children: [
                    Container(
                        margin: const EdgeInsets.only(top: 16.0),
                        child: Image.asset("$pathImg/strikeCounter_${movedLastRedLight ? "one" : (goToStart ? "two" : "no")}Strikes.png", fit: BoxFit.cover)),
                    Container(
                      height: 2,
                      width: 200,
                      color: Colors.white,
                    ),
                  ],
                ),
                dontMove
                    ? Stack(
                        alignment: AlignmentDirectional.center,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 35,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 5,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(10))),
                          ),
                          Positioned(
                              left: 70,
                              child: Container(
                                color: Color.fromRGBO(84, 140, 47, 1),
                                width: 4,
                                height: 25,
                              )),
                          Positioned(
                              right: 70,
                              child: Container(
                                color: Color.fromRGBO(84, 140, 47, 1),
                                width: 4,
                                height: 25,
                              )),
                          AnimatedContainer(
                            clipBehavior: Clip.none,
                            duration: const Duration(milliseconds: 200),
                            height: 20,
                            width: totalAe * 100,
                            color: Colors.amber,
                          ),
                        ],
                      )
                    : Container(),
                playing
                    ? goToStart
                        ? const Text("GO TO START",
                            style: TextStyle(fontSize: 36, color: Colors.amber))
                        : ((movedLastRedLight
                            ? const Text("ILLEGAL MOVE",
                                style: TextStyle(
                                    fontSize: 36, color: Colors.amber))
                            : ((dontMove)
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
                          if (inStart) {
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
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackbar);
                          }
                        },
                        child: const Text('Start Game',
                            style: TextStyle(fontSize: 18)),
                      ),
                Text(
                  "Points: $points",
                  style: const TextStyle(color: Colors.white),
                ),
                powerUpButtons(),
              ],
            ),
          ),
        ),
      )
    ]);
  }
}
