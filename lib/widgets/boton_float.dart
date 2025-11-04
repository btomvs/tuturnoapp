import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class BotonFloatAuth extends StatelessWidget {
  const BotonFloatAuth({
    super.key,
    this.cerrarsesion = 'login',
    this.historial = 'registro',
    this.turno = 'iconos',
    this.onTapTurno,
    this.onTapHistorial,
    this.onTapLogin,
    this.heroTag = 'botonFloatAuth',
  });

  final String turno;
  final String cerrarsesion;
  final String historial;
  final VoidCallback? onTapTurno;
  final VoidCallback? onTapLogin;
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
        // ----- Boton de Cerrar Sesión -----
        SpeedDialChild(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.claro,
          shape: const CircleBorder(),
          child: const Icon(Icons.exit_to_app),
          label: 'Cerrar Sesión',
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          onTap: onTapLogin ?? () => Navigator.pushNamed(context, cerrarsesion),
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
              onTapHistorial ?? () => Navigator.pushNamed(context, historial),
        ),

        // ----- Modificar para que sea Turno -----
        SpeedDialChild(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.claro,
          shape: const CircleBorder(),
          child: const Icon(Icons.apps),
          label: 'Ir a Iconos',
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          onTap: onTapTurno ?? () => Navigator.pushNamed(context, turno),
        ),
      ],
    );
  }
}
