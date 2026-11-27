import 'package:flutter/material.dart';

import '../../domain/entities/monitoring_mode_entity.dart';

/// Ícones dos modos (Material Symbols Rounded). Todo ícone vem acompanhado
/// de texto; a coruja, e não um escudo, é quem representa segurança no Vigi.
abstract final class ModeIcons {
  /// As 12 opções que a pessoa pode escolher ao criar um modo.
  static const Map<String, ({IconData icon, String label})> options = {
    'walk': (icon: Icons.directions_walk_rounded, label: 'Caminhada'),
    'read': (icon: Icons.menu_book_rounded, label: 'Leitura'),
    'tv': (icon: Icons.tv_rounded, label: 'Televisão'),
    'cook': (icon: Icons.restaurant_rounded, label: 'Cozinha'),
    'garden': (icon: Icons.local_florist_rounded, label: 'Jardim'),
    'shop': (icon: Icons.shopping_cart_rounded, label: 'Compras'),
    'bus': (icon: Icons.directions_bus_rounded, label: 'Passeio'),
    'exercise': (icon: Icons.fitness_center_rounded, label: 'Exercício'),
    'pet': (icon: Icons.pets_rounded, label: 'Animal'),
    'health': (icon: Icons.medical_services_rounded, label: 'Consulta'),
    'visit': (icon: Icons.groups_rounded, label: 'Visita'),
    'other': (icon: Icons.schedule_rounded, label: 'Outro'),
  };

  static IconData of(MonitoringModeEntity mode) {
    if (mode.isSleep) return Icons.bedtime_rounded;
    if (mode.isShower) return Icons.shower_rounded;
    if (mode.isRoutine) return Icons.home_rounded;
    return options[mode.iconKey]?.icon ?? Icons.schedule_rounded;
  }
}
