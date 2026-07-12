part of '../inkdoc_app.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.documentTypes,
    required this.onAddDocumentType,
    required this.onEditDocumentType,
    required this.onScan,
    required this.onLibrary,
  });

  final ScanViewModel viewModel;
  final List<DocType> documentTypes;
  final VoidCallback onAddDocumentType;
  final VoidCallback onEditDocumentType;
  final Future<void> Function() onScan;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            cacheExtent: 4000,
            padding: EdgeInsets.zero,
            children: [
              const AppTopBar(
                title: 'InkDoc',
                subtitle: 'On-device AI - no internet needed',
                trailing: Icons.notifications_none_rounded,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: ScanHero(onTap: onScan),
              ),
              _SectionHeader(
                label: 'Document type',
                actions: [
                  IconButton(
                    onPressed: onEditDocumentType,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit document type',
                    color: AppColors.textMuted,
                  ),
                  IconButton.filledTonal(
                    onPressed: onAddDocumentType,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add document type',
                    color: AppColors.deepGreen,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.mint,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var index = 0; index < documentTypes.length; index++)
                      DocumentTypeFilterChip(
                        documentType: documentTypes[index],
                        selected: viewModel.selectedDocumentType == index,
                        onTap: () => viewModel.selectDocumentType(index),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: BatchScanTile(
                  value: viewModel.batchMode,
                  onChanged: viewModel.setBatchMode,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: FilledButton.icon(
                  onPressed: viewModel.isScanning ? null : onScan,
                  icon: viewModel.isScanning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    viewModel.isScanning
                        ? 'Processing scan...'
                        : 'Open camera scanner',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: AppColors.mint,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        AppNavBar(current: AppScreen.home, onHome: () {}, onLibrary: onLibrary),
      ],
    );
  }
}
