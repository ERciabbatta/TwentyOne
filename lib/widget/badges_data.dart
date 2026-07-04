import 'package:flutter/material.dart';

/// Modello di dati per un Badge.
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// Lista globale di tutti i badge sbloccabili dell'applicazione.
const List<BadgeModel> allBadges = [
  BadgeModel(
    id: 'inizio_forte',
    name: 'Inizio Forte',
    description: 'Raggiungi 3 giorni di streak consecutivi.',
    icon: Icons.flash_on_rounded,
  ),
  BadgeModel(
    id: 'costanza',
    name: 'Costanza',
    description: 'Raggiungi 7 giorni di streak consecutivi.',
    icon: Icons.event_available_rounded,
  ),
  BadgeModel(
    id: 'quasi_arrivato',
    name: 'Quasi Arrivato',
    description: 'Raggiungi 14 giorni di streak consecutivi.',
    icon: Icons.directions_run_rounded,
  ),
  BadgeModel(
    id: 'trionfo_21',
    name: 'Trionfo 21',
    description: 'Completa il ciclo dei 21 giorni.',
    icon: Icons.emoji_events_rounded,
  ),
  BadgeModel(
    id: 'mente_serena',
    name: 'Mente Serena',
    description: 'Esegui 3 check-in consecutivi con un mood positivo (Bene o Ottimo).',
    icon: Icons.spa_rounded,
  ),
  BadgeModel(
    id: 'riflessivo',
    name: 'Riflessivo',
    description: 'Scrivi almeno 5 note personali.',
    icon: Icons.edit_note_rounded,
  ),
];
