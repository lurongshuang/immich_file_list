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
  bool get isSelectionActive => _isSelectionActive;

  /// 当前处于焦点（Focus ring）状态的项目角标。用于键盘导航。
  int? _focusedIndex;
  int? get focusedIndex => _focusedIndex;

  /// 上一次用户手动点击（非拖拽）选中的项目角标。作为 Shift 连选的基点锚点。
  int? _selectionAnchorIndex;
  int? get selectionAnchorIndex => _selectionAnchorIndex;

  bool _isDragSelecting = true;
  Set<String> _baseSelectedIds = {};

  /// 更新焦点角标。
  void setFocusedIndex(int? index) {
    if (_focusedIndex != index) {
      _focusedIndex = index;
      notifyListeners();
    }
  }

  /// 明确开启或关闭多选模式。
  void setSelectionActive(bool active) {
    if (_isSelectionActive != active) {
      _isSelectionActive = active;
      if (!active) {
        _selectedIds.clear();
        _selectionAnchorIndex = null;
      }
      notifyListeners();
    }
  }

  /// 翻转单张照片的选择状态。
  /// [index] 可选，用于更新锚点位置。
  void toggleItem(String id, {int? index}) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
      if (index != null) _selectionAnchorIndex = index;
    }
    notifyListeners();
  }

  /// 选中单张照片。
  void selectItem(String id, {int? index}) {
    _selectedIds.add(id);
    if (index != null) _selectionAnchorIndex = index;
    notifyListeners();
  }

  /// 连选范围内的项目。
  /// [allIds] 是完整的、有序的 ID 列表，用于获取 [start] 到 [end] 的元素。
  /// [additive] 为 true 时，保留之前的选中状态；为 false 时，先清空。
  void selectRange(int start, int end, List<String> allIds, {bool additive = false}) {
    if (!additive) _selectedIds.clear();
    
    final s = start < end ? start : end;
    final e = start > end ? start : end;

    for (int i = s; i <= e; i++) {
      if (i >= 0 && i < allIds.length) {
        _selectedIds.add(allIds[i]);
      }
    }
    notifyListeners();
  }

  /// 拖拽框选开始。
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
    _selectionAnchorIndex = null;
    notifyListeners();
  }
}
