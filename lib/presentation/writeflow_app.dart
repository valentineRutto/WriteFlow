import 'package:flutter/material.dart';

import '../app/app_dependencies.dart';
import '../domain/models/library_document.dart';
import '../domain/models/scanned_document.dart';
import 'view_models/app_navigation_view_model.dart';
import 'view_models/library_view_model.dart';
import 'view_models/preview_view_model.dart';
import 'view_models/scan_view_model.dart';

class WriteFlowApp extends StatelessWidget {
  const WriteFlowApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inkscribe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deepGreen),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.canvas,
        useMaterial3: true,
      ),
      home: InkscribeShell(
        dependencies: dependencies ?? AppDependencies.demo(),
      ),
    );
  }
}

class InkscribeShell extends StatefulWidget {
  const InkscribeShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<InkscribeShell> createState() => _InkscribeShellState();
}

class _InkscribeShellState extends State<InkscribeShell> {
  late final AppNavigationViewModel _navigationViewModel;
  late final ScanViewModel _scanViewModel;
  late final PreviewViewModel _previewViewModel;
  late final LibraryViewModel _libraryViewModel;
  late final Listenable _viewModels;

  @override
  void initState() {
    super.initState();
    _navigationViewModel = AppNavigationViewModel();
    _scanViewModel = ScanViewModel(
      repository: widget.dependencies.scanRepository,
    );
    _previewViewModel = PreviewViewModel();
    _libraryViewModel = LibraryViewModel(
      repository: widget.dependencies.libraryRepository,
    );
    _viewModels = Listenable.merge([
      _navigationViewModel,
      _scanViewModel,
      _previewViewModel,
      _libraryViewModel,
    ]);
    _libraryViewModel.load();
  }

