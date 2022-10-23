import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:indesproj/main.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});


  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
        Stack(children: [
          Image.asset("assets/backGround_image.png",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.all(16),
                child: Image.asset("assets/logo.png", fit: BoxFit.cover)),
              TextButton(
                style: ButtonStyle(
                  foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.white),
                  backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.blue),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MyHomePage(),
                    ),
                  );
                },
                child: const Text('Play', style: TextStyle(fontSize: 24)),
              ),
            ],
          )
        ),
        ]),
    );
  }
}