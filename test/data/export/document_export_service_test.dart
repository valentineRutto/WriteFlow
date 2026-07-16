import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkdoc/data/export/document_export_service.dart';
import 'package:inkdoc/domain/models/scanned_document.dart';

void main() {
  const document = ScannedDocument(
    title: 'Lecture Notes',
    pages: [
      ScannedPage(number: 1, text: 'First page text.', confidence: 0.9),
      ScannedPage(number: 2, text: 'Second page text.', confidence: 0.8),
    ],
  );
  const service = DocumentExportService();

  test('creates a readable PDF document', () async {
    final exported = await service.export(document, DocumentExportFormat.pdf);

    expect(exported.fileName, 'Lecture_Notes.pdf');
    expect(exported.mimeType, 'application/pdf');
    expect(ascii.decode(exported.bytes.take(5).toList()), '%PDF-');
  });

  test(
    'creates an EPUB containing navigation and every scanned page',
    () async {
      final exported = await service.export(
        document,
        DocumentExportFormat.epub,
      );
      final archive = ZipDecoder().decodeBytes(exported.bytes);

      expect(exported.fileName, 'Lecture_Notes.epub');
      expect(archive.findFile('mimetype'), isNotNull);
      expect(archive.findFile('OEBPS/nav.xhtml'), isNotNull);
      expect(
        _contents(archive, 'OEBPS/page1.xhtml'),
        contains('First page text.'),
      );
      expect(
        _contents(archive, 'OEBPS/page2.xhtml'),
        contains('Second page text.'),
      );
    },
  );

  test('creates a DOCX containing every scanned page', () async {
    final exported = await service.export(document, DocumentExportFormat.docx);
    final archive = ZipDecoder().decodeBytes(exported.bytes);

    expect(exported.fileName, 'Lecture_Notes.docx');
    expect(archive.findFile('[Content_Types].xml'), isNotNull);
    final body = _contents(archive, 'word/document.xml');
    expect(body, contains('First page text.'));
    expect(body, contains('Second page text.'));
  });
}

String _contents(Archive archive, String path) {
  final file = archive.findFile(path)!;
  return utf8.decode(file.content as List<int>);
}
