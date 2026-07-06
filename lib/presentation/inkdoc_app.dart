import 'package:flutter/material.dart';

import '../app/app_dependencies.dart';
import '../domain/models/library_document.dart';
import '../domain/models/scanned_document.dart';
import 'view_models/app_navigation_view_model.dart';
import 'view_models/library_view_model.dart';
import 'view_models/preview_view_model.dart';
import 'view_models/scan_view_model.dart';

part 'screens/home_screen.dart';
part 'screens/library_screen.dart';
part 'screens/preview_screen.dart';

class InkDocApp extends StatelessWidget {
  const InkDocApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InkDoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deepGreen),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: AppColors.canvas,
        useMaterial3: true,
      ),
      home: InkDocShell(dependencies: dependencies ?? AppDependencies.demo()),
    );
  }
}

class InkDocShell extends StatefulWidget {
  const InkDocShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<InkDocShell> createState() => _InkDocShellState();
}

class _InkDocShellState extends State<InkDocShell> {
  late final AppNavigationViewModel _navigationViewModel;
  late final ScanViewModel _scanViewModel;
  late final PreviewViewModel _previewViewModel;
  late final LibraryViewModel _libraryViewModel;
  late final Listenable _viewModels;
  final List<DocType> _documentTypes = List.of(defaultDocTypes);

  @override
  void initState() {
    super.initState();
    _navigationViewModel = AppNavigationViewModel();
    _scanViewModel = ScanViewModel(
      repository: widget.dependencies.scanRepository,
    );
    _previewViewModel = PreviewViewModel(
      textEditingRepository: widget.dependencies.textEditingRepository,
    );
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

  void _openLibraryDocument(LibraryDocument document) {
    _previewViewModel.showDocument(_scannedDocumentFromLibraryItem(document));
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
                      'INKDOC - HANDWRITTEN TO DIGITAL',
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
                                documentTypes: _documentTypes,
                                onAddDocumentType: _addDocumentType,
                                onEditDocumentType: _editSelectedDocumentType,
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
                                onEditPage: _editCurrentPage,
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
                                onOpenDocument: _openLibraryDocument,
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

  Future<void> _editCurrentPage() async {
    final page = _previewViewModel.currentPage;
    if (page == null) {
      return;
    }

    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) => EditRecognisedTextDialog(initialText: page.text),
    );

    if (updatedText == null) {
      return;
    }

    _previewViewModel.updateCurrentPageText(updatedText);
  }

  Future<void> _addDocumentType() async {
    final documentType = await showDialog<DocType>(
      context: context,
      builder: (context) => const DocumentTypeDialog(),
    );

    if (documentType == null) {
      return;
    }

    setState(() {
      _documentTypes.add(documentType);
      _scanViewModel.selectDocumentType(_documentTypes.length - 1);
    });
  }

  Future<void> _editSelectedDocumentType() async {
    final selectedIndex = _scanViewModel.selectedDocumentType;
    if (selectedIndex < 0 || selectedIndex >= _documentTypes.length) {
      return;
    }

    final documentType = await showDialog<DocType>(
      context: context,
      builder: (context) => DocumentTypeDialog(
        initialDocumentType: _documentTypes[selectedIndex],
      ),
    );

    if (documentType == null) {
      return;
    }

    setState(() {
      _documentTypes[selectedIndex] = documentType;
    });
  }
}

ScannedDocument _scannedDocumentFromLibraryItem(LibraryDocument document) {
  final pageCount = _pageCountFromMeta(document.meta);
  final pages = List.generate(
    pageCount,
    (index) => ScannedPage(
      number: index + 1,
      text:
          '${document.title}\n'
          '${document.category} document opened from your library.\n\n'
          'This saved handwriting preview is ready to review, clean, edit, '
          'and export from InkDoc.',
      confidence: 0.9,
      aiEngine: 'Saved OCR text',
    ),
  );

  return ScannedDocument(
    title: document.title,
    pages: pages,
    engine: 'InkDoc library',
  );
}

int _pageCountFromMeta(String meta) {
  final match = RegExp(r'^(\d+)\s+pages?').firstMatch(meta);
  return int.tryParse(match?.group(1) ?? '') ?? 1;
}

class DocumentTypeDialog extends StatefulWidget {
  const DocumentTypeDialog({super.key, this.initialDocumentType});

