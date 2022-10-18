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
      body: Center(
          child: TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.amber),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.white30)
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MyHomePage(),
                ),
              );
            },
            child: const Text('Play', style: TextStyle(fontSize: 24)),
          )

      ),
    );
  }
}