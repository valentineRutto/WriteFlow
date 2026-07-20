import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/models/library_document.dart';
import '../../domain/models/scanned_document.dart';
import '../../domain/repositories/library_repository.dart';

class LocalLibraryRepository implements LibraryRepository {
  LocalLibraryRepository({Future<Database>? database})
    : _database = database ?? _openDatabase();

  final Future<Database> _database;

  static Future<Database> _openDatabase() async {
    final path = '${await getDatabasesPath()}/inkdoc.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (database, _) => database.execute('''
        CREATE TABLE documents (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          page_count INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          payload TEXT NOT NULL
        )
      '''),
    );
  }

  @override
  Future<List<LibraryDocument>> loadDocuments({
    int offset = 0,
    int limit = 20,
    String query = '',
  }) async {
    final database = await _database;
    final normalized = query.trim();
    final rows = await database.query(
      'documents',
      columns: ['id', 'title', 'category', 'page_count', 'created_at'],
      where: normalized.isEmpty ? null : '(title LIKE ? OR category LIKE ?)',
      whereArgs: normalized.isEmpty ? null : ['%$normalized%', '%$normalized%'],
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_libraryDocumentFromRow).toList(growable: false);
  }

  @override
  Future<void> saveDocument(
    ScannedDocument document, {
    String? category,
  }) async {
    final database = await _database;
    await database.insert('documents', {
      'title': document.title,
      'category': category?.trim().isNotEmpty == true
          ? category!.trim()
          : 'Scanned',
      'page_count': document.pages.length,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'payload': jsonEncode(_documentToJson(document)),
    });
  }

  @override
  Future<ScannedDocument?> loadDocument(int id) async {
    final database = await _database;
    final rows = await database.query(
      'documents',
      columns: ['payload'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _documentFromJson(
      jsonDecode(rows.single['payload']! as String) as Map<String, dynamic>,
    );
  }

  LibraryDocument _libraryDocumentFromRow(Map<String, Object?> row) {
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      row['created_at']! as int,
    );
    final pages = row['page_count']! as int;
    return LibraryDocument(
      id: row['id']! as int,
      title: row['title']! as String,
      category: row['category']! as String,
      meta:
          '$pages ${pages == 1 ? 'page' : 'pages'} - Saved ${_date(createdAt)}',
    );
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

Map<String, Object?> _documentToJson(ScannedDocument document) => {
  'title': document.title,
  'pdfUri': document.pdfUri,
  'engine': document.engine,
  'pages': document.pages
      .map(
        (page) => {
          'number': page.number,
          'text': page.text,
          'rawText': page.rawText,
          'imageUri': page.imageUri,
          'aiEngine': page.aiEngine,
          'confidence': page.confidence,
          'lowConfidencePhrases': page.lowConfidencePhrases,
          'contentBlocks': page.contentBlocks
              .map(
                (block) => {
                  'type': block.type.name,
                  'text': block.text,
                  'confidence': block.confidence,
                },
              )
              .toList(),
        },
      )
      .toList(),
};

ScannedDocument _documentFromJson(Map<String, dynamic> json) => ScannedDocument(
  title: json['title'] as String,
  pdfUri: json['pdfUri'] as String?,
  engine: json['engine'] as String? ?? 'InkDoc local database',
  pages: (json['pages'] as List<dynamic>)
      .map((value) {
        final page = value as Map<String, dynamic>;
        return ScannedPage(
          number: page['number'] as int,
          text: page['text'] as String,
          rawText: page['rawText'] as String?,
          imageUri: page['imageUri'] as String?,
          aiEngine: page['aiEngine'] as String?,
          confidence: (page['confidence'] as num).toDouble(),
          lowConfidencePhrases: List<String>.from(
            page['lowConfidencePhrases'] as List<dynamic>? ?? const [],
          ),
          contentBlocks: (page['contentBlocks'] as List<dynamic>? ?? const [])
              .map((value) {
                final block = value as Map<String, dynamic>;
                return ScannedContentBlock(
                  type: ScannedContentType.values.byName(
                    block['type'] as String,
                  ),
                  text: block['text'] as String,
                  confidence: (block['confidence'] as num).toDouble(),
                );
              })
              .toList(growable: false),
        );
      })
      .toList(growable: false),
);
