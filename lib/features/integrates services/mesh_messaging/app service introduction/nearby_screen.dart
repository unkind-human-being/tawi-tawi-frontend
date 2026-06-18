import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'chat_screen.dart';
import '../../../../core/channels/app_channels.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  List<String> _devices = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    // Poll the mesh state every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchDevices();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final List<dynamic> result = await AppChannels.messaging.invokeMethod('getNearbyDevices');
      setState(() {
        _devices = result.cast<String>();
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to get nearby devices: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        title: Text(
          'Nearby Devices',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: _devices.isEmpty || (_devices.length == 1 && _devices[0].contains('Searching'))
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_tethering_rounded, size: 80, color: const Color(0xFF0F766E).withOpacity(0.5)),
                  const SizedBox(height: 24),
                  Text(
                    _devices.isEmpty ? 'Starting mesh network...' : _devices[0],
                    style: TextStyle(color: textMuted, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final rawString = _devices[index];
                if (!rawString.contains(':::')) {
                  return const SizedBox.shrink();
                }
                
                final parts = rawString.split(':::');
                final threadId = parts[0];
                final displayName = parts[1];

                return Card(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0F766E).withOpacity(0.1),
                      child: const Icon(Icons.smartphone_rounded, color: Color(0xFF0F766E)),
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              threadId: threadId,
                              displayName: displayName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Message'),
                    ),
                  ),
                );
              },
            ),
    );
  }

}
