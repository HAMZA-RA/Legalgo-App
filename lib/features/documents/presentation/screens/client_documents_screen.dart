import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/download/download.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';

final clientDocumentsProvider = FutureProvider.autoDispose<List<LegalDocument>>(
  (ref) async {
    final requests = await ref
        .watch(legalGoRepositoryProvider)
        .fetchClientRequests();
    final payloads = await Future.wait(
      requests.map(
        (request) => ref
            .watch(legalGoRepositoryProvider)
            .fetchRequestDocuments(request.id),
      ),
    );
    return payloads.expand((payload) => payload.documents).toList();
  },
);

class ClientDocumentsScreen extends ConsumerWidget {
  const ClientDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(clientDocumentsProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: const PremiumAppBar(title: 'Documents'),
      body: documentsAsync.when(
        loading: () => const LoadingView(message: 'Chargement des documents'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(clientDocumentsProvider),
        ),
        data: (documents) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(clientDocumentsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xs,
                AppSpacing.screenHorizontal,
                AppSpacing.screenBottom,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 940),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.softIndigo.withValues(
                                    alpha: .10,
                                  ),
                                  borderRadius: AppRadius.icon,
                                ),
                                child: const Icon(
                                  Icons.folder_copy_outlined,
                                  color: AppColors.softIndigo,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Coffre documentaire',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      '${documents.length} fichier(s) liés à vos demandes LegalGo',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (documents.isEmpty)
                          const AppCard(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.xxxl,
                            ),
                            child: EmptyStateView(
                              icon: Icons.file_present_outlined,
                              title: 'Aucun document',
                              message:
                                  'Les documents liés à vos demandes apparaîtront ici.',
                            ),
                          )
                        else
                          _DocumentsList(
                            documents: documents,
                            onDownload: (document) =>
                                _download(context, ref, document),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    LegalDocument document,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref
          .read(legalGoRepositoryProvider)
          .downloadDocument(document);
      await saveDownloadedBytes(
        bytes: file.bytes,
        fileName: file.fileName,
        mimeType: file.mimeType,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? '${file.fileName} téléchargé'
                : 'Fichier enregistré dans Téléchargements',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(_downloadErrorMessage(error))),
      );
    }
  }
}

String _downloadErrorMessage(Object error) {
  if (error.toString().contains(
    'Fichier enregistré, mais aucune application compatible trouvée',
  )) {
    return 'Fichier enregistré, mais aucune application compatible trouvée';
  }
  return 'Échec du téléchargement';
}

class _DocumentsList extends StatelessWidget {
  const _DocumentsList({required this.documents, required this.onDownload});

  final List<LegalDocument> documents;
  final void Function(LegalDocument document) onDownload;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 820;
        if (!twoColumns) {
          return Column(
            children: [
              for (final document in documents) ...[
                _DocumentCard(document: document, onDownload: onDownload),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final document in documents)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.md) / 2,
                child: _DocumentCard(
                  document: document,
                  onDownload: onDownload,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.onDownload});

  final LegalDocument document;
  final void Function(LegalDocument document) onDownload;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.softIndigo.withValues(alpha: .10),
              borderRadius: AppRadius.icon,
            ),
            child: const Icon(
              Icons.description_outlined,
              color: AppColors.softIndigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    StatusBadge(value: document.status, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  document.originalName ?? document.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          if (document.canDownload)
            IconButton(
              tooltip: 'Télécharger',
              icon: const Icon(Icons.download_rounded),
              color: AppColors.softIndigo,
              onPressed: () => onDownload(document),
            ),
        ],
      ),
    );
  }
}