  @override
  void dispose() {
    _navigationViewModel.dispose();
    _scanViewModel.dispose();
    _previewViewModel.dispose();
    _libraryViewModel.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final document = await _scanViewModel.scan();
    if (!mounted || document == null) {
      return;
    }

    _previewViewModel.showDocument(document);
    _navigationViewModel.show(AppScreen.preview);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModels,
      builder: (context, _) {
        final screen = _navigationViewModel.screen;

        return Scaffold(
          backgroundColor: AppColors.shell,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'INKSCRIBE - HANDWRITTEN TO DIGITAL',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ScreenTabs(
                      screen: screen,
                      onChanged: _navigationViewModel.show,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: switch (screen) {
                              AppScreen.home => HomeScreen(
                                viewModel: _scanViewModel,
                                onScan: _scan,
                                onLibrary: () => _navigationViewModel.show(
                                  AppScreen.library,
                                ),
                              ),
                              AppScreen.preview => PreviewScreen(
                                viewModel: _previewViewModel,
                                onBack: () =>
                                    _navigationViewModel.show(AppScreen.home),
                                onAddPage: () =>
                                    _navigationViewModel.show(AppScreen.home),
                                onHome: () =>
                                    _navigationViewModel.show(AppScreen.home),
                                onLibrary: () => _navigationViewModel.show(
                                  AppScreen.library,
                                ),
                              ),
                              AppScreen.library => LibraryScreen(
                                viewModel: _libraryViewModel,
                                onHome: () =>
                                    _navigationViewModel.show(AppScreen.home),
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.onScan,
    required this.onLibrary,
  });

  final ScanViewModel viewModel;
  final Future<void> Function() onScan;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      statusTime: '9:41',
      bottomNavigation: AppNavBar(
        current: AppScreen.home,
        onHome: () {},
        onLibrary: onLibrary,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const AppTopBar(
            title: 'Inkscribe',
            subtitle: 'On-device AI - no internet needed',
            trailing: Icons.notifications_none_rounded,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ScanHero(onTap: onScan),
          ),
          const _SectionLabel('Document type'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: GridView.builder(
              itemCount: docTypes.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.7,
              ),
              itemBuilder: (context, index) {
                final doc = docTypes[index];
                return SelectableCard(
                  selected: viewModel.selectedDocumentType == index,
                  icon: doc.icon,
                  iconColor: doc.color,
                  title: doc.title,
                  subtitle: doc.subtitle,
                  onTap: () => viewModel.selectDocumentType(index),
                );
              },
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
    );
  }
}

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({
    super.key,
    required this.viewModel,
    required this.onBack,
    required this.onAddPage,
    required this.onHome,
    required this.onLibrary,
  });

  final PreviewViewModel viewModel;
  final VoidCallback onBack;
  final VoidCallback onAddPage;
  final VoidCallback onHome;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    final document = viewModel.document;
    final pages = document?.pages ?? const <ScannedPage>[];
    final export = exportTypes[viewModel.selectedExport];

    return _PhoneScreen(
      statusTime: '9:43',
      bottomNavigation: AppNavBar(
        current: AppScreen.preview,
        onHome: onHome,
        onLibrary: onLibrary,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          PreviewTopBar(document: document, onBack: onBack),
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
                for (var index = 0; index < exportTypes.length; index++) ...[
                  Expanded(
                    child: ExportOptionCard(
                      type: exportTypes[index],
                      selected: viewModel.selectedExport == index,
                      onTap: () => viewModel.selectExport(index),
                    ),
                  ),
                  if (index < exportTypes.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
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
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.viewModel,
    required this.onHome,
  });

  final LibraryViewModel viewModel;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return _PhoneScreen(
      statusTime: '9:45',
      bottomNavigation: AppNavBar(
        current: AppScreen.library,
        onHome: onHome,
        onLibrary: () {},
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const AppTopBar(
            title: 'My library',
            subtitle: '12 documents - 47 pages',
            trailing: Icons.tune_rounded,
          ),
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
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderLight),
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
              ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PhoneScreen extends StatelessWidget {
  const _PhoneScreen({
    required this.statusTime,
    required this.child,
    required this.bottomNavigation,
  });

  final String statusTime;
  final Widget child;
  final Widget bottomNavigation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StatusBar(time: statusTime),
        Expanded(child: child),
        bottomNavigation,
      ],
    );
  }
}

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Row(
            children: [
              Icon(Icons.wifi_rounded, size: 14, color: AppColors.textMuted),
              SizedBox(width: 4),
              Icon(
                Icons.battery_full_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(trailing, color: AppColors.textMuted, size: 22),
        ],
      ),
    );
  }
}

class ScanHero extends StatefulWidget {
  const ScanHero({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<ScanHero> createState() => _ScanHeroState();
}

class _ScanHeroState extends State<ScanHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deepGreen,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          height: 200,
          child: Stack(
            children: [
              const Positioned(
                top: 16,
                left: 16,
                child: ScanCorner(alignment: CornerAlignment.topLeft),
              ),
              const Positioned(
                top: 16,
                right: 16,
                child: ScanCorner(alignment: CornerAlignment.topRight),
              ),
              const Positioned(
                bottom: 16,
                left: 16,
                child: ScanCorner(alignment: CornerAlignment.bottomLeft),
              ),
              const Positioned(
                bottom: 16,
                right: 16,
                child: ScanCorner(alignment: CornerAlignment.bottomRight),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final value = Curves.easeInOut.transform(_controller.value);
                  return Positioned(
                    left: 24,
                    right: 24,
                    top: 30 + (140 * value),
                    child: Opacity(
                      opacity:
                          _controller.value < 0.1 || _controller.value > 0.9
                          ? 0.35
                          : 1,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.scanLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.mint,
                      size: 42,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to scan',
                      style: TextStyle(
                        color: AppColors.mint,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Position page within frame',
                      style: TextStyle(color: AppColors.scanLine, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum CornerAlignment { topLeft, topRight, bottomLeft, bottomRight }

class ScanCorner extends StatelessWidget {
  const ScanCorner({super.key, required this.alignment});

  final CornerAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: ScanCornerPainter(alignment),
    );
  }
}

class ScanCornerPainter extends CustomPainter {
  ScanCornerPainter(this.alignment);

  final CornerAlignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final path = Path();

    switch (alignment) {
      case CornerAlignment.topLeft:
        path
          ..moveTo(size.width, 0)
          ..lineTo(0, 0)
          ..lineTo(0, size.height);
      case CornerAlignment.topRight:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height);
      case CornerAlignment.bottomLeft:
        path
          ..moveTo(0, 0)
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height);
      case CornerAlignment.bottomRight:
        path
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScanCornerPainter oldDelegate) {
    return oldDelegate.alignment != alignment;
  }
}

class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accentGreen : AppColors.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BatchScanTile extends StatelessWidget {
  const BatchScanTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch scan mode',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Scan multiple pages in one session',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accentGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class PreviewTopBar extends StatelessWidget {
  const PreviewTopBar({
    super.key,
    required this.document,
    required this.onBack,
  });

  final ScannedDocument? document;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${document?.title ?? 'Scanned document'} - '
                  '${document?.pages.length ?? 0} '
                  '${document?.pages.length == 1 ? 'page' : 'pages'}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Scanned just now - edge AI processing done',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class PageThumb extends StatelessWidget {
  const PageThumb({
    super.key,
    required this.label,
    required this.icon,
    this.active = false,
    this.dashed = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool dashed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 64,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.accentGreen : AppColors.borderLight,
              width: active ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textMuted, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OcrPreviewCard extends StatelessWidget {
  const OcrPreviewCard({super.key, required this.page});

  final ScannedPage? page;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      height: 1.6,
      fontFamily: 'Georgia',
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Recognised text - page 1',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${((page?.confidence ?? 0) * 100).round()}% confidence',
                  style: TextStyle(
                    color: AppColors.darkMintText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(page?.text ?? 'No recognized text yet.', style: textStyle),
        ],
      ),
    );
  }
}

class AccuracyMeter extends StatelessWidget {
  const AccuracyMeter({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          const Text(
            'Overall accuracy',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(
                value: confidence,
                minHeight: 4,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.accentGreen),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(confidence * 100).round()}%',
            style: const TextStyle(
              color: AppColors.deepGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ExportOptionCard extends StatelessWidget {
  const ExportOptionCard({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ExportType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.accentGreen : AppColors.borderLight,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(type.icon, color: type.color, size: 22),
              const SizedBox(height: 4),
              Text(
                type.label,
                style: TextStyle(
                  color: selected ? AppColors.darkMintText : type.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryItemTile extends StatelessWidget {
  const LibraryItemTile({super.key, required this.item, required this.isLast});

  final LibraryDocument item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final style = libraryItemStyle(item.category);

    return InkWell(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : AppColors.borderLight,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.meta,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: style.tint,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.category,
                style: TextStyle(
                  color: style.badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.current,
    required this.onHome,
    required this.onLibrary,
  });

  final AppScreen current;
  final VoidCallback onHome;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        children: [
          NavItem(
            icon: Icons.document_scanner_outlined,
            label: 'Scan',
            active: current == AppScreen.home,
            onTap: onHome,
          ),
          NavItem(
            icon: Icons.folder_outlined,
            label: 'Library',
            active: current == AppScreen.library,
            onTap: onLibrary,
          ),
          NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            active: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.deepGreen : AppColors.textFaint;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenTabs extends StatelessWidget {
  const _ScreenTabs({required this.screen, required this.onChanged});

  final AppScreen screen;
  final ValueChanged<AppScreen> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _TabPill(
          label: 'Home',
          selected: screen == AppScreen.home,
          onTap: () => onChanged(AppScreen.home),
        ),
        _TabPill(
          label: 'Preview & export',
          selected: screen == AppScreen.preview,
          onTap: () => onChanged(AppScreen.preview),
        ),
        _TabPill(
          label: 'My library',
          selected: screen == AppScreen.library,
          onTap: () => onChanged(AppScreen.library),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.deepGreen : AppColors.surface,
        foregroundColor: selected ? AppColors.mint : AppColors.textMuted,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class DocType {
  const DocType(this.title, this.subtitle, this.icon, this.color);

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class ExportType {
  const ExportType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class LibraryItemStyle {
  const LibraryItemStyle({
    required this.icon,
    required this.tint,
    required this.color,
    required this.badgeColor,
  });

  final IconData icon;
  final Color tint;
  final Color color;
  final Color badgeColor;
}

LibraryItemStyle libraryItemStyle(String category) {
  return switch (category) {
    'Diary' => const LibraryItemStyle(
      icon: Icons.menu_book_outlined,
      tint: AppColors.mint,
      color: AppColors.deepGreen,
      badgeColor: AppColors.darkMintText,
    ),
    'Poetry' => const LibraryItemStyle(
      icon: Icons.draw_outlined,
      tint: Color(0xFFE6F1FB),
      color: Color(0xFF185FA5),
      badgeColor: Color(0xFF0C447C),
    ),
    'Recipe' => const LibraryItemStyle(
      icon: Icons.restaurant_menu_rounded,
      tint: AppColors.warmHighlight,
      color: Color(0xFF854F0B),
      badgeColor: AppColors.brownText,
    ),
    'Sermon' => const LibraryItemStyle(
      icon: Icons.church_outlined,
      tint: Color(0xFFEEEDFE),
      color: Color(0xFF534AB7),
      badgeColor: Color(0xFF3C3489),
    ),
    'Notes' => const LibraryItemStyle(
      icon: Icons.school_outlined,
      tint: Color(0xFFEAF3DE),
      color: Color(0xFF3B6D11),
      badgeColor: Color(0xFF27500A),
    ),
    _ => const LibraryItemStyle(
      icon: Icons.business_center_outlined,
      tint: Color(0xFFF1EFE8),
      color: Color(0xFF444441),
      badgeColor: Color(0xFF2C2C2A),
    ),
  };
}

const docTypes = [
  DocType(
    'Diary / journal',
    'Personal entries',
    Icons.menu_book_outlined,
    AppColors.deepGreen,
  ),
  DocType('Poetry', 'Verses & stanzas', Icons.draw_outlined, Color(0xFF185FA5)),
  DocType(
    'Meeting notes',
    'Minutes & actions',
    Icons.notes_rounded,
    AppColors.brownText,
  ),
  DocType(
    'Class notes',
    'Lectures & study',
    Icons.school_outlined,
    Color(0xFF3B6D11),
  ),
  DocType(
    'Recipes',
    'Ingredients & steps',
    Icons.restaurant_menu_rounded,
    Color(0xFF993C1D),
  ),
  DocType(
    'Sermon',
    'Notes & scripture',
    Icons.church_outlined,
    Color(0xFF534AB7),
  ),
];

const exportTypes = [
  ExportType('PDF', Icons.picture_as_pdf_outlined, Color(0xFFA32D2D)),
  ExportType('EPUB', Icons.book_outlined, Color(0xFF185FA5)),
  ExportType('eBook', Icons.tablet_mac_outlined, AppColors.brownText),
];

class AppColors {
  static const canvas = Color(0xFFFCFCFA);
  static const shell = Color(0xFFF1F3F0);
  static const surface = Color(0xFFF6F7F4);
  static const border = Color(0xFFD8DDD6);
  static const borderLight = Color(0xFFE5E8E1);
  static const textPrimary = Color(0xFF20231F);
  static const textMuted = Color(0xFF6F766E);
  static const textFaint = Color(0xFF9AA099);
  static const deepGreen = Color(0xFF0F6E56);
  static const accentGreen = Color(0xFF1D9E75);
  static const mint = Color(0xFFE1F5EE);
  static const scanLine = Color(0xFF9FE1CB);
  static const darkMintText = Color(0xFF085041);
  static const warmHighlight = Color(0xFFFAEEDA);
  static const brownText = Color(0xFF633806);
}
