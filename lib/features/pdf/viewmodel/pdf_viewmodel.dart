import 'package:flutter/material.dart';
import '../repository/pdf_repository.dart';
import '../../documents/repository/document_repository.dart';
import '../../documents/viewmodel/documents_viewmodel.dart';
import '../../documents/model/document_item.dart';
import 'package:provider/provider.dart';

class PdfViewModel extends ChangeNotifier {
  final PdfRepository pdfRepo;
  final DocumentRepository docRepo;

  PdfViewModel(this.pdfRepo, this.docRepo);

  bool loading = false;
  String? lastPdfPath;

  Future<void> generateAndSavePdf(
    List<String> images,
    BuildContext context,
  ) async {
    loading = true;
    notifyListeners();

    try {
      final pdfPath = await pdfRepo.createPdfFromImages(images);
      lastPdfPath = pdfPath;

      final doc = docRepo.addDocument(
        pdfPath: pdfPath,
        pageCount: images.length,
      );

      final docsVm = Provider.of<DocumentsViewModel>(context, listen: false);
      docsVm.addDocument(doc);

      loading = false;
      notifyListeners();

      Navigator.pushNamed(context, '/pdfPreview', arguments: pdfPath);
    } catch (e) {
      loading = false;
      notifyListeners();
    }
  }
}
