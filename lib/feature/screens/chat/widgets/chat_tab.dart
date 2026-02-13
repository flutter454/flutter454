import 'package:flutter/material.dart';

class ChatTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const ChatTab({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
