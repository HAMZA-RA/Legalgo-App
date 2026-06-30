import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:legalgo_mobile/core/design_system/design_system.dart';
import 'package:legalgo_mobile/core/download/download.dart';
import 'package:legalgo_mobile/core/widgets/state_views.dart';
import 'package:legalgo_mobile/features/shared/data/legalgo_repository.dart';
import 'package:legalgo_mobile/features/shared/domain/legalgo_models.dart';
import 'package:legalgo_mobile/features/shared/presentation/providers/legalgo_providers.dart';
import 'package:legalgo_mobile/features/shared/presentation/widgets/portal_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailsScreen extends ConsumerStatefulWidget {
  const RequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.admin,
  });

  final String requestId;
  final bool admin;

  @override
  ConsumerState<RequestDetailsScreen> createState() =>
      _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen>
    with WidgetsBindingObserver {
  static const _allowedExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
  };
  static const _maxUploadBytes = 10 * 1024 * 1024;
  static const _mimeTypes = {
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  String? _requestAction;
  String? _documentActionId;
  String? _uploadingDocumentKey;
  String? _paymentActionState;
  bool _requestingDocument = false;
  bool _checkoutAwaitingReturn = false;
  bool _checkoutLeftForeground = false;
  bool _paymentRefreshInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_checkoutAwaitingReturn) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _checkoutLeftForeground = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _checkoutLeftForeground) {
      _checkoutAwaitingReturn = false;
      _checkoutLeftForeground = false;
      _refreshPaymentState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(requestDetailsProvider(widget.requestId));
    final docsAsync = ref.watch(requestDocumentsProvider(widget.requestId));
    return Scaffold(
      backgroundColor: AppColors.pageBackground(context),
      appBar: PremiumAppBar(
        title: 'Détail de la demande',
        onBack: () =>
            context.go(widget.admin ? '/admin/requests' : '/client/requests'),
      ),
      body: requestAsync.when(
        loading: () => const LoadingView(message: 'Chargement de la demande'),
        error: (error, _) => ErrorStateView(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(requestDetailsProvider(widget.requestId)),
        ),
        data: (request) => RefreshIndicator(
          onRefresh: _refresh,
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
                      _Summary(request: request),
                      if (!widget.admin && _canStartCheckout(request)) ...[
                        const SizedBox(height: AppSpacing.md),
                        _PaymentActionCard(
                          request: request,
                          actionState: _paymentActionState,
                          onPressed: () => _startCheckout(request),
                        ),
                      ],
                      if (widget.admin) ...[
                        const SizedBox(height: AppSpacing.md),
                        docsAsync.when(
                          loading: () =>
                              const AppCard(child: LinearProgressIndicator()),
                          error: (_, _) => _AdminRequestActions(
                            request: request,
                            documentsReady: false,
                            allRequiredDocumentsValidated: false,
                            loadingAction: _requestAction,
                            onComplete: null,
                            onReject: _canReject(request)
                                ? () => _changeRequestWithReason(
                                    request,
                                    status: 'rejected',
                                  )
                                : null,
                            onCancel: _canCancel(request)
                                ? () => _changeRequestWithReason(
                                    request,
                                    status: 'cancelled',
                                  )
                                : null,
                          ),
                          data: (payload) {
                            final allValidated = _allRequiredDocumentsValidated(
                              payload,
                            );
                            return _AdminRequestActions(
                              request: request,
                              documentsReady: true,
                              allRequiredDocumentsValidated: allValidated,
                              loadingAction: _requestAction,
                              onComplete: _canComplete(request, allValidated)
                                  ? () => _completeRequest(request)
                                  : null,
                              onReject: _canReject(request)
                                  ? () => _changeRequestWithReason(
                                      request,
                                      status: 'rejected',
                                    )
                                  : null,
                              onCancel: _canCancel(request)
                                  ? () => _changeRequestWithReason(
                                      request,
                                      status: 'cancelled',
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _ResponsiveDetailsGrid(
                        left: Column(
                          children: [
                            _PackInfo(request: request),
                            const SizedBox(height: AppSpacing.md),
                            _Timeline(history: request.statusHistory),
                          ],
                        ),
                        right: Column(
                          children: [
                            docsAsync.when(
                              loading: () => const AppCard(
                                child: LinearProgressIndicator(),
                              ),
                              error: (error, _) => AppCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.error_outline),
                                  title: Text(error.toString()),
                                ),
                              ),
                              data: (payload) => _DocumentsCard(
                                admin: widget.admin,
                                requestStatus: request.status,
                                documents: payload.documents,
                                requiredDocuments: payload.requiredDocuments,
                                loadingDocumentId: _documentActionId,
                                uploadingDocumentKey: _uploadingDocumentKey,
                                requestingDocument: _requestingDocument,
                                onValidate: _validateDocument,
                                onReject: _rejectDocument,
                                onRequestDocument: () =>
                                    _requestMissingDocument(request),
                                onUploadRequired: widget.admin
                                    ? null
                                    : _uploadRequiredDocument,
                                onUploadDocument: widget.admin
                                    ? null
                                    : _uploadExistingDocument,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _AnswersCard(answers: request.answers),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(requestDetailsProvider(widget.requestId).future),
      ref.refresh(requestDocumentsProvider(widget.requestId).future),
    ]);
    ref.invalidate(adminRequestsProvider);
  }

  bool _canStartCheckout(LegalRequest request) {
    final finalRequest = const {
      'completed',
      'rejected',
      'cancelled',
    }.contains(request.status);
    return !finalRequest &&
        const {
          'pending',
          'failed',
          'cancelled',
        }.contains(request.paymentStatus);
  }

  Future<void> _startCheckout(LegalRequest request) async {
    if (_paymentActionState != null) return;

    setState(() => _paymentActionState = 'creating');
    final messenger = ScaffoldMessenger.of(context);
    try {
      final checkout = await ref
          .read(legalGoRepositoryProvider)
          .createRequestCheckoutSession(request.id);
      if (!mounted) return;

      setState(() => _paymentActionState = 'opening');
      _checkoutAwaitingReturn = true;
      _checkoutLeftForeground = false;
      final launched = await launchUrl(
        Uri.parse(checkout.checkoutUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
      );
      if (!launched) {
        _checkoutAwaitingReturn = false;
        throw const PaymentCheckoutException(
          'Impossible de démarrer le paiement',
        );
      }
      if (kIsWeb) {
        Future<void>.delayed(const Duration(seconds: 3), () async {
          if (!mounted) return;
          await _refreshPaymentState();
        });
      }
    } catch (error) {
      _checkoutAwaitingReturn = false;
      if (!mounted) return;
      final message = error is PaymentCheckoutException
          ? error.message
          : 'Impossible de démarrer le paiement';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _paymentActionState = null);
    }
  }

  Future<void> _refreshPaymentState() async {
    if (_paymentRefreshInProgress || !mounted) return;
    _paymentRefreshInProgress = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final results = await Future.wait<Object?>([
        ref.refresh(requestDetailsProvider(widget.requestId).future),
        ref.refresh(clientRequestsProvider.future),
        ref.refresh(clientPaymentsProvider.future),
      ]);
      if (!mounted) return;
      final request = results.first as LegalRequest;
      if (request.paymentStatus == 'paid') {
        messenger.showSnackBar(
          const SnackBar(content: Text('Paiement confirmé')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible de démarrer le paiement')),
      );
    } finally {
      _paymentRefreshInProgress = false;
    }
  }

  bool _allRequiredDocumentsValidated(RequestDocumentsPayload payload) {
    final required = payload.requiredDocuments.where(
      (document) => document.active && document.isRequired,
    );
    return required.every(
      (requiredDocument) => payload.documents.any(
        (document) =>
            document.serviceRequiredDocumentId == requiredDocument.id &&
            document.status == 'validated',
      ),
    );
  }

  bool _canComplete(LegalRequest request, bool allValidated) {
    return request.status == 'processing' &&
        request.paymentStatus == 'paid' &&
        allValidated;
  }

  bool _canReject(LegalRequest request) {
    return const {
      'documents_requested',
      'documents_received',
      'processing',
    }.contains(request.status);
  }

  bool _canCancel(LegalRequest request) {
    return const {
      'draft',
      'pending_payment',
      'documents_requested',
      'documents_received',
      'processing',
    }.contains(request.status);
  }

  Future<void> _completeRequest(LegalRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer ce dossier ?'),
        content: const Text(
          'Le dossier sera marqué comme terminé et le client sera notifié.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateRequestStatus(request.id, 'completed');
    }
  }

  Future<void> _changeRequestWithReason(
    LegalRequest request, {
    required String status,
  }) async {
    final rejected = status == 'rejected';
    final reason = await _askForReason(
      title: rejected ? 'Motif du rejet' : 'Motif d’annulation',
      actionLabel: rejected ? 'Rejeter' : 'Annuler la demande',
    );
    if (reason == null || !mounted) return;
    await _updateRequestStatus(request.id, status, reason: reason);
  }

  Future<String?> _askForReason({
    required String title,
    required String actionLabel,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _ReasonDialog(title: title, actionLabel: actionLabel),
    );
  }

  Future<void> _updateRequestStatus(
    String requestId,
    String status, {
    String? reason,
  }) async {
    setState(() => _requestAction = status);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(legalGoRepositoryProvider)
          .updateRequestStatus(requestId, status, reason: reason);
      await _refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Statut de la demande mis à jour.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(backendResponseBody(error))),
      );
    } finally {
      if (mounted) setState(() => _requestAction = null);
    }
  }

  Future<void> _validateDocument(LegalDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider le document ?'),
        content: Text(
          'Le document « ${document.title} » sera validé et le client sera notifié.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _updateDocumentStatus(document, 'validated');
  }

  Future<void> _rejectDocument(LegalDocument document) async {
    final reason = await _askForReason(
      title: 'Rejeter le document',
      actionLabel: 'Rejeter',
    );
    if (reason == null) return;
    await _updateDocumentStatus(document, 'rejected', rejectionReason: reason);
  }

  Future<void> _updateDocumentStatus(
    LegalDocument document,
    String status, {
    String? rejectionReason,
  }) async {
    setState(() => _documentActionId = document.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(legalGoRepositoryProvider)
          .updateDocumentStatus(
            document.id,
            status,
            rejectionReason: rejectionReason,
          );
      await _refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'validated'
                ? 'Document validé. Le client a été notifié.'
                : 'Document rejeté. Le client a été notifié.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(backendResponseBody(error))),
      );
    } finally {
      if (mounted) setState(() => _documentActionId = null);
    }
  }

  Future<void> _requestMissingDocument(LegalRequest request) async {
    final payload = await _showRequestDocumentDialog();
    if (payload == null || !mounted) return;

    setState(() => _requestingDocument = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(legalGoRepositoryProvider)
          .requestDocument(
            requestId: request.id,
            title: payload.title,
            type: payload.type,
            message: payload.message,
          );
      await _refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('Demande de document envoyée.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(backendResponseBody(error))),
      );
    } finally {
      if (mounted) setState(() => _requestingDocument = false);
    }
  }

  Future<void> _uploadRequiredDocument(
    ServiceRequiredDocument requiredDocument,
  ) {
    return _pickAndUploadDocument(
      targetKey: 'required:${requiredDocument.id}',
      title: requiredDocument.title,
      type: requiredDocument.category,
      requiredDocumentId: requiredDocument.id,
    );
  }

  Future<void> _uploadExistingDocument(LegalDocument document) {
    return _pickAndUploadDocument(
      targetKey: 'document:${document.id}',
      title: document.title,
      type: document.type,
      requiredDocumentId: document.serviceRequiredDocumentId,
    );
  }

  Future<void> _pickAndUploadDocument({
    required String targetKey,
    required String title,
    required String type,
    String? requiredDocumentId,
  }) async {
    if (_uploadingDocumentKey != null) return;

    setState(() => _uploadingDocumentKey = targetKey);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions.toList(),
        allowMultiple: false,
        withData: true,
      );
      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aucun fichier sélectionné')),
        );
        return;
      }

      final file = result.files.single;
      final extension = file.extension?.toLowerCase();
      if (extension == null || !_allowedExtensions.contains(extension)) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Format non autorisé')),
        );
        return;
      }
      if (file.size > _maxUploadBytes) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Le fichier dépasse la limite de 10 Mo'),
          ),
        );
        return;
      }
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aucun fichier sélectionné')),
        );
        return;
      }

      await ref
          .read(legalGoRepositoryProvider)
          .uploadDocument(
            requestId: widget.requestId,
            title: title,
            type: type,
            bytes: bytes,
            fileName: file.name,
            mimeType: _mimeTypes[extension]!,
            requiredDocumentId: requiredDocumentId,
          );
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Document envoyé avec succès')),
      );

      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      ref.invalidate(requestDocumentsProvider(widget.requestId));
      ref.invalidate(requestDetailsProvider(widget.requestId));
      ref.invalidate(clientRequestsProvider);
    } catch (error) {
      if (!mounted) return;
      final message = error is DocumentUploadValidationException
          ? error.message
          : 'Échec de l’envoi du document';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _uploadingDocumentKey = null);
    }
  }

  Future<_RequestedDocumentInput?> _showRequestDocumentDialog() async {
    return showDialog<_RequestedDocumentInput>(
      context: context,
      builder: (context) => const _RequestDocumentDialog(),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 5,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: 'Motif obligatoire',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isEmpty) {
              setState(() => _errorText = 'Le motif est obligatoire.');
              return;
            }
            Navigator.pop(context, value);
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

class _RequestDocumentDialog extends StatefulWidget {
  const _RequestDocumentDialog();

  @override
  State<_RequestDocumentDialog> createState() => _RequestDocumentDialogState();
}

class _RequestDocumentDialogState extends State<_RequestDocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _typeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demander un document'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: 191,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: _requiredField,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _typeController,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Type'),
                validator: _requiredField,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _messageController,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Message client'),
                validator: _requiredField,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              _RequestedDocumentInput(
                title: _titleController.text.trim(),
                type: _typeController.text.trim(),
                message: _messageController.text.trim(),
              ),
            );
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }

  static String? _requiredField(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Ce champ est obligatoire.'
        : null;
  }
}

