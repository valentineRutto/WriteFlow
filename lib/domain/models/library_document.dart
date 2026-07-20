class LibraryDocument {
  const LibraryDocument({
    this.id,
    required this.title,
    required this.meta,
    required this.category,
  });

  final int? id;
  final String title;
  final String meta;
  final String category;
}
