import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../documents/viewmodel/documents_viewmodel.dart';
import '../../documents/model/document_item.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // load tài liệu từ Hive sau khi widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsViewModel>().loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final docsVm = context.watch<DocumentsViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xffF1F6FF),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff7065FF),
        onPressed: () {
          Navigator.pushNamed(context, '/scan');
        },
        child: const Icon(Icons.add, size: 32),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE
                    Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              "Trình chỉnh sửa PDF",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.workspace_premium,
                          color: Colors.orange,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.settings, size: 26),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Search Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      height: 50,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 22,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: docsVm.search,
                              decoration: const InputDecoration(
                                hintText: "Tìm tập tin",
                                border: InputBorder.none,
                                isCollapsed: true,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Tools
                    const Text(
                      "Công cụ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: _toolItem(
                              color: const Color(0xffFFB547),
                              icon: Icons.document_scanner,
                              title: "Máy quét",
                              onTap: () {
                                Navigator.pushNamed(context, '/scan');
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: _toolItem(
                              color: const Color(0xff37C5F5),
                              icon: Icons.folder_open,
                              title: "Tất cả \nTệp",
                              onTap: () {
                                // hiện tại Home đã là danh sách, bạn có thể sau này
                                // mở màn filter/manager riêng
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Tính năng Tất cả Tệp (TODO)",
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: _toolItem(
                              color: const Color(0xffA685FF),
                              icon: Icons.apps,
                              title: "Tất cả Công cụ",
                              onTap: () {
                                // TODO: mở màn Tools khi bạn làm
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(
                                //     content: Text(
                                //       "Tính năng Tất cả Công cụ (TODO)",
                                //     ),
                                //   ),
                                // );
                                Navigator.pushNamed(context, '/tools');
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Recent Files Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Tệp Gần đây",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Xem tất cả",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Recent documents list
            if (docsVm.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (docsVm.items.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("Chưa có tài liệu nào"),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = docsVm.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _recentDocumentItem(context, doc),
                    );
                  }, childCount: docsVm.items.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _toolItem({
    required Color color,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 5),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentDocumentItem(BuildContext context, DocumentItem doc) {
    final dateStr =
        "${doc.createdAt.day.toString().padLeft(2, '0')}/"
        "${doc.createdAt.month.toString().padLeft(2, '0')}/"
        "${doc.createdAt.year} "
        "${doc.createdAt.hour.toString().padLeft(2, '0')}:"
        "${doc.createdAt.minute.toString().padLeft(2, '0')}";

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/pdfPreview', arguments: doc.path);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Trang: ${doc.pageCount} • $dateStr",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () {
                _showDocMenu(context, doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDocMenu(BuildContext context, DocumentItem doc) {
    final docsVm = context.read<DocumentsViewModel>();
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text("Mở"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/pdfPreview',
                    arguments: doc.path,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Xoá"),
                onTap: () {
                  Navigator.pop(context);
                  docsVm.deleteDocument(doc.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
