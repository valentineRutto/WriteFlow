part of '../inkdoc_app.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.viewModel,
    required this.onHome,
    required this.onOpenDocument,
    required this.onSettings,
  });

  final LibraryViewModel viewModel;
  final VoidCallback onHome;
  final ValueChanged<LibraryDocument> onOpenDocument;
  final VoidCallback onSettings;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 320) {
      widget.viewModel.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
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
                    onTap: () => widget.onOpenDocument(item),
                  ),
              if (!viewModel.isLoading && viewModel.documents.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No saved documents found.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              if (viewModel.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        AppNavBar(
          current: AppScreen.library,
          onHome: widget.onHome,
          onLibrary: () {},
          onSettings: widget.onSettings,
        ),
      ],
    );
  }
}
