import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/download/download.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

final clientDocumentsProvider = FutureProvider.autoDispose<List<LegalDocument>>((ref) async {
  final requests = await ref.watch(legalGoRepositoryProvider).fetchClientRequests();
  final payloads = await Future.wait(requests.map((request) => ref.watch(legalGoRepositoryProvider).fetchRequestDocuments(request.id)));
  return payloads.expand((payload) => payload.documents).toList();
});

class ClientDocumentsScreen extends ConsumerWidget {
  const ClientDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(clientDocumentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: documentsAsync.when(
        loading: () => const LoadingView(message: 'Loading documents'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(clientDocumentsProvider)),
        data: (documents) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(clientDocumentsProvider),
          child: documents.isEmpty
              ? const EmptyStateView(icon: Icons.file_present_outlined, title: 'No documents', message: 'Documents attached to your requests will appear here.')
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: documents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(document.title),
                        subtitle: Text('${humanStatus(document.status)} • ${document.originalName ?? document.type}'),
                        trailing: document.canDownload
                            ? IconButton(
                                icon: const Icon(Icons.download_rounded),
                                onPressed: () => _download(context, ref, document),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref, LegalDocument document) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ref.read(legalGoRepositoryProvider).downloadDocument(document);
      await saveDownloadedBytes(bytes: file.bytes, fileName: file.fileName, mimeType: file.mimeType);
      messenger.showSnackBar(SnackBar(content: Text('Downloaded ${file.fileName}')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $error')));
    }
  }
}