class _RequestedDocumentInput {
  const _RequestedDocumentInput({
    required this.title,
    required this.type,
    required this.message,
  });

  final String title;
  final String type;
  final String message;
}

class _PaymentActionCard extends StatelessWidget {
  const _PaymentActionCard({
    required this.request,
    required this.actionState,
    required this.onPressed,
  });

  final LegalRequest request;
  final String? actionState;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final retry =
        request.paymentStatus == 'failed' ||
        request.paymentStatus == 'cancelled';
    final loading = actionState != null;
    final loadingLabel = actionState == 'opening'
        ? 'Ouverture du paiement...'
        : 'Paiement en cours...';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.subtleSurface(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                retry ? 'Paiement à réessayer' : 'Paiement requis',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${money(request.totalPrice)} - ${humanStatus(request.paymentStatus)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: loading ? null : onPressed,
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.credit_card_rounded),
            label: Text(
              loading
                  ? loadingLabel
                  : retry
                  ? 'Réessayer le paiement'
                  : 'Payer maintenant',
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: AppSpacing.md),
                button,
              ],
            );
          }
          return Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.softIndigo.withValues(alpha: .10),
                  borderRadius: AppRadius.icon,
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.softIndigo,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: details),
              const SizedBox(width: AppSpacing.md),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _AdminRequestActions extends StatelessWidget {
  const _AdminRequestActions({
    required this.request,
    required this.documentsReady,
    required this.allRequiredDocumentsValidated,
    required this.loadingAction,
    required this.onComplete,
    required this.onReject,
    required this.onCancel,
  });

  final LegalRequest request;
  final bool documentsReady;
  final bool allRequiredDocumentsValidated;
  final String? loadingAction;
  final VoidCallback? onComplete;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final finalStatus = const {
      'completed',
      'rejected',
      'cancelled',
    }.contains(request.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Gestion du dossier',
            subtitle: 'Actions administratives',
          ),
          const SizedBox(height: AppSpacing.md),
          if (finalStatus)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.subtleSurface(context),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ce dossier est clôturé. Aucune action supplémentaire n’est disponible.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (onComplete == null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  !documentsReady
                      ? 'Les documents doivent être chargés avant de terminer le dossier.'
                      : request.paymentStatus != 'paid'
                      ? 'Le paiement doit être validé avant de terminer le dossier.'
                      : !allRequiredDocumentsValidated
                      ? 'Tous les documents obligatoires doivent être validés.'
                      : 'La demande doit être en cours de traitement.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.icon(
                  onPressed: loadingAction == null ? onComplete : null,
                  icon: _ActionIcon(
                    loading: loadingAction == 'completed',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  label: const Text('Terminer'),
                ),
                OutlinedButton.icon(
                  onPressed: loadingAction == null ? onReject : null,
                  icon: _ActionIcon(
                    loading: loadingAction == 'rejected',
                    icon: Icons.block_outlined,
                  ),
                  label: const Text('Rejeter'),
                ),
                OutlinedButton.icon(
                  onPressed: loadingAction == null ? onCancel : null,
                  icon: _ActionIcon(
                    loading: loadingAction == 'cancelled',
                    icon: Icons.cancel_outlined,
                  ),
                  label: const Text('Annuler'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.loading, required this.icon});

  final bool loading;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (!loading) return Icon(icon);
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    final customer = request.customerName.isNotEmpty
        ? request.customerName
        : request.customerEmail;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      gradient: dark
          ? AppColors.heroGradient(context)
          : AppColors.primaryGradient,
      shadows: AppShadows.elevated(context),
      borderColor: Colors.white.withValues(alpha: dark ? .08 : .22),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: AppRadius.icon,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                  ),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      request.service?.title ?? 'Service indisponible',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: .82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusBadge(value: request.status),
              StatusBadge(value: request.paymentStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final details = [
                _SummaryMetric(
                  label: 'Créée le',
                  value: compactDate(request.createdAt),
                ),
                _SummaryMetric(
                  label: 'Total',
                  value: money(request.totalPrice),
                ),
                _SummaryMetric(label: 'Client', value: customer ?? '-'),
              ];
              if (compact) {
                return Column(
                  children: [
                    for (final detail in details) ...[
                      detail,
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (var index = 0; index < details.length; index++) ...[
                    Expanded(child: details[index]),
                    if (index != details.length - 1)
                      const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .70),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: .78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveDetailsGrid extends StatelessWidget {
  const _ResponsiveDetailsGrid({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(
            children: [
              left,
              const SizedBox(height: AppSpacing.md),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _PackInfo extends StatelessWidget {
  const _PackInfo({required this.request});

  final LegalRequest request;

  @override
  Widget build(BuildContext context) {
    final pack = request.pack;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: .10),
              borderRadius: AppRadius.icon,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations du pack',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  pack?.title ?? 'Aucun pack',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  pack == null
                      ? 'Les informations du pack sont indisponibles.'
                      : '${money(pack.price)} - ${pack.delayDays} jour(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.history});

  final List<RequestStatusHistory> history;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Chronologie',
            subtitle: 'Historique des statuts',
          ),
          const SizedBox(height: AppSpacing.md),
          if (history.isEmpty)
            Text(
              'Aucun historique de statut disponible.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (var index = 0; index < history.length; index++)
              _TimelineItem(
                item: history[index],
                isLast: index == history.length - 1,
              ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.isLast});

  final RequestStatusHistory item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final title =
        '${humanStatus(item.oldStatus ?? 'created')} → ${humanStatus(item.newStatus)}';
    final subtitle = [
      compactDate(item.createdAt),
      item.reason,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' - ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: AppColors.softIndigo,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxs,
                    ),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends ConsumerWidget {
  const _DocumentsCard({
    required this.admin,
    required this.requestStatus,
    required this.documents,
    required this.requiredDocuments,
    required this.loadingDocumentId,
    required this.uploadingDocumentKey,
    required this.requestingDocument,
    required this.onValidate,
    required this.onReject,
    required this.onRequestDocument,
    required this.onUploadRequired,
    required this.onUploadDocument,
  });

  final bool admin;
  final String requestStatus;
  final List<LegalDocument> documents;
  final List<ServiceRequiredDocument> requiredDocuments;
  final String? loadingDocumentId;
  final String? uploadingDocumentKey;
  final bool requestingDocument;
  final ValueChanged<LegalDocument> onValidate;
  final ValueChanged<LegalDocument> onReject;
  final VoidCallback onRequestDocument;
  final Future<void> Function(ServiceRequiredDocument)? onUploadRequired;
  final Future<void> Function(LegalDocument)? onUploadDocument;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finalRequest = const {
      'completed',
      'rejected',
      'cancelled',
    }.contains(requestStatus);
    final missingRequiredDocuments = requiredDocuments.where((required) {
      if (!required.active) return false;
      return !documents.any(
        (document) => document.serviceRequiredDocumentId == required.id,
      );
    }).toList();
    final latestDocumentByRequirement = <String, String>{};
    for (final document in documents) {
      final requirementId = document.serviceRequiredDocumentId;
      if (requirementId != null) {
        latestDocumentByRequirement.putIfAbsent(
          requirementId,
          () => document.id,
        );
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SectionHeader(
                  title: 'Documents',
                  subtitle: requiredDocuments.isEmpty
                      ? 'Fichiers transmis'
                      : '${requiredDocuments.length} document(s) requis',
                ),
              ),
              if (admin && !finalRequest) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton.filledTonal(
                  tooltip: 'Demander un document',
                  onPressed: requestingDocument ? null : onRequestDocument,
                  icon: requestingDocument
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.note_add_outlined),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (missingRequiredDocuments.isNotEmpty) ...[
            for (final required in missingRequiredDocuments)
              _MissingDocumentRow(
                requiredDocument: required,
                uploading: uploadingDocumentKey == 'required:${required.id}',
                uploadDisabled: uploadingDocumentKey != null,
                onUpload: onUploadRequired == null
                    ? null
                    : () => onUploadRequired!(required),
              ),
            if (documents.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Divider(height: 1),
              ),
          ],
          if (documents.isEmpty && missingRequiredDocuments.isEmpty)
            Text(
              'Aucun document transmis.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final document in documents)
              _DocumentRow(
                document: document,
                admin: admin,
                loading:
                    loadingDocumentId == document.id ||
                    uploadingDocumentKey == 'document:${document.id}',
                onDownload: document.canDownload
                    ? () => _download(context, ref, document)
                    : null,
                onValidate: admin && document.status == 'sent'
                    ? () => onValidate(document)
                    : null,
                onReject: admin && document.status == 'sent'
                    ? () => onReject(document)
                    : null,
                uploadLabel: _clientUploadLabel(
                  document,
                  finalRequest: finalRequest,
                  isLatestRequiredDocument:
                      document.serviceRequiredDocumentId == null ||
                      latestDocumentByRequirement[document
                              .serviceRequiredDocumentId] ==
                          document.id,
                ),
                uploadDisabled: uploadingDocumentKey != null,
                onUpload: onUploadDocument == null
                    ? null
                    : () => onUploadDocument!(document),
              ),
          if (admin && !finalRequest) ...[
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: requestingDocument ? null : onRequestDocument,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Demander un document'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _clientUploadLabel(
    LegalDocument document, {
    required bool finalRequest,
    required bool isLatestRequiredDocument,
  }) {
    if (admin || finalRequest || onUploadDocument == null) return null;
    final requirementId = document.serviceRequiredDocumentId;
    if (document.status == 'pending' &&
        document.requestedByAdmin &&
        requirementId == null) {
      return 'Téléverser';
    }
    if (document.status != 'rejected') return null;
    if (document.requestedByAdmin && requirementId == null) {
      return 'Remplacer';
    }
    if (requirementId != null && isLatestRequiredDocument) {
      return 'Remplacer';
    }
    return null;
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

class _MissingDocumentRow extends StatelessWidget {
  const _MissingDocumentRow({
    required this.requiredDocument,
    required this.uploading,
    required this.uploadDisabled,
    required this.onUpload,
  });

  final ServiceRequiredDocument requiredDocument;
  final bool uploading;
  final bool uploadDisabled;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.subtleBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.file_present_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requiredDocument.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      requiredDocument.isRequired
                          ? 'Document obligatoire non envoyé'
                          : 'Document optionnel non envoyé',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusBadge(value: 'missing', compact: true),
            ],
          ),
          if (onUpload != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.tonalIcon(
              onPressed: uploadDisabled ? null : onUpload,
              icon: uploading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Téléverser'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.admin,
    required this.loading,
    required this.onDownload,
    required this.onValidate,
    required this.onReject,
    required this.uploadLabel,
    required this.uploadDisabled,
    required this.onUpload,
  });

  final LegalDocument document;
  final bool admin;
  final bool loading;
  final VoidCallback? onDownload;
  final VoidCallback? onValidate;
  final VoidCallback? onReject;
  final String? uploadLabel;
  final bool uploadDisabled;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.subtleBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.softIndigo.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: AppColors.softIndigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
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
              StatusBadge(value: document.status, compact: true),
            ],
          ),
          if (document.requestedMessage?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Message client : ${document.requestedMessage}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (document.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Motif du rejet : ${document.rejectionReason}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (onDownload != null ||
              onValidate != null ||
              onReject != null ||
              uploadLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (uploadLabel != null && onUpload != null)
                  FilledButton.tonalIcon(
                    onPressed: uploadDisabled ? null : onUpload,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(uploadLabel!),
                  ),
                if (onDownload != null)
                  TextButton.icon(
                    onPressed: loading ? null : onDownload,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Télécharger'),
                  ),
                if (onValidate != null)
                  FilledButton.tonalIcon(
                    onPressed: loading ? null : onValidate,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: const Text('Valider'),
                  ),
                if (onReject != null)
                  OutlinedButton.icon(
                    onPressed: loading ? null : onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Rejeter'),
                  ),
              ],
            ),
          ],
          if (admin &&
              document.status != 'sent' &&
              document.status != 'pending')
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _AnswersCard extends StatelessWidget {
  const _AnswersCard({required this.answers});

  final List<RequestAnswer> answers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Réponses',
            subtitle: 'Informations transmises',
          ),
          const SizedBox(height: AppSpacing.md),
          if (answers.isEmpty)
            Text(
              'Aucune réponse associée à cette demande.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final answer in answers) _AnswerRow(answer: answer),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.answer});

  final RequestAnswer answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.subtleBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            answer.fieldName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            answer.fieldValue ?? '-',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
