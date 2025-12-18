import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// pdf (tạo PDF)
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// pdf_render_maintained (đọc/render PDF) — GẮN PREFIX
import 'package:pdf_render_maintained/pdf_render.dart' as pdf_render;

/// PDF Tools Repository
/// FINAL FINAL – compatible pdf_render_maintained 1.6.1
class PdfToolsRepository {
  /// Merge nhiều PDF thành 1 PDF
  Future<String> mergePdfs(
    List<String> inputPdfPaths, {
    void Function(double progress)? onProgress,
    int jpegQuality = 90,
  }) async {
    if (inputPdfPaths.isEmpty) {
      throw ArgumentError('inputPdfPaths is empty');
    }

    // Đếm tổng số trang để báo progress
    int totalPages = 0;
    for (final path in inputPdfPaths) {
      final pdf_render.PdfDocument doc = await pdf_render.PdfDocument.openFile(
        path,
      );
      totalPages += doc.pageCount;
      doc.dispose(); // SYNC
    }

    final pw.Document outDoc = pw.Document();
    int processed = 0;

    for (final path in inputPdfPaths) {
      final pdf_render.PdfDocument doc = await pdf_render.PdfDocument.openFile(
        path,
      );
      try {
        for (int i = 1; i <= doc.pageCount; i++) {
          final pdf_render.PdfPage page = await doc.getPage(i);
          try {
            final pdf_render.PdfPageImage pageImage = await page.render(
              width: page.width.toInt(),
              height: page.height.toInt(),
            );

            try {
              final Uint8List jpgBytes = await _renderPageToJpeg(
                pageImage,
                jpegQuality,
              );

              final double w = pageImage.width.toDouble();
              final double h = pageImage.height.toDouble();

              outDoc.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat(w, h),
                  build: (_) => pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(jpgBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              );
            } finally {
              pageImage.dispose(); // SYNC
            }
          } finally {
            // page.close(); // SYNC (đúng API 1.6.1)
          }

          processed++;
          if (onProgress != null && totalPages > 0) {
            onProgress(processed / totalPages);
          }
        }
      } finally {
        doc.dispose(); // SYNC
      }
    }

    final String outPath = await _createOutputPath('merged');
    await File(outPath).writeAsBytes(await outDoc.save());
    return outPath;
  }

  /// Split PDF thành các PDF 1 trang
  Future<List<String>> splitPdf(String srcPdf) async {
    final pdf_render.PdfDocument doc = await pdf_render.PdfDocument.openFile(
      srcPdf,
    );
    final List<String> outputs = [];

    try {
      for (int i = 1; i <= doc.pageCount; i++) {
        final pdf_render.PdfPage page = await doc.getPage(i);
        try {
          final pdf_render.PdfPageImage pageImage = await page.render(
            width: page.width.toInt(),
            height: page.height.toInt(),
          );

          try {
            final Uint8List jpg = await _renderPageToJpeg(pageImage, 90);

            final pw.Document pdf = pw.Document();
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(
                  pageImage.width.toDouble(),
                  pageImage.height.toDouble(),
                ),
                build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(jpg))),
              ),
            );

            final String outPath = await _createOutputPath('page_$i');
            await File(outPath).writeAsBytes(await pdf.save());
            outputs.add(outPath);
          } finally {
            pageImage.dispose();
          }
        } finally {
          // page.close();
        }
      }
    } finally {
      doc.dispose();
    }

    return outputs;
  }

  // ========================
  // INTERNAL HELPERS
  // ========================

  Future<Uint8List> _renderPageToJpeg(
    pdf_render.PdfPageImage pageImage,
    int quality,
  ) {
    return compute<Map<String, dynamic>, Uint8List>(_encodeJpegIsolate, {
      'rgba': pageImage.pixels.buffer.asUint8List(),
      'w': pageImage.width,
      'h': pageImage.height,
      'quality': quality,
    });
  }

  Future<String> _createOutputPath(String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}

// ========================
// ISOLATE
// ========================

Future<Uint8List> _encodeJpegIsolate(Map<String, dynamic> args) async {
  final Uint8List rgba = args['rgba'] as Uint8List;
  final int w = args['w'] as int;
  final int h = args['h'] as int;
  final int quality = args['quality'] as int;

  final img.Image image = img.Image.fromBytes(
    width: w,
    height: h,
    bytes: rgba.buffer,
    numChannels: 4, // RGBA
  );

  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}
