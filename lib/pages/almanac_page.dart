// lib/pages/almanac_page.dart
import 'package:flutter/material.dart';
import '../data/plant_info.dart' show plantInfo;

class AlmanacPage extends StatelessWidget {
  const AlmanacPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = plantInfo.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Almanac"),
        backgroundColor: const Color(0xFF456F1F),
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final data = entries[index].value;
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(data['name']),
              subtitle: Text(data['scientific']),
            ),
          );
        },
      ),
    );
  }
}