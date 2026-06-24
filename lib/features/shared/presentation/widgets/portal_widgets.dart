import 'package:flutter/material.dart';

String money(String? value) {
  final amount = num.tryParse(value ?? '') ?? 0;
  return '${amount.toStringAsFixed(2)} EUR';
}

String compactDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String humanStatus(String value) {
  const labels = {
    'active': 'Actif',
    'inactive': 'Inactif',
    'paid': 'Payé',
    'pending': 'En attente',
    'pending_payment': 'Paiement en attente',
    'failed': 'Échoué',
    'cancelled': 'Annulé',
    'completed': 'Terminé',
    'processing': 'En traitement',
    'documents_requested': 'Documents demandés',
    'documents_received': 'Documents reçus',
    'validated': 'Validé',
    'rejected': 'Rejeté',
    'expired': 'Expiré',
    'past_due': 'En retard',
    'official_available': 'Document officiel disponible',
    'sent': 'Envoyé',
    'draft': 'Brouillon',
    'created': 'Création',
  };
  final normalized = value.toLowerCase().trim();
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

Color statusColor(BuildContext context, String value) {
  final scheme = Theme.of(context).colorScheme;
  return switch (value) {
    'paid' || 'completed' || 'validated' || 'active' => Colors.green.shade700,
    'pending' ||
    'pending_payment' ||
    'documents_requested' ||
    'past_due' => Colors.orange.shade800,
    'failed' || 'rejected' || 'cancelled' || 'expired' => scheme.error,
    _ => scheme.primary,
  };
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 14),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, value);
    return Chip(
      label: Text(humanStatus(value)),
      side: BorderSide(color: color.withValues(alpha: .25)),
      backgroundColor: color.withValues(alpha: .10),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 180,
  });

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          childAspectRatio: 1.35,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: children,
        );
      },
    );
  }
}
