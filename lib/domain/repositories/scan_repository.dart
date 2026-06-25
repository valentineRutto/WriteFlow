import '../models/scanned_document.dart';

abstract interface class ScanRepository {
  Future<ScannedDocument> scan({
    required int documentTypeIndex,
    required bool batchMode,
  });
}
