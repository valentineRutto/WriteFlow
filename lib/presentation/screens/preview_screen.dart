part of '../inkdoc_app.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.viewModel,
    required this.onBack,
    required this.onAddPage,
    required this.onEditPage,
    required this.onHome,
    required this.onLibrary,
    required this.onSettings,
  });

  final PreviewViewModel viewModel;
  final VoidCallback onBack;
  final VoidCallback onAddPage;
  final VoidCallback onEditPage;
  final VoidCallback onHome;
  final VoidCallback onLibrary;
  final VoidCallback onSettings;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final DocumentExportService _exportService = const DocumentExportService();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final document = viewModel.document;
    final pages = document?.pages ?? const <ScannedPage>[];
    final export = exportTypes[viewModel.selectedExport];

    return Column(
      children: [
        Expanded(
          child: ListView(
            cacheExtent: 4000,
            padding: EdgeInsets.zero,
            children: [
              PreviewTopBar(
                document: document,
                onBack: widget.onBack,
                onEditPage: widget.onEditPage,
              ),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: pages.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == pages.length) {
                      return PageThumb(
                        label: 'Add',
                        icon: Icons.add_rounded,
                        dashed: true,
                        onTap: widget.onAddPage,
                      );
                    }
                    return PageThumb(
                      label: 'Pg ${index + 1}',
                      icon: Icons.description_outlined,
                      active: index == viewModel.selectedPage,
                      onTap: () => viewModel.selectPage(index),
                    );
                  },
                ),
              ),
              OcrPreviewCard(page: viewModel.currentPage),
              AiPipelineBadge(
                engine: document?.engine,
                aiEngine: viewModel.currentPage?.aiEngine,
              ),
              AccuracyMeter(confidence: document?.overallConfidence ?? 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  'Export as',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < exportTypes.length;
                      index++
                    ) ...[
                      Expanded(
                        child: ExportOptionCard(
                          type: exportTypes[index],
                          selected: viewModel.selectedExport == index,
                          onTap: () => viewModel.selectExport(index),
                        ),
                      ),
                      if (index < exportTypes.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.onEditPage,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit text'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: viewModel.isImprovingText
                          ? null
                          : () => _cleanCurrentPage(context),
                      icon: viewModel.isImprovingText
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high_rounded, size: 18),
                      label: const Text('Clean'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: document == null || _isExporting
                            ? null
                            : () => _exportDocument(context),
                        icon: _isExporting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _isExporting
                              ? 'Preparing...'
                              : 'Export ${export.label}',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          foregroundColor: AppColors.mint,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppNavBar(
          current: AppScreen.preview,
          onHome: widget.onHome,
          onLibrary: widget.onLibrary,
          onSettings: widget.onSettings,
        ),
      ],
    );
  }

  Future<void> _cleanCurrentPage(BuildContext context) async {
    await widget.viewModel.improveCurrentPage();
    if (!context.mounted || widget.viewModel.errorMessage == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.viewModel.errorMessage!)));
  }

  Future<void> _exportDocument(BuildContext context) async {
    final document = widget.viewModel.document;
    if (document == null || _isExporting) {
      return;
    }

    setState(() => _isExporting = true);
    try {
      final format =
          DocumentExportFormat.values[widget.viewModel.selectedExport];
      final exported = await _exportService.export(document, format);
      if (!context.mounted) {
        return;
      }
      await _showExportActions(context, exported);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export document: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showExportActions(
    BuildContext context,
    ExportedDocument exported,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Export ${exported.fileName}',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Save a copy to your phone or share it with another app.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _saveToDevice(context, exported);
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Save to phone'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _shareExport(context, exported);
                },
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share to another app'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToDevice(
    BuildContext context,
    ExportedDocument exported,
  ) async {
    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save InkDoc export',
        fileName: exported.fileName,
        type: FileType.custom,
        allowedExtensions: [exported.fileName.split('.').last],
        bytes: exported.bytes,
      );
      if (context.mounted && savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${exported.fileName} saved to your phone.')),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save file: $error')));
      }
    }
  }

  Future<void> _shareExport(
    BuildContext context,
    ExportedDocument exported,
  ) async {
    try {
      final renderBox = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: 'Share ${exported.fileName}',
          subject: exported.fileName,
          files: [
            XFile.fromData(
              exported.bytes,
              name: exported.fileName,
              mimeType: exported.mimeType,
            ),
          ],
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share file: $error')));
      }
    }
  }
}
