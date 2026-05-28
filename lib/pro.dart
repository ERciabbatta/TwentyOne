import 'package:flutter/material.dart';

class Pro extends StatefulWidget {
  const Pro({super.key});

  @override
  State<Pro> createState() => _ProState();
}

class _ProState extends State<Pro> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: const Center(
        child: Text(
          "Pro",
        ),
      ),
    );
  }
}
