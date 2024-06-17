import 'package:flutter/material.dart';

class PulsingMicIcon extends StatefulWidget {
  const PulsingMicIcon({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PulsingMicIconState createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Transform.scale(
          scale: _animation.value,
          child: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade700,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 50),
          ),
        ),
      );
}



  // Widget _buildSpeakNow() => SizedBox(
  //       height: 100,
  //       child: ElevatedButton(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.blue.shade700,
  //           padding: EdgeInsets.zero,
  //           shape: const RoundedRectangleBorder(),
  //         ),
  //         onPressed: () {},
  //         child: const Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.mic, color: Colors.white),
  //             Text('Speak Now', style: TextStyle(color: Colors.white)),
  //           ],
  //         ),
  //       ),
  //     );