  final DocType? initialDocumentType;

  @override
  State<DocumentTypeDialog> createState() => _DocumentTypeDialogState();
}

class _DocumentTypeDialogState extends State<DocumentTypeDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late IconData _icon;
  late Color _color;

  bool get _isEditing => widget.initialDocumentType != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDocumentType;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _subtitleController = TextEditingController(text: initial?.subtitle ?? '');
    _icon = initial?.icon ?? _documentTypeIconOptions.first;
    _color = initial?.color ?? _documentTypeColorOptions.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    if (title.isEmpty || subtitle.isEmpty) {
      return;
    }

    Navigator.of(context).pop(DocType(title, subtitle, _icon, _color));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit document type' : 'Add document type'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Subtitle',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _documentTypeIconOptions)
                  _OptionIconButton(
                    icon: icon,
                    selected: icon == _icon,
                    color: _color,
                    onTap: () => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in _documentTypeColorOptions)
                  _ColorSwatchButton(
                    color: color,
                    selected: color == _color,
                    onTap: () => setState(() => _color = color),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _OptionIconButton extends StatelessWidget {
  const _OptionIconButton({
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
      color: selected ? Colors.white : color,
      style: IconButton.styleFrom(
        backgroundColor: selected ? color : AppColors.surface,
        side: BorderSide(
          color: selected ? color : AppColors.borderLight,
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Select color',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.textPrimary : AppColors.borderLight,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }
}

class EditRecognisedTextDialog extends StatefulWidget {
  const EditRecognisedTextDialog({super.key, required this.initialText});

  final String initialText;

  @override
  State<EditRecognisedTextDialog> createState() =>
      _EditRecognisedTextDialogState();
}

class _EditRecognisedTextDialogState extends State<EditRecognisedTextDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit recognised text'),
      content: TextField(
        controller: _controller,
        minLines: 6,
        maxLines: 10,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Correct the handwriting OCR here...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
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

class DocumentTypeFilterChip extends StatelessWidget {
  const DocumentTypeFilterChip({
    super.key,
    required this.documentType,
    required this.selected,
    required this.onTap,
  });

  final DocType documentType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        documentType.icon,
        color: selected ? AppColors.deepGreen : documentType.color,
        size: 18,
      ),
      label: Text(
        documentType.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      tooltip: documentType.subtitle,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selected ? AppColors.darkMintText : AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.mint,
      side: BorderSide(
        color: selected ? AppColors.accentGreen : AppColors.borderLight,
        width: selected ? 1.5 : 1,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
    required this.onEditPage,
  });

  final ScannedDocument? document;
  final VoidCallback onBack;
  final VoidCallback onEditPage;

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
          IconButton(
            onPressed: document == null ? null : onEditPage,
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.textMuted,
            tooltip: 'Edit text',
          ),
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

class AiPipelineBadge extends StatelessWidget {
  const AiPipelineBadge({super.key, this.engine, this.aiEngine});

  final String? engine;
  final String? aiEngine;

  @override
  Widget build(BuildContext context) {
    final scanEngine = engine ?? 'Scanner ready';
    final textEngine = aiEngine ?? 'Text cleanup ready';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.memory_rounded,
            color: AppColors.deepGreen,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$scanEngine\n$textEngine',
              style: const TextStyle(
                color: AppColors.darkMintText,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
  const LibraryItemTile({
    super.key,
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  final LibraryDocument item;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = libraryItemStyle(item.category);

    return InkWell(
      onTap: onTap,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.actions});

  final String label;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          for (final action in actions) action,
        ],
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

const defaultDocTypes = [
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

const _documentTypeIconOptions = [
  Icons.menu_book_outlined,
  Icons.draw_outlined,
  Icons.notes_rounded,
  Icons.school_outlined,
  Icons.restaurant_menu_rounded,
  Icons.church_outlined,
  Icons.business_center_outlined,
  Icons.description_outlined,
];

const _documentTypeColorOptions = [
  AppColors.deepGreen,
  Color(0xFF185FA5),
  AppColors.brownText,
  Color(0xFF3B6D11),
  Color(0xFF993C1D),
  Color(0xFF534AB7),
  Color(0xFFA32D2D),
  Color(0xFF444441),
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
