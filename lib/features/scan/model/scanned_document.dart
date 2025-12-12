// lib/features/scan/model/scanned_document.dart
class ScannedDocument {
  final List<String> imagePaths;
  final bool hasPdf;

  ScannedDocument({required this.imagePaths, required this.hasPdf});
}
