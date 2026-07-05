part of '../writeflow_app.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.viewModel,
    required this.onHome,
    required this.onOpenDocument,
  });

  final LibraryViewModel viewModel;
  final VoidCallback onHome;
  final ValueChanged<LibraryDocument> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //const StatusBar(time: '9:45'),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // const AppTopBar(
              //   title: 'My library',
              //   subtitle: '12 documents - 47 pages',
              //   trailing: Icons.tune_rounded,
              // ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: TextField(
                  onChanged: viewModel.search,
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                  ),
                ),
              ),
              if (viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final item in viewModel.documents)
                  LibraryItemTile(
                    item: item,
                    isLast: item == viewModel.documents.last,
                    onTap: () => onOpenDocument(item),
                  ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        AppNavBar(current: AppScreen.library, onHome: onHome, onLibrary: () {}),
      ],
    );
  }
}
