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
          Text((time >= 3) ? "You win! :)" : "You lose :(", style: const TextStyle(color: Colors.white, fontSize: 22)),
        ],
      ),
    );
  }
}
