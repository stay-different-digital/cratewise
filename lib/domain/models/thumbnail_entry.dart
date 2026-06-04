class ThumbnailEntry {
  const ThumbnailEntry({
    required this.releaseId,
    required this.lastModified,
    required this.sizeBytes,
  });

  final int releaseId;
  final DateTime lastModified;
  final int sizeBytes;
}
