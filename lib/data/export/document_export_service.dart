import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/scanned_document.dart';

enum DocumentExportFormat { pdf, epub, docx }

class ExportedDocument {
  const ExportedDocument({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

class DocumentExportService {
  const DocumentExportService();

  Future<ExportedDocument> export(
    ScannedDocument document,
    DocumentExportFormat format,
  ) async {
    if (document.pages.isEmpty) {
      throw StateError('There are no scanned pages to export.');
    }

    final baseName = _safeFileName(document.title);
    return switch (format) {
      DocumentExportFormat.pdf => ExportedDocument(
        fileName: '$baseName.pdf',
        mimeType: 'application/pdf',
        bytes: await _buildPdf(document),
      ),
      DocumentExportFormat.epub => ExportedDocument(
        fileName: '$baseName.epub',
        mimeType: 'application/epub+zip',
        bytes: _buildEpub(document),
      ),
      DocumentExportFormat.docx => ExportedDocument(
        fileName: '$baseName.docx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        bytes: _buildDocx(document),
      ),
    };
  }

  Future<Uint8List> _buildPdf(ScannedDocument document) async {
    final pdf = pw.Document(title: document.title, author: 'InkDoc');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        header: (context) => pw.Text(
          document.title,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.Text(
            document.title,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          for (final page in document.pages) ...[
            pw.Text(
              'Scanned page ${page.number}',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(page.text, style: const pw.TextStyle(fontSize: 11)),
            if (page != document.pages.last) pw.NewPage(),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  Uint8List _buildEpub(ScannedDocument document) {
    final archive = Archive();
    archive.addFile(
      ArchiveFile.noCompress(
        'mimetype',
        'application/epub+zip'.length,
        utf8.encode('application/epub+zip'),
      ),
    );
    _addTextFile(
      archive,
      'META-INF/container.xml',
      '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''',
    );

    final manifest = StringBuffer();
    final spine = StringBuffer();
    final nav = StringBuffer();
    for (var index = 0; index < document.pages.length; index++) {
      final page = document.pages[index];
      final id = 'page${index + 1}';
      manifest.writeln(
        '<item id="$id" href="$id.xhtml" media-type="application/xhtml+xml"/>',
      );
      spine.writeln('<itemref idref="$id"/>');
      nav.writeln('<li><a href="$id.xhtml">Page ${page.number}</a></li>');
      _addTextFile(archive, 'OEBPS/$id.xhtml', _epubPage(document.title, page));
    }

    _addTextFile(
      archive,
      'OEBPS/nav.xhtml',
      '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>${_xml(document.title)}</title></head>
<body><nav epub:type="toc"><h1>${_xml(document.title)}</h1><ol>$nav</ol></nav></body>
</html>''',
    );
    _addTextFile(
      archive,
      'OEBPS/content.opf',
      '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">urn:uuid:${_documentId(document)}</dc:identifier>
    <dc:title>${_xml(document.title)}</dc:title>
    <dc:language>en</dc:language>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    $manifest
  </manifest>
  <spine>$spine</spine>
</package>''',
    );

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Uint8List _buildDocx(ScannedDocument document) {
    final archive = Archive();
    _addTextFile(
      archive,
      '[Content_Types].xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''',
    );
    _addTextFile(
      archive,
      '_rels/.rels',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''',
    );

    final body = StringBuffer()
      ..write(_docxParagraph(document.title, heading: true));
    for (var index = 0; index < document.pages.length; index++) {
      final page = document.pages[index];
      body.write(_docxParagraph('Scanned page ${page.number}', heading: true));
      for (final paragraph in page.text.split(RegExp(r'\n+'))) {
        body.write(_docxParagraph(paragraph));
      }
      if (index < document.pages.length - 1) {
        body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }
    }
    _addTextFile(
      archive,
      'word/document.xml',
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>$body<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body>
</w:document>''',
    );
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}

void _addTextFile(Archive archive, String path, String contents) {
  final bytes = utf8.encode(contents);
  archive.addFile(ArchiveFile(path, bytes.length, bytes));
}

String _epubPage(String title, ScannedPage page) {
  final paragraphs = page.text
      .split(RegExp(r'\n+'))
      .map((text) => '<p>${_xml(text)}</p>')
      .join();
  return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${_xml(title)} - Page ${page.number}</title></head>
<body><h1>Scanned page ${page.number}</h1>$paragraphs</body>
</html>''';
}

String _docxParagraph(String text, {bool heading = false}) {
  final style = heading ? '<w:rPr><w:b/><w:sz w:val="30"/></w:rPr>' : '';
  return '<w:p><w:r>$style<w:t xml:space="preserve">${_xml(text)}</w:t></w:r></w:p>';
}

String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

String _safeFileName(String value) {
  final safe = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  return safe.isEmpty ? 'InkDoc_scan' : safe;
}

String _documentId(ScannedDocument document) =>
    '${document.title.hashCode.abs()}-${document.pages.length}-${document.pages.fold<int>(0, (sum, page) => sum + page.text.hashCode).abs()}';
