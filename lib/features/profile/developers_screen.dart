import 'package:flutter/material.dart';

class DevelopersScreen extends StatelessWidget {
  const DevelopersScreen({super.key});

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Widget _buildTeam(BuildContext context, String teamName, List<String> members) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_work_outlined, 
                     size: 20, 
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  teamName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...members.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _toTitleCase(m),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developers'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'The Masterminds',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Meet the brilliant teams behind this application:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          
          _buildTeam(context, 'LakbAi', [
            'Jericho L. Kohoyan',
            'Alnedzfar N. Sanaani',
            'Hazrazee Sadhan A. Daing',
          ]),
          
          _buildTeam(context, 'Reach', [
            'Rhayan Lodovice',
            'Ethel Von Inrich Lawan',
            'Rayhan Suaib',
          ]),
          
          _buildTeam(context, 'ZentroMart', [
            'Alih A. Marajani',
            'Erwyne A. Basil',
            'Chriska Ubbama',
          ]),
          
          _buildTeam(context, 'PAMEYAAN', [
            'SUALDEN SALA',
            'RASMAN JULSALI',
            'RAYAN KEN BAGUIO',
          ]),
          
          _buildTeam(context, 'TDLF-Educ', [
            'Abdu, Kamrashier Imlani',
            'Jumad, Harsamer Rabah',
            'Isbala, Ali-Risha Marjukin',
          ]),
          
          _buildTeam(context, 'SOCIAL HEALTH UPDATE', [
            'ALNADZMEN SALLIL',
            'DYZON CHIONG',
            'ABDUL NASIRIN',
          ]),
          
          _buildTeam(context, 'HanapGawa', [
            'Raizha Ajul',
            'Sandara Tadus',
            'Fatima Reedzqha Asaad',
          ]),
        ],
      ),
    );
  }
}

