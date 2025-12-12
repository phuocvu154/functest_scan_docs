import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'features/scan/view/scan_view.dart';
import 'features/scan/viewmodel/scan_viewmodel.dart';

import 'features/pdf/view/pdf_preview_view.dart';
import 'features/pdf/viewmodel/pdf_viewmodel.dart';
import 'features/pdf/repository/pdf_repository.dart';

import 'features/documents/model/document_item.dart';
import 'features/documents/repository/document_repository.dart';
import 'features/documents/viewmodel/documents_viewmodel.dart';
import 'features/home/view/home_view.dart';
import 'features/tools/viewmodel/tools_viewmodel.dart';
import 'features/tools/view/tools_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentItemAdapter());
  final docsBox = await Hive.openBox<DocumentItem>('documents_box');

  final docRepo = DocumentRepository(docsBox);

  runApp(App(docRepo: docRepo));
}

class App extends StatelessWidget {
  final DocumentRepository docRepo;

  const App({super.key, required this.docRepo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScanViewModel()),
        ChangeNotifierProvider(create: (_) => DocumentsViewModel(docRepo)),
        ChangeNotifierProvider(
          create: (_) => PdfViewModel(PdfRepository(), docRepo),
        ),
        ChangeNotifierProvider(create: (_) => ToolsViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PDF Scanner Demo',
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        home: const HomeView(), // <-- dùng HomeView đẹp + gộp Documents
        routes: {
          '/scan': (_) => const ScanView(),
          '/pdfPreview': (context) {
            final path = ModalRoute.of(context)!.settings.arguments as String;
            return PdfPreviewView(path: path);
          },
          '/tools': (_) => const ToolsView(),
        },
      ),
    );
  }
}
