import 'package:flutter/foundation.dart';

/// 照片多选状态交互控制器。
/// 
/// 该控制器与渲染层 (`PhotoGridView`) 完全解耦。宿主通过将此控制器传入 `PhotoGridView`
/// 来接管用户的点击、长按以及拖拽手势。网格在检测到对应手势后会调用本控制器的方法，
/// 从而集中进行选中状态的计算与下发（基于观察者模式），触发包含 `AnimatedBuilder` 的局部 UI 更新。
class PhotoSelectionController extends ChangeNotifier {
  final Set<String> _selectedIds = {};
  
  /// 当前已选中的全部照片元素的唯一标识符(ID)集合
  Set<String> get selectedIds => _selectedIds;

  bool _isSelectionActive = false;
  
  /// 当前是否处于多选激活模式。
  /// 通常在用户长按某张照片，或点击右上角“选择”按钮时，由宿主将其设置为 true。
  bool get isSelectionActive => _isSelectionActive;

  bool _isDragSelecting = true;
  Set<String> _baseSelectedIds = {};

  /// 明确开启或关闭多选模式。
  ///
  /// 如果由于关闭行为退出多选模式，会自动清空已选中的图片。
  void setSelectionActive(bool active) {
    if (_isSelectionActive != active) {
      _isSelectionActive = active;
      if (!active) _selectedIds.clear();
      notifyListeners();
    }
  }

  /// 翻转单张照片的选择状态 (选中转未选，未选转选中)
  /// 仅在单点模式下调用。
  void toggleItem(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  /// 拖拽框选开始。
  ///
  /// [anchorId] 是用户手指按下的起始项（抛锚点）。
  /// 引擎会根据起始项当前的选中状态，智能判断接下来的划动行为是“批量选择”还是“批量反选”。
  void startDragSelection(String anchorId) {
    if (!_isSelectionActive) {
      _isSelectionActive = true;
    }
    _baseSelectedIds = Set.from(_selectedIds);
    _isDragSelecting = !_selectedIds.contains(anchorId);

    if (_isDragSelecting) {
      _selectedIds.add(anchorId);
    } else {
      _selectedIds.remove(anchorId);
    }
    notifyListeners();
  }

  /// 拖拽范围更新。
  ///
  /// [affectedIds] 表示滑动边界框所覆盖的当前全部 ID。
  /// 引擎会自动将其覆盖到 [startDragSelection] 时记录的 _baseSelectedIds 快照上。
  void updateDragSelection(Set<String> affectedIds) {
    _selectedIds.clear();
    _selectedIds.addAll(_baseSelectedIds);

    if (_isDragSelecting) {
      _selectedIds.addAll(affectedIds);
    } else {
      _selectedIds.removeAll(affectedIds);
    }
    notifyListeners();
  }

  /// 释放手指，结束拖拽框选过程。
  /// 会清理底层缓存的选中快照。
  void endDragSelection() {
    _baseSelectedIds.clear();
  }

  /// 批量全选列表图片
  void selectAll(List<String> allIds) {
    _selectedIds.addAll(allIds);
    notifyListeners();
  }

  /// 清空当前选中列表
  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }
}
