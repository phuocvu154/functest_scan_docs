// lib/features/tools/repository/pdf_tools_repository.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'; // compute
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_render_maintained/pdf_render.dart';
import 'package:image/image.dart' as img;

/// Simple cancellation token
class CancelToken {
  bool _canceled = false;
  bool get isCanceled => _canceled;
  void cancel() => _canceled = true;
}

/// Progress callback value in range 0.0 .. 1.0
typedef ProgressCallback = void Function(double progress);

/// Production-ready PDF tools repository for pdf_render_maintained 1.6.1
class PdfToolsRepository {
  PdfToolsRepository();

  /// Merge many PDFs into one PDF.
  /// - inputPdfPaths: list of absolute paths to PDF files
  /// - onProgress: optional progress callback 0..1
  /// - cancelToken: optional token to cancel operation
  /// - jpegQuality: quality used when encoding page images (1..100)
  Future<String> mergePdfs(
    List<String> inputPdfPaths, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    int jpegQuality = 90,
  }) async {
    if (inputPdfPaths.isEmpty) {
      throw ArgumentError('inputPdfPaths must not be empty');
    }

    // First pass: count total pages for progress
    int totalPages = 0;
    for (final pth in inputPdfPaths) {
      final d = await PdfDocument.openFile(pth);
      totalPages += d.pageCount;
      await d.dispose();
      if (cancelToken?.isCanceled == true) throw Exception('merge canceled');
    }

    final pw.Document outDoc = pw.Document();
    int processed = 0;

    // Process files sequentially (keeps memory usage low)
    for (final path in inputPdfPaths) {
      final PdfDocument doc = await PdfDocument.openFile(path);
      try {
        final int pageCount = doc.pageCount;
        for (int pageIndex = 1; pageIndex <= pageCount; pageIndex++) {
          if (cancelToken?.isCanceled == true)
            throw Exception('merge canceled');

          final PdfPage page = await doc.getPage(pageIndex);
          try {
            // IMPORTANT: pdf_render_maintained 1.6.1 -> render() has no named 'format' parameter.
            final PdfPageImage pageImage = await page.render(
              width: page.width.toInt(),
              height: page.height.toInt(),
            );

            try {
              // Convert whatever pageImage provides into JPEG bytes (Uint8List)
              final Uint8List jpgBytes = await _pageImageToJpegBytes(
                pageImage,
                jpegQuality,
              );

              // Add image as a page in output PDF
              final mem = pw.MemoryImage(jpgBytes);
              outDoc.addPage(
                pw.Page(
                  pageFormat: pw.PageFormat(
                    pageImage.width.toDouble(),
                    pageImage.height.toDouble(),
                  ),
                  build: (ctx) => pw.Center(child: pw.Image(mem)),
                ),
              );
            } finally {
              // Dispose pageImage ASAP
              try {
                pageImage.dispose();
              } catch (_) {}
            }
          } finally {
            // Dispose page
            try {
              await page.dispose();
            } catch (_) {}
          }

          processed++;
          if (onProgress != null && totalPages > 0) {
            onProgress(processed / totalPages);
          }
        }
      } finally {
        try {
          await doc.dispose();
        } catch (_) {}
      }
    }

    // save outDoc
    final outPath = await _createOutputFilePath('merged');
    final f = File(outPath);
    await f.writeAsBytes(await outDoc.save());
    return outPath;
  }

  /// Split a PDF into separate one-page PDFs.
  /// Returns list of produced file paths.
  Future<List<String>> splitPdfToSinglePages(
    String srcPdf, {
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    int jpegQuality = 92,
  }) async {
    final PdfDocument doc = await PdfDocument.openFile(srcPdf);
    final int pageCount = doc.pageCount;
    final List<String> outPaths = [];

    try {
      for (int i = 1; i <= pageCount; i++) {
        if (cancelToken?.isCanceled == true) throw Exception('split canceled');

        final PdfPage page = await doc.getPage(i);
        try {
          final PdfPageImage pageImage = await page.render(
            width: page.width.toInt(),
            height: page.height.toInt(),
          );

          try {
            final Uint8List jpgBytes = await _pageImageToJpegBytes(
              pageImage,
              jpegQuality,
            );

            final pdf = pw.Document();
            pdf.addPage(
              pw.Page(
                pageFormat: pw.PageFormat(
                  pageImage.width.toDouble(),
                  pageImage.height.toDouble(),
                ),
                build: (ctx) =>
                    pw.Center(child: pw.Image(pw.MemoryImage(jpgBytes))),
              ),
            );

            final outPath = await _createOutputFilePath('split_page_$i');
            await File(outPath).writeAsBytes(await pdf.save());
            outPaths.add(outPath);
          } finally {
            try {
              pageImage.dispose();
            } catch (_) {}
          }
        } finally {
          try {
            await page.dispose();
          } catch (_) {}
        }

        if (onProgress != null) onProgress(i / pageCount);
      }
    } finally {
      await doc.dispose();
    }

    return outPaths;
  }

  /// Compress PDF by rendering each page and re-encoding with JPEG compression and optional resize.
  /// - quality: JPEG quality 1..100
  /// - maxWidth: if >0, resize image width to maxWidth keeping aspect ratio
  Future<String> compressPdf(
    String srcPdf, {
    int quality = 70,
    int maxWidth = 1200,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final PdfDocument doc = await PdfDocument.openFile(srcPdf);
    final int pageCount = doc.pageCount;
    final pw.Document outDoc = pw.Document();

    try {
      for (int i = 1; i <= pageCount; i++) {
        if (cancelToken?.isCanceled == true)
          throw Exception('compress canceled');

        final PdfPage page = await doc.getPage(i);
        try {
          final PdfPageImage pageImage = await page.render(
            width: page.width.toInt(),
            height: page.height.toInt(),
          );

          try {
            // Convert page image (bytes or pixels) -> raw RGBA if needed, then resize+encode in isolate
            final Uint8List jpgBytes = await _pageImageToJpegBytes(
              pageImage,
              quality,
              maxWidth: maxWidth,
            );

            outDoc.addPage(
              pw.Page(
                pageFormat: pw.PageFormat(
                  pageImage.width.toDouble(),
                  pageImage.height.toDouble(),
                ),
                build: (ctx) =>
                    pw.Center(child: pw.Image(pw.MemoryImage(jpgBytes))),
              ),
            );
          } finally {
            try {
              pageImage.dispose();
            } catch (_) {}
          }
        } finally {
          try {
            await page.dispose();
          } catch (_) {}
        }

        if (onProgress != null) onProgress(i / pageCount);
      }
    } finally {
      await doc.dispose();
    }

    final outPath = await _createOutputFilePath('compressed');
    await File(outPath).writeAsBytes(await outDoc.save());
    return outPath;
  }

  /// Generate thumbnail JPEG from a PDF (pageNumber is 1-based)
  Future<String> generateThumbnail(
    String pdfPath, {
    int pageNumber = 1,
    int width = 400,
    ProgressCallback? onProgress,
  }) async {
    final PdfDocument doc = await PdfDocument.openFile(pdfPath);
    try {
      final int pageCount = doc.pageCount;
      if (pageNumber < 1) pageNumber = 1;
      if (pageNumber > pageCount) pageNumber = pageCount;

      final PdfPage page = await doc.getPage(pageNumber);
      try {
        final double scale = width / page.width;
        final int targetW = (page.width * scale).round();
        final int targetH = (page.height * scale).round();

        final PdfPageImage pageImage = await page.render(
          width: targetW,
          height: targetH,
        );

        try {
          final Uint8List jpgBytes = await _pageImageToJpegBytes(pageImage, 85);

          final outPath = await _createOutputFilePath('thumb');
          await File(outPath).writeAsBytes(jpgBytes);
          if (onProgress != null) onProgress(1.0);
          return outPath;
        } finally {
          try {
            pageImage.dispose();
          } catch (_) {}
        }
      } finally {
        try {
          await page.dispose();
        } catch (_) {}
      }
    } finally {
      await doc.dispose();
    }
  }

  // -------------------------
  // Internal helpers
  // -------------------------

  Future<String> _createOutputFilePath(String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    return p.join(dir.path, filename);
  }

  /// Convert PdfPageImage to JPEG bytes (possibly resizing).
  /// If pageImage.bytes exists (PNG/JPEG), we may decode/re-encode to change quality/resize.
  /// If pageImage.pixels exists (ByteData raw RGBA), we use that directly.
  Future<Uint8List> _pageImageToJpegBytes(
    PdfPageImage pageImage,
    int quality, {
    int? maxWidth,
  }) async {
    // First try direct bytes (common: PNG/JPEG)
    try {
      final dynamic maybeBytes = pageImage.bytes;
      if (maybeBytes is Uint8List && maybeBytes.isNotEmpty) {
        // If no resize and default quality, return as-is (if it's JPEG).
        // But often pageImage.bytes is PNG; to change quality or resize we should decode & re-encode.
        if (maxWidth == null && quality >= 90) {
          // try to return as-is if it is already JPEG and quality high
          // We cannot detect directly here; safe approach is to decode+encode in isolate anyway
          // We'll decode & encode in isolate to ensure consistent JPEG output
        }

        // Decode bytes into raw RGBA and then encode in isolate (handles resize + quality)
        final Uint8List decodedRgba = await compute<_DecodeArgs, Uint8List>(
          _decodeImageToRgba,
          _DecodeArgs(maybeBytes, null),
        );

        // Now call encoder isolate to produce JPEG with quality and optional maxWidth
        final Map<String, dynamic> encArgs = {
          'rgba': decodedRgba,
          'w': pageImage.width,
          'h': pageImage.height,
          'quality': quality,
          'maxWidth': maxWidth,
        };

        final Uint8List jpg = await compute<Map<String, dynamic>, Uint8List>(
          _encodeMapToJpg,
          encArgs,
        );
        return jpg;
      }
    } catch (_) {
      // fall through to pixels handling
    }

    // Fallback: use raw pixels (ByteData, Uint8List, List<int>)
    final dynamic pixels = pageImage.pixels;
    if (pixels == null) {
      throw Exception('PdfPageImage has neither bytes nor pixels');
    }

    Uint8List rgba;
    if (pixels is ByteData) {
      rgba = pixels.buffer.asUint8List();
    } else if (pixels is Uint8List) {
      rgba = pixels;
    } else if (pixels is List<int>) {
      rgba = Uint8List.fromList(List<int>.from(pixels));
    } else {
      // try buffer property
      try {
        final buf = (pixels as dynamic).buffer;
        if (buf is ByteBuffer) {
          rgba = buf.asUint8List();
        } else {
          throw Exception('Unsupported pixels type: ${pixels.runtimeType}');
        }
      } catch (e) {
        throw Exception('Unsupported pixels type: ${pixels.runtimeType}');
      }
    }

    // Encode (possibly resize) in isolate
    final Map<String, dynamic> encArgs = {
      'rgba': rgba,
      'w': pageImage.width,
      'h': pageImage.height,
      'quality': quality,
      'maxWidth': maxWidth,
    };

    final Uint8List jpg = await compute<Map<String, dynamic>, Uint8List>(
      _encodeMapToJpg,
      encArgs,
    );
    return jpg;
  }
}

