import 'package:flutter_test/flutter_test.dart';
import 'package:writeflow/domain/models/scanned_document.dart';
import 'package:writeflow/domain/repositories/scan_repository.dart';
import 'package:writeflow/presentation/view_models/scan_view_model.dart';

void main() {
  test('scan delegates selected options to the injected repository', () async {
    final repository = _FakeScanRepository();
    final viewModel = ScanViewModel(repository: repository);

    viewModel.selectDocumentType(2);
    viewModel.setBatchMode(true);

    final document = await viewModel.scan();

    expect(repository.documentTypeIndex, 2);
    expect(repository.batchMode, isTrue);
    expect(document?.pages, hasLength(2));
    expect(viewModel.status, ScanStatus.completed);
  });
}

class _FakeScanRepository implements ScanRepository {
  int? documentTypeIndex;
  bool? batchMode;

  @override
  Future<ScannedDocument> scan({
    required int documentTypeIndex,
    required bool batchMode,
  }) async {
    this.documentTypeIndex = documentTypeIndex;
    this.batchMode = batchMode;

    return const ScannedDocument(
      title: 'Test document',
      pages: [
        ScannedPage(number: 1, text: 'First page', confidence: 0.9),
        ScannedPage(number: 2, text: 'Second page', confidence: 0.8),
      ],
    );
  }
}
