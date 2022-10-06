import 'package:flutter/material.dart';
import 'package:indesproj/main.dart';

class EndPage extends StatelessWidget {
  final int time;

  const EndPage(this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("Goal!!!", style: const TextStyle(color: Colors.white)),
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
