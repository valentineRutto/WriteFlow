class GemmaModelOption {
  const GemmaModelOption({
    required this.id,
    required this.name,
    required this.description,
    required this.sizeLabel,
    required this.url,
    required this.minimumRamGb,
    required this.requiredStorageGb,
  });

  final String id;
  final String name;
  final String description;
  final String sizeLabel;
  final String url;
  final double minimumRamGb;
  final double requiredStorageGb;
}

class DeviceCapabilities {
  const DeviceCapabilities({
    required this.platform,
    required this.osVersion,
    required this.totalRamGb,
    required this.freeStorageGb,
    required this.architecture,
    this.isSimulator = false,
  });

  final String platform;
  final String osVersion;
  final double totalRamGb;
  final double freeStorageGb;
  final String architecture;
  final bool isSimulator;

  bool supports(GemmaModelOption model) =>
      totalRamGb >= model.minimumRamGb &&
      freeStorageGb >= model.requiredStorageGb;
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
