import 'package:flutter/material.dart';
import 'package:tuturnoapp/core/app_colors.dart';

class BotonEntrada extends StatelessWidget {
  const BotonEntrada({
    super.key,
    required this.onEntrada,
    required this.onSalida,
    this.altura = 55,
    this.separacion = 25,
    this.borderRadius = 55,
    this.labelEntrada = 'Entrada',
    this.labelSalida = 'Salida',
    this.iconEntrada,
    this.iconSalida,
  });

  final VoidCallback onEntrada;
  final VoidCallback onSalida;

  final double altura;
  final double separacion;
  final double borderRadius;

  final String labelEntrada;
  final String labelSalida;
  final IconData? iconEntrada;
  final IconData? iconSalida;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget buildFilled(
      String label,
      IconData? icon,
      VoidCallback onTap, {
      required Color bg,
      required Color fg,
    }) {
      final child = icon == null
          ? Text(label, style: const TextStyle(fontWeight: FontWeight.w600))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            );

      return SizedBox(
        height: altura,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: AppColors.claro,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return Row(
      children: [
        // ----- Boton Entrada -----
        Expanded(
          child: buildFilled(
            labelEntrada,
            iconEntrada,
            onEntrada,
            bg: AppColors.secondary,
            fg: scheme.onPrimary,
          ),
        ),
        SizedBox(width: separacion),
        // ----- Boton Salida -----
        Expanded(
          child: buildFilled(
            labelSalida,
            iconSalida,
            onSalida,
            bg: Colors.deepOrange,
            fg: scheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}
