import 'package:flutter/foundation.dart';

class ToolsViewModel extends ChangeNotifier {
  bool busy = false;
  String? lastResultPath;
  String? error;

  // Ví dụ các hành động - hiện là placeholder
  Future<void> onMergeTap() async {
    busy = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    busy = false;
    notifyListeners();
  }

  Future<void> onSplitTap() async {
    busy = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    busy = false;
    notifyListeners();
  }

  Future<void> onCompressTap() async {
    busy = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    busy = false;
    notifyListeners();
  }

  // Thêm các hàm thao tác thực tế ở đây (gọi repository)
}
