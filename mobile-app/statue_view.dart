import 'package:flutter/material.dart';

class ScooterStatusView extends StatelessWidget {
  final String? connectedId;
  final VoidCallback onTap;

  const ScooterStatusView({super.key, this.connectedId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isConnected = connectedId != null && connectedId!.isNotEmpty;

    return GestureDetector(
      // 투명한 빈 공간을 눌러도 클릭이 인식되게 합니다.
      behavior: HitTestBehavior.opaque,
      onTap: isConnected ? null : onTap,
      child: Container(
        // 클릭 영역을 가로로 길게 확장하여 터치가 잘 되게 합니다.
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          isConnected ? "연결됨: $connectedId" : "연결된 킥보드가 없습니다. (Click)",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isConnected ? Colors.black : Colors.red,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            decoration: isConnected
                ? TextDecoration.none
                : TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
