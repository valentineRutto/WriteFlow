class GemmaModelOption {
  const GemmaModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeLabel,
    required this.url,
  });

  final String id;
  final String name;
  final String description;
  final String sizeLabel;
  final String url;
}

class GemmaModelState {
  const GemmaModelState({
    required this.option,
    required this.isInstalled,
    required this.isActive,
  });

  final GemmaModelOption option;
  final bool isInstalled;
  final bool isActive;
}
