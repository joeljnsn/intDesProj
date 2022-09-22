import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';


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

  late AccelerometerEvent ae;

  late UserAccelerometerEvent uae;

  late GyroscopeEvent ge;

  late MagnetometerEvent me;

  @override
  initState() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        ae = event;
      });
    });
    /*userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        uae = event;
      });
    });*/
    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        ge = event;
      });
    });
    /*magnetometerEvents.listen((MagnetometerEvent event) {
      setState(() {
        me = event;
      });
    });*/

    ae = AccelerometerEvent(0, 0, 0);
    ge = GyroscopeEvent(0, 0, 0);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Text("Gyroscope:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            Text("x: ${ge.x.toStringAsFixed(4)} y: ${ge.y.toStringAsFixed(4)} z: ${ge.z.toStringAsFixed(4)}"),
          ],
        ),
      ),
    );
  }
}
