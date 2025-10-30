import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class BotonFloatAuth extends StatelessWidget {
  const BotonFloatAuth({
    super.key,
    this.configuraciones = 'iconos',
    this.registerRoute = 'register',
    //this.configuraciones = 'iconos',
    this.onTapConfiguraciones,
    this.onTapHistorial,
    this.heroTag = 'botonFloatAuth',
  });

  final String configuraciones;
  final String registerRoute;
  final VoidCallback? onTapConfiguraciones;
  final VoidCallback? onTapHistorial;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SpeedDial(
      heroTag: heroTag,
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 5,
      spaceBetweenChildren: 5,
      overlayOpacity: 0.15,
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.claro,
      children: [
        // ----- Modificar para que vaya a Configuraciones -----
        SpeedDialChild(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.claro,
          shape: const CircleBorder(),
          child: const Icon(Icons.more_vert),
          label: 'Más',
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          onTap:
              onTapConfiguraciones ??
              () => Navigator.pushNamed(context, configuraciones),
        ),

        // ----- Modificar para ir a Historial -----
        SpeedDialChild(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.claro,
          shape: const CircleBorder(),
          child: const Icon(Icons.history),
          label: 'Ir a Historial',
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          onTap:
              onTapHistorial ??
              () => Navigator.pushNamed(context, registerRoute),
        ),

        // ----- Eliminar debido que es para visualizar los iconos -----
        SpeedDialChild(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.claro,
          shape: const CircleBorder(),
          child: const Icon(Icons.apps),
          label: 'Ir a Iconos',
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          onTap:
              onTapHistorial ??
              () => Navigator.pushNamed(context, configuraciones),
        ),
      ],
    );
  }
}
