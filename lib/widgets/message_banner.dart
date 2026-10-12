import 'package:flutter/material.dart';

import '../theme.dart';

/// On-screen message (success or error) shown inside the page itself.
class MessageBanner extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onClose;

  const MessageBanner({
    super.key,
    required this.message,
    this.isError = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? kDanger : kSuccess;
    final bg = isError ? kDangerLight : kSuccessLight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (onClose != null)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 18, color: color),
              ),
            ),
        ],
      ),
    );
  }
}
