import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legalgo_mobile/core/download/download.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';

class RequestDetailsScreen extends ConsumerWidget {
  const RequestDetailsScreen({super.key, required this.requestId, required this.admin});

  final String requestId;
  final bool admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(requestDetailsProvider(requestId));
    final docsAsync = ref.watch(requestDocumentsProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: Text(admin ? 'Request Details' : 'My Request')),
      body: requestAsync.when(
        loading: () => const LoadingView(message: 'Loading request'),
        error: (error, _) => ErrorStateView(message: error.toString(), onRetry: () => ref.invalidate(requestDetailsProvider(requestId))),
        data: (request) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(requestDetailsProvider(requestId));
            ref.invalidate(requestDocumentsProvider(requestId));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Summary(request: request),
              const SizedBox(height: 14),
              _PackInfo(request: request),
              const SizedBox(height: 14),
              _Timeline(history: request.statusHistory),
              const SizedBox(height: 14),
              docsAsync.when(
                loading: () => const Card(child: Padding(padding: EdgeInsets.all(18), child: LinearProgressIndicator())),
                error: (error, _) => Card(child: ListTile(leading: const Icon(Icons.error_outline), title: Text(error.toString()))),
                data: (payload) => _DocumentsCard(documents: payload.documents, requiredDocuments: payload.requiredDocuments),
              ),
              const SizedBox(height: 14),
              _AnswersCard(answers: request.answers),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.reference, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(request.service?.title ?? 'Service unavailable'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [StatusChip(value: request.status), StatusChip(value: request.paymentStatus)]),
          const SizedBox(height: 12),
          Text('Created: ${compactDate(request.createdAt)}'),
          Text('Total: ${money(request.totalPrice)}'),
          if (request.customerEmail != null) Text('Customer: ${request.customerEmail}'),
        ]),
      ),
    );
  }
}

class _PackInfo extends StatelessWidget {
  const _PackInfo({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    final pack = request.pack;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inventory_2_outlined),
        title: Text(pack?.title ?? 'No pack'),
        subtitle: Text(pack == null ? 'Pack information is unavailable.' : '${money(pack.price)} • ${pack.delayDays} day(s)'),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.history});

  final List<RequestStatusHistory> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Timeline', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text('No status history available.')
          else
            for (final item in history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded),
                title: Text('${humanStatus(item.oldStatus ?? 'created')} → ${humanStatus(item.newStatus)}'),
                subtitle: Text([compactDate(item.createdAt), item.reason].whereType<String>().join(' • ')),
              ),
        ]),
      ),
    );
  }
}

class _DocumentsCard extends ConsumerWidget {
  const _DocumentsCard({required this.documents, required this.requiredDocuments});

  final List<LegalDocument> documents;
  final List<ServiceRequiredDocument> requiredDocuments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Documents', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (requiredDocuments.isNotEmpty) Text('${requiredDocuments.length} required document(s)', style: Theme.of(context).textTheme.bodySmall),
          if (documents.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 12), child: Text('No uploaded documents yet.'))
          else
            for (final document in documents)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file_rounded),
                title: Text(document.title),
                subtitle: Text('${humanStatus(document.status)} • ${document.originalName ?? document.type}'),
                trailing: document.canDownload ? IconButton(icon: const Icon(Icons.download_rounded), onPressed: () => _download(context, ref, document)) : null,
              ),
        ]),
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

class _AnswersCard extends StatelessWidget {
  const _AnswersCard({required this.answers});

  final List<RequestAnswer> answers;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Answers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (answers.isEmpty)
            const Text('No answers attached to this request.')
          else
            for (final answer in answers)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(answer.fieldName), subtitle: Text(answer.fieldValue ?? '-')),
        ]),
      ),
    );
  }
}