// -------------------------
// Top-level isolate helpers
// -------------------------

/// Decode an image (PNG/JPEG bytes) into raw RGBA Uint8List (for passing to encoder isolate).
/// Input: Map with {'bytes': Uint8List, 'targetMaxWidth': int?}
Future<Uint8List> _decodeImageToRgba(_DecodeArgs args) async {
  final Uint8List bytes = args.bytes;
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) throw Exception('Failed to decode image bytes');

  // produce RGBA bytes
  final rgba = decoded.getBytes(format: img.Format.rgba);
  return Uint8List.fromList(rgba);
}

class _DecodeArgs {
  final Uint8List bytes;
  final int? maxWidth;
  _DecodeArgs(this.bytes, this.maxWidth);
}

/// Encoder isolate top-level function.
/// Receives a Map<String, dynamic>:
/// {
///   'rgba': Uint8List,
///   'w': int,
///   'h': int,
///   'quality': int,
///   'maxWidth': int?
/// }
Future<Uint8List> _encodeMapToJpg(Map<String, dynamic> map) async {
  final Uint8List rgba = map['rgba'] as Uint8List;
  final int w = map['w'] as int;
  final int h = map['h'] as int;
  final int quality = map['quality'] as int;
  final int? maxWidth = map['maxWidth'] as int?;

  // Build image
  img.Image image;
  try {
    image = img.Image.fromBytes(w, h, rgba, numChannels: 4);
  } catch (_) {
    image = img.Image.fromBytes(w, h, rgba);
  }

  // Resize if requested
  if (maxWidth != null && maxWidth > 0 && image.width > maxWidth) {
    final int newH = (image.height * (maxWidth / image.width)).round();
    image = img.copyResize(image, width: maxWidth, height: newH);
  }

  final List<int> jpg = img.encodeJpg(image, quality: quality);
  return Uint8List.fromList(jpg);
}
