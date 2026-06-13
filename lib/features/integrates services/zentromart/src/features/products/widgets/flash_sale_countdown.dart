import 'dart:async';
import 'package:flutter/material.dart';

class FlashSaleCountdown extends StatefulWidget {
  final DateTime closingTime;

  const FlashSaleCountdown({super.key, required this.closingTime});

  @override
  State<FlashSaleCountdown> createState() => _FlashSaleCountdownState();
}

class _FlashSaleCountdownState extends State<FlashSaleCountdown> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.closingTime.isBefore(now)) {
      setState(() {
        _timeLeft = Duration.zero;
        _timer.cancel();
      });
    } else {
      setState(() {
        _timeLeft = widget.closingTime.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatNumber(int number) {
    return number.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return const Text(
        "Sale Ended",
        style: TextStyle(
            color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
      );
    }

    final hours = _formatNumber(_timeLeft.inHours);
    final minutes = _formatNumber(_timeLeft.inMinutes.remainder(60));
    final seconds = _formatNumber(_timeLeft.inSeconds.remainder(60));

    return Row(
      children: [
        const Text("Ends In ",
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        _buildTimeBlock(hours),
        const Text(" : ",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.redAccent)),
        _buildTimeBlock(minutes),
        const Text(" : ",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.redAccent)),
        _buildTimeBlock(seconds),
      ],
    );
  }

  Widget _buildTimeBlock(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.shade100.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight
              .w900, // FIXED: Changed from FontWeight.black to FontWeight.w900
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
