import 'package:flutter/material.dart';

class SettingItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? titleBadge;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingItemTile({
    super.key,
    required this.icon,
    required this.title,
    this.titleBadge,
    this.subtitle,
    this.subtitleWidget,
    this.trailingWidget,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.grey.shade700).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.grey.shade700,
          size: 22,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (titleBadge != null) ...[
            const SizedBox(width: 8),
            titleBadge!,
          ],
        ],
      ),
      subtitle: subtitleWidget ?? (subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            )
          : null),
      trailing: trailingWidget ??
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
          ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
