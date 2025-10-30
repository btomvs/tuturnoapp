import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.radius,
    this.imageFile,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.showEditBadge = true,
    this.editBadgeColor,
    this.editIconColor,
  });

  final double radius;
  final File? imageFile;
  final VoidCallback? onTap;

  final Color? backgroundColor;
  final Color? iconColor;

  final bool showEditBadge;
  final Color? editBadgeColor;
  final Color? editIconColor;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
      backgroundImage: imageFile != null ? FileImage(imageFile!) : null,
      child: imageFile == null
          ? Icon(
              Icons.account_circle,
              size: radius * 2 * 0.9,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
            )
          : null,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          if (showEditBadge)
            Container(
              decoration: BoxDecoration(
                color: editBadgeColor ?? Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.oscuro,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.edit,
                size: 18,
                color: editIconColor ?? AppColors.claro,
              ),
            ),
        ],
      ),
    );
  }
}
