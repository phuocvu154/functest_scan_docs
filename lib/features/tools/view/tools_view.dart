import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/tools_viewmodel.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ToolsViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Tools', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Example section: Convert from PDF
              const SizedBox(height: 6),
              const SectionTitle(title: 'Convert from PDF'),
              const SizedBox(height: 8),
              ToolWrap(
                children: [
                  ToolTile(
                    color: const Color(0xffE7F9E9),
                    icon: Icons.image,
                    label: 'PDF thành JPG',
                    onTap: () {
                      // TODO: action
                    },
                  ),
                  ToolTile(
                    color: const Color(0xffE8F4FF),
                    icon: Icons.image_outlined,
                    label: 'PDF thành PNG',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffE6FCFF),
                    icon: Icons.description_outlined,
                    label: 'PDF sang Word',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffFFE6EE),
                    icon: Icons.table_chart_outlined,
                    label: 'PDF sang Excel',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const SectionTitle(title: 'Convert to PDF'),
              const SizedBox(height: 8),
              ToolWrap(
                children: [
                  ToolTile(
                    color: const Color(0xffFFF0F0),
                    icon: Icons.photo_library_outlined,
                    label: 'Ảnh sang PDF',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffF3FFE8),
                    icon: Icons.description,
                    label: 'Word sang PDF',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffEEF7FF),
                    icon: Icons.grid_view,
                    label: 'Excel sang PDF',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffFFF3F6),
                    icon: Icons.slideshow,
                    label: 'Powerpoint sang PDF',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const SectionTitle(title: 'Scanner'),
              const SizedBox(height: 8),
              ToolWrap(
                children: [
                  ToolTile(
                    color: const Color(0xffE8F6FF),
                    icon: Icons.camera_alt_outlined,
                    label: 'Máy quét',
                    onTap: () {
                      Navigator.pushNamed(context, '/scan');
                    },
                  ),
                  ToolTile(
                    color: const Color(0xffE8F6FF),
                    icon: Icons.contact_page_outlined,
                    label: 'Danh thiếp',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffF3E9FF),
                    icon: Icons.straighten_outlined,
                    label: 'Đo lường',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const SectionTitle(title: 'Security'),
              const SizedBox(height: 8),
              ToolWrap(
                children: [
                  ToolTile(
                    color: const Color(0xffFFF1F1),
                    icon: Icons.lock_outline,
                    label: 'Khóa',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffF1F3FF),
                    icon: Icons.lock_open_outlined,
                    label: 'Mở khóa',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffFFF6E8),
                    icon: Icons.brush_outlined,
                    label: 'Chữ ký ảnh',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffE8FFF3),
                    icon: Icons.crop_square_outlined,
                    label: 'Redact',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const SectionTitle(title: 'Organize'),
              const SizedBox(height: 8),
              ToolWrap(
                children: [
                  ToolTile(
                    color: const Color(0xffFFEAF6),
                    icon: Icons.merge_type,
                    label: 'Hợp nhất',
                    onTap: () {
                      // ví dụ gọi ViewModel
                      vm.onMergeTap();
                    },
                  ),
                  ToolTile(
                    color: const Color(0xffFFF7E6),
                    icon: Icons.call_split,
                    label: 'Tách ra',
                    onTap: () {
                      vm.onSplitTap();
                    },
                  ),
                  ToolTile(
                    color: const Color(0xffF2E8FF),
                    icon: Icons.rotate_left,
                    label: 'Quay',
                    onTap: () {},
                  ),
                  ToolTile(
                    color: const Color(0xffF6EEFF),
                    icon: Icons.format_list_numbered,
                    label: 'Số trang',
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 40),
              if (vm.busy) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helpers below

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

/// Wrap container for responsive tiles
class ToolWrap extends StatelessWidget {
  final List<Widget> children;
  const ToolWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: children);
  }
}

/// Tile widget used across ToolsView
class ToolTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ToolTile({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // tile width responsive: two columns on phone, full width on narrow?
    final w = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;
    return SizedBox(
      width: w,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: Colors.black87),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
