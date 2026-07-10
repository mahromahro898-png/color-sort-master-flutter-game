import 'package:flutter/material.dart';

class PourAnimationLayer extends StatelessWidget {
  final bool isVisible;

  const PourAnimationLayer({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: Container(
          width: 8,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7DD3FC),
                Color(0xFF38BDF8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}