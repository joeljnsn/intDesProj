import 'package:flutter/material.dart';
import 'package:indesproj/main.dart';

class EndPage extends StatelessWidget {

  final int score;

  const EndPage(this.score, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: <Widget>[
          Text("Goal!!! Your score was $score", style: const TextStyle(color: Colors.white)),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all<Color>(Colors.amber),
            ),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const MyHomePage(),
                ),
              );
            },
            child: const Text('Play again'),
          )
        ],
      ),
    );
  }
}