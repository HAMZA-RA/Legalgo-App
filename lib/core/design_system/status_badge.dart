import 'package:flutter/material.dart';
import 'package:legalgo_mobile/core/design_system/app_colors.dart';
import 'package:legalgo_mobile/core/design_system/app_radius.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.value, this.compact = false});

  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = statusBadgeColor(value);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: AppRadius.chip,
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        humanizeStatus(value),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

Color statusBadgeColor(String value) {
  final normalized = value.toLowerCase().trim();
  return switch (normalized) {
    'paid' ||
    'completed' ||
    'validated' ||
    'active' ||
    'approved' => AppColors.success,
    'pending' ||
    'pending_payment' ||
    'documents_requested' ||
    'past_due' ||
    'processing' => AppColors.warning,
    'failed' || 'rejected' || 'cancelled' || 'expired' => AppColors.danger,
    'in_progress' || 'under_review' || 'submitted' => AppColors.softIndigo,
    _ => AppColors.softIndigo,
  };
}

String humanizeStatus(String value) {
  final normalized = value.toLowerCase().trim();
  const labels = {
    'active': 'Actif',
    'inactive': 'Inactif',
    'admin': 'Administrateur',
    'client': 'Client',
    'paid': 'Payé',
    'pending': 'En attente',
    'pending_payment': 'Paiement en attente',
    'failed': 'Échoué',
    'cancelled': 'Annulé',
    'completed': 'Terminé',
    'processing': 'En traitement',
    'in_progress': 'En cours',
    'under_review': 'En vérification',
    'submitted': 'Envoyé',
    'documents_requested': 'Documents demandés',
    'documents_received': 'Documents reçus',
    'validated': 'Validé',
    'approved': 'Approuvé',
    'rejected': 'Rejeté',
    'expired': 'Expiré',
    'past_due': 'En retard',
    'overdue': 'Échu',
    'official_available': 'Document officiel disponible',
    'sent': 'Envoyé',
    'draft': 'Brouillon',
    'created': 'Création',
    'read_only': 'Lecture seule',
  };
  return labels[normalized] ??
      normalized
          .replaceAll('_', ' ')
          .split(' ')
          .map((part) {
            if (part.isEmpty) return part;
            return '${part[0].toUpperCase()}${part.substring(1)}';
          })
          .join(' ');
}
