part of '../inkdoc_app.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({
    super.key,
    required this.viewModel,
    required this.onBack,
    required this.onAddPage,
    required this.onEditPage,
    required this.onHome,
    required this.onLibrary,
  });

  final PreviewViewModel viewModel;
  final VoidCallback onBack;
  final VoidCallback onAddPage;
  final VoidCallback onEditPage;
  final VoidCallback onHome;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
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
                onBack: onBack,
                onEditPage: onEditPage,
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
                        onTap: onAddPage,
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
                      onPressed: onEditPage,
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
                          : viewModel.improveCurrentPage,
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
                        onPressed: () {},
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text('Export ${export.label}'),
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
          onHome: onHome,
          onLibrary: onLibrary,
        ),
      ],
    );
  }
}
