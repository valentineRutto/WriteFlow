part of '../inkdoc_app.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.viewModel,
    required this.onHome,
    required this.onLibrary,
  });

  final SettingsViewModel viewModel;
  final VoidCallback onHome;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'On-device AI model',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Download a Gemma model once, then use it offline to clean and improve scanned handwriting.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              if (viewModel.deviceCapabilities case final device?)
                _DeviceCompatibilityCard(device: device),
              if (viewModel.deviceCapabilities != null)
                const SizedBox(height: 18),
              if (viewModel.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                for (final model in viewModel.models) ...[
                  _GemmaModelCard(model: model, viewModel: viewModel),
                  const SizedBox(height: 12),
                ],
              if (!viewModel.isLoading && viewModel.models.isEmpty)
                OutlinedButton.icon(
                  onPressed: viewModel.load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reload models'),
                ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Could not manage models: ${viewModel.errorMessage}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.wifi_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Internet is only required while downloading. Large downloads should use Wi-Fi.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppNavBar(
          current: AppScreen.settings,
          onHome: onHome,
          onLibrary: onLibrary,
          onSettings: () {},
        ),
      ],
    );
  }
}

class _GemmaModelCard extends StatelessWidget {
  const _GemmaModelCard({required this.model, required this.viewModel});

  final GemmaModelState model;
  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final device = viewModel.deviceCapabilities;
    final isCompatible = device?.supports(model.option);
    final isBusy = viewModel.busyModelId == model.option.id;
    final anotherIsBusy =
        viewModel.busyModelId != null &&
        viewModel.busyModelId != model.option.id;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: model.isActive ? AppColors.mint : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: model.isActive ? AppColors.accentGreen : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.option.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (model.isActive)
                const Chip(
                  avatar: Icon(Icons.check_circle_rounded, size: 17),
                  label: Text('Active'),
                  visualDensity: VisualDensity.compact,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      model.option.sizeLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCompatible != null)
                      Text(
                        isCompatible ? 'Recommended' : 'May not run',
                        style: TextStyle(
                          color: isCompatible
                              ? AppColors.deepGreen
                              : Colors.deepOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            model.option.description,
            style: const TextStyle(color: AppColors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            'Requires ${model.option.minimumRamGb.toStringAsFixed(0)} GB RAM and '
            '${model.option.requiredStorageGb.toStringAsFixed(0)} GB free storage.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isBusy) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: viewModel.progress / 100),
            const SizedBox(height: 5),
            Text(
              'Downloading ${viewModel.progress}%',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ] else if (!model.isActive) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: model.isInstalled
                  ? OutlinedButton.icon(
                      onPressed: anotherIsBusy
                          ? null
                          : () => viewModel.select(model.option),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Use this model'),
                    )
                  : FilledButton.icon(
                      onPressed: anotherIsBusy
                          ? null
                          : () => viewModel.select(model.option),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download and use'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeviceCompatibilityCard extends StatelessWidget {
  const _DeviceCompatibilityCard({required this.device});

  final DeviceCapabilities device;

  @override
  Widget build(BuildContext context) {
    final baseCompatible = device.totalRamGb >= 4 && device.freeStorageGb >= 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseCompatible ? AppColors.mint : const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: baseCompatible ? AppColors.accentGreen : Colors.deepOrange,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                baseCompatible
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                color: baseCompatible ? AppColors.deepGreen : Colors.deepOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  baseCompatible
                      ? 'This device supports Gemma'
                      : 'Limited model compatibility',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${device.platform} ${device.osVersion}'
            '${device.isSimulator ? ' • Simulator' : ''}\n'
            '${device.totalRamGb.toStringAsFixed(1)} GB RAM • '
            '${device.freeStorageGb.toStringAsFixed(1)} GB free • '
            '${device.architecture}',
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          const Text(
            'Requirements: iOS 16+ or Android 8+, a 64-bit ARM device, at least '
            '4 GB RAM, and 1–2 GB free storage. Performance varies by chipset '
            'and thermal conditions. A compatibility result is guidance, not '
            'a guarantee.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
