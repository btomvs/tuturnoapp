import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class BotonFloatAuth extends StatelessWidget {
  const BotonFloatAuth({
    super.key,
    this.cerrarsesion = 'login',
    this.historial = 'historial',
    this.turno = 'turno',
    this.onTapTurno,
    this.onTapHistorial,
    this.onTapLogin,
    this.heroTag = 'botonFloatAuth',
    this.confirmLogout = true,
    this.mini = false,
    this.elevation,
    this.overlayColor,
  });

  // Rutas
  final String turno;
  final String cerrarsesion;
  final String historial;

  // Callbacks (si los provees, se usan en vez de navegar por ruta)
  final VoidCallback? onTapTurno;
  final VoidCallback? onTapLogin;
  final VoidCallback? onTapHistorial;

  // Opciones visuales/comportamiento
  final String heroTag;
  final bool confirmLogout;
  final bool mini;
  final double? elevation;
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    SpeedDialChild _buildChild({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      String? tooltip,
    }) {
      return SpeedDialChild(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.claro,
        shape: const CircleBorder(),
        child: Icon(icon),
        label: label,
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        onTap: onTap,
        elevation: elevation,
        labelShadow: [],
      );
    }

    Future<void> _safePushNamed(BuildContext ctx, String route) async {
      final can =
          Navigator.of(ctx).canPop() || (ModalRoute.of(ctx)?.isCurrent ?? true);
      final routes = Navigator.of(ctx);
      try {
        await routes.pushNamed(route);
      } catch (_) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Ruta "$route" no encontrada')));
      }
    }

    Future<void> _handleCerrarSesion(BuildContext ctx) async {
      if (onTapLogin != null) {
        onTapLogin!();
        return;
      }
      if (confirmLogout) {
        final ok = await showDialog<bool>(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Seguro que quieres cerrar tu sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dCtx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dCtx).pop(true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
      await _safePushNamed(ctx, cerrarsesion);
    }

    return Semantics(
      label: 'Menú rápido',
      button: true,
      child: SpeedDial(
        heroTag: heroTag,
        icon: Icons.add,
        activeIcon: Icons.close,
        spacing: 5,
        spaceBetweenChildren: 5,
        overlayOpacity: 0.15,
        overlayColor: overlayColor,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.claro,
        childrenButtonSize: mini ? const Size(42, 42) : const Size(56, 56),
        children: [
          // ----- Cerrar Sesión -----
          _buildChild(
            icon: Icons.exit_to_app,
            label: 'Cerrar Sesión',
            onTap: () => _handleCerrarSesion(context),
          ),

          // ----- Historial -----
          _buildChild(
            icon: Icons.history,
            label: 'Historial',
            onTap: onTapHistorial ?? () => _safePushNamed(context, historial),
          ),

          // ----- Turnos -----
          _buildChild(
            icon: Icons.calendar_month,
            label: 'Turnos',
            onTap: onTapTurno ?? () => _safePushNamed(context, turno),
          ),
        ],
      ),
    );
  }
}
