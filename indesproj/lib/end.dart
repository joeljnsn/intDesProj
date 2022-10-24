import 'package:flutter/material.dart';
import 'package:indesproj/main.dart';

class EndPage extends StatelessWidget {
  final int time;

  const EndPage(this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Text("Game ended", style: TextStyle(color: Colors.white, fontSize: 22))),
    );
  }
}
