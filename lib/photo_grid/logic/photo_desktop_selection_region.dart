import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'photo_selection_controller.dart';
import 'photo_drag_region.dart';

/// 构建桌面端拖拽选框 (Marquee Selection) 的 Painter 构建器。
typedef SelectionBoxPainterBuilder = CustomPainter Function(Rect rect, Color primaryColor);

/// 桌面端专属的多选与导航容器。
/// 
/// 提供类似 macOS Finder 的交互体验：
/// 1. 鼠标框选 (Rubber Band Selection)
/// 2. 修饰键支持 (Shift 范围连选, Ctrl/Cmd 反选)
/// 3. 键盘导航 (方向键移动焦点, Shift+方向键连选)
/// 4. 自动滚动 (框选至边缘时自动触发)
class PhotoDesktopSelectionRegion extends StatefulWidget {
  final Widget child;
  final PhotoSelectionController selectionController;
  final List<String> allItemIds;
  final int crossAxisCount;
  final ScrollController? scrollController;
  final Map<String, Rect>? itemLayoutMap;
  final SelectionBoxPainterBuilder? selectionBoxPainterBuilder;

  const PhotoDesktopSelectionRegion({
    super.key,
    required this.child,
    required this.selectionController,
    required this.allItemIds,
    this.crossAxisCount = 4,
    this.scrollController,
    this.itemLayoutMap,
    this.selectionBoxPainterBuilder,
  });

  @override
  State<PhotoDesktopSelectionRegion> createState() => _PhotoDesktopSelectionRegionState();
}

class _PhotoDesktopSelectionRegionState extends State<PhotoDesktopSelectionRegion> with SingleTickerProviderStateMixin {
  Offset? _selectionStartLocal; // 相对容器起始坐标 (随滚动移动)
  Offset? _selectionEndLocal;   // 相对当前视口坐标 (鼠标位置)
  
  // 核心逻辑坐标：相对于滚动内容顶部的偏移
  Offset? _logicStart; 
  bool _isSelecting = false;
  final FocusNode _focusNode = FocusNode();

  // 自动滚动相关
  late final Ticker _scrollTicker;
  double _scrollVelocity = 0;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    _scrollTicker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollTicker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_scrollVelocity == 0) {
      _lastElapsed = null;
      return;
    }
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }
    final delta = elapsed - _lastElapsed!;
    _lastElapsed = elapsed;
    final pixelDelta = _scrollVelocity * (delta.inMicroseconds / 1000000.0);

    final scrollController = widget.scrollController ?? Scrollable.maybeOf(context)?.position;
    if (scrollController != null) {
      final currentPixels = scrollController is ScrollController ? scrollController.offset : (scrollController as ScrollPosition).pixels;
      final maxExtent = scrollController is ScrollController ? scrollController.position.maxScrollExtent : (scrollController as ScrollPosition).maxScrollExtent;
      
      final targetPixels = (currentPixels + pixelDelta).clamp(0.0, maxExtent);
      if (scrollController is ScrollController) {
        scrollController.jumpTo(targetPixels);
      } else {
        (scrollController as ScrollPosition).jumpTo(targetPixels);
      }

      if (_isSelecting && _selectionEndLocal != null) {
         _updateSelection(_selectionEndLocal!);
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse) return;
    
    _focusNode.requestFocus();
    
    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
    final isControlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                             HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                             HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
    
    final bool isRightClick = event.buttons == kSecondaryButton;

    final hitIndex = _getIndexAtPosition(event.position);
    final isHeader = _isHeaderAtPosition(event.position);

    if (hitIndex != null) {
      final index = hitIndex.offset;

      if (isRightClick) {
        // 右键点击项：如果项未选中，则选中它（并清空其他，符合 macOS Finder 逻辑）
        // 如果项已选中，则保持现状（用于显示针对多项的 Context Menu）
        if (!widget.selectionController.selectedIds.contains(widget.allItemIds[index])) {
          widget.selectionController.selectOnly(widget.allItemIds[index], index: index);
        }
        return; // 右键不触发框选
      }

      if (isShiftPressed) {
        // Shift 连选：锚点来自上一步的点选。如果没有锚点，以当前位置为锚点。
        final anchor = widget.selectionController.selectionAnchorIndex ?? index;
        widget.selectionController.selectRange(anchor, index, widget.allItemIds, additive: isControlPressed);
      } else if (isControlPressed) {
        widget.selectionController.toggleItem(widget.allItemIds[index], index: index);
        // Ctrl/Cmd 点选：即使是反选，也将该点设为新锚点，以便后续 Shift 连选
        widget.selectionController.setAnchorIndex(index);
      } else {
        // 普通左键单击（不带修饰键）：直接执行选中
        widget.selectionController.selectOnly(widget.allItemIds[index], index: index);
      }
    } else {
      if (isRightClick) return; // 右键点击空白处不执行任何操作

      // 点击空白处开始框选
      final scrollOffset = widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0;
      
      _selectionStartLocal = event.localPosition;
      _logicStart = Offset(event.localPosition.dx, event.localPosition.dy + scrollOffset);
      _isSelecting = true;

      // 如果点击的是 Header 或者是按下了修饰键，不要清除已有选中
      if (!isControlPressed && !isShiftPressed && !isHeader) {
        widget.selectionController.clearSelection();
      }
      // 记录当前已选，用于框选时的增量计算 (macOS 风格：框选通常是替换或反选，但我们做简单的增量/替换)
      widget.selectionController.startDragSelection(null); 
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isSelecting || _selectionStartLocal == null) return;

    setState(() {
      _selectionEndLocal = event.localPosition;
    });

    _updateSelection(event.localPosition);
    _checkAutoScroll(event.localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    setState(() {
      _isSelecting = false;
      _selectionStartLocal = null;
      _selectionEndLocal = null;
      _logicStart = null;
      _scrollVelocity = 0;
      if (_scrollTicker.isActive) _scrollTicker.stop();
      widget.selectionController.endDragSelection();
    });
  }

  void _updateSelection(Offset localPointerPos) {
    if (_logicStart == null) return;

    final scrollOffset = widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0;
    
    // 当前鼠标在内容空间的逻辑坐标
    final logicEnd = Offset(localPointerPos.dx, localPointerPos.dy + scrollOffset);

    // 逻辑空间内的矩形
    final logicRect = Rect.fromPoints(
      Offset(min(_logicStart!.dx, logicEnd.dx), min(_logicStart!.dy, logicEnd.dy)),
      Offset(max(_logicStart!.dx, logicEnd.dx), max(_logicStart!.dy, logicEnd.dy)),
    );

    // 遍历 Render tree 或使用 LayoutMap 查找覆盖项
    if (widget.itemLayoutMap != null && widget.itemLayoutMap!.isNotEmpty) {
      // 调整策略：直接收集 IDs
      final ids = <String>{};
      widget.itemLayoutMap!.forEach((id, rect) {
         if (logicRect.overlaps(rect)) {
            ids.add(id);
         }
      });
      widget.selectionController.setSelectionActive(true);
      widget.selectionController.updateDragSelection(ids);
    } else {
      final selectedIndices = _getIndicesInRect(logicRect, contentSpace: true);
      final ids = selectedIndices.map((i) => widget.allItemIds[i]).toSet();
      widget.selectionController.setSelectionActive(true);
      widget.selectionController.updateDragSelection(ids);
    }
  }

  void _checkAutoScroll(Offset localPosition) {
    final height = context.size?.height ?? 0;
    const threshold = 60.0;
    const maxSpeed = 2000.0;

    if (localPosition.dy < threshold) {
      _scrollVelocity = -maxSpeed * (1 - (localPosition.dy.clamp(0, threshold)) / threshold);
    } else if (localPosition.dy > height - threshold) {
      _scrollVelocity = maxSpeed * (1 - (height - localPosition.dy).clamp(0, threshold) / threshold);
    } else {
      _scrollVelocity = 0;
    }

    if (_scrollVelocity != 0) {
      if (!_scrollTicker.isActive) {
        _lastElapsed = null;
        _scrollTicker.start();
      }
    } else {
       if (_scrollTicker.isActive) _scrollTicker.stop();
    }
  }

  /// 在指定矩形内搜索项。
  /// [contentSpace] 为 true 时，rect 是内容的逻辑坐标 (包括 scrollOffset)。
  List<int> _getIndicesInRect(Rect rect, {bool contentSpace = false}) {
    final List<int> indices = [];
    final RenderObject? root = context.findRenderObject();
    if (root == null || root is! RenderBox) return indices;

    // 找到具体的 Sliver 内容节点
    // 通常 RenderViewport -> RenderSliverList
    void visitor(RenderObject child) {
      if (child is PhotoGridItemIndexProxy) {
        final childBox = child;
        // 获取相对于 root (即本 Widget 容器) 的坐标
        final childTransform = childBox.getTransformTo(root);
        final paintBounds = childBox.paintBounds;
        final childRectInViewport = MatrixUtils.transformRect(childTransform, paintBounds);
        
        Rect targetChildRect = childRectInViewport;
        Rect targetTestRect = rect;

        if (contentSpace) {
           final offset = widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0;
           // 将测试矩形转换回 Viewport 空间，或者将 childRect 转换为内容空间。
           // 这里我们将 childRect 转换为内容空间进行比较更稳健
           targetChildRect = childRectInViewport.shift(Offset(0, offset));
        }
        
        if (targetTestRect.overlaps(targetChildRect)) {
          indices.add(child.index.offset);
        }
      } else {
        child.visitChildren(visitor);
      }
    }
    root.visitChildren(visitor);
    return indices;
  }

  PhotoGridItemIndex? _getIndexAtPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final local = box.globalToLocal(globalPosition);
    
    // 优先使用 LayoutMap 进行精确匹配（特别是桌面端）
    if (widget.itemLayoutMap != null && widget.itemLayoutMap!.isNotEmpty) {
      final scrollOffset = widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0;
      final logicPos = Offset(local.dx, local.dy + scrollOffset);
      
      for (final entry in widget.itemLayoutMap!.entries) {
        if (entry.value.contains(logicPos)) {
          final id = entry.key;
          final idx = widget.allItemIds.indexOf(id);
          if (idx != -1) return PhotoGridItemIndex(idx);
        }
      }
    }

    // 备选方案：Render Tree Hit Test (用于处理动态项或 LayoutMap 未就绪时)
    final hitTestResult = BoxHitTestResult();
    if (!box.hitTest(hitTestResult, position: local)) return null;

    for (final hit in hitTestResult.path) {
      if (hit.target is PhotoGridItemIndexProxy) {
        return (hit.target as PhotoGridItemIndexProxy).index;
      }
    }
    return null;
  }

  bool _isHeaderAtPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return false;

    final hitTestResult = BoxHitTestResult();
    final local = box.globalToLocal(globalPosition);
    if (!box.hitTest(hitTestResult, position: local)) return false;

    for (final hit in hitTestResult.path) {
      if (hit.target is PhotoGridHeaderProxy) {
        return true;
      }
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final currentFocus = widget.selectionController.selectionAnchorIndex ?? -1;
    final totalCount = widget.allItemIds.length;
    if (totalCount == 0) return KeyEventResult.ignored;

    int nextFocus = currentFocus;
    final logicalKey = event.logicalKey;
    
    // 检查是否是我们处理的键
    final bool isArrow = logicalKey == LogicalKeyboardKey.arrowLeft ||
                         logicalKey == LogicalKeyboardKey.arrowRight ||
                         logicalKey == LogicalKeyboardKey.arrowUp ||
                         logicalKey == LogicalKeyboardKey.arrowDown;
    final bool isAction = logicalKey == LogicalKeyboardKey.keyA || 
                          logicalKey == LogicalKeyboardKey.escape;

    if (!isArrow && !isAction) return KeyEventResult.ignored;

    final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
    final isControlPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                             HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                             HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);

    if (logicalKey == LogicalKeyboardKey.arrowLeft) {
      nextFocus = max(0, currentFocus - 1);
    } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
      nextFocus = min(totalCount - 1, currentFocus + 1);
    } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
      nextFocus = max(0, currentFocus - widget.crossAxisCount);
    } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
      nextFocus = min(totalCount - 1, currentFocus + widget.crossAxisCount);
    } else if (logicalKey == LogicalKeyboardKey.keyA && isControlPressed) {
      widget.selectionController.selectAll(widget.allItemIds);
      return KeyEventResult.handled;
    } else if (logicalKey == LogicalKeyboardKey.escape) {
      widget.selectionController.clearSelection();
      return KeyEventResult.handled;
    }

    if (nextFocus != currentFocus && nextFocus >= 0) {
      if (isShiftPressed) {
        final anchor = widget.selectionController.selectionAnchorIndex ?? currentFocus;
        widget.selectionController.selectRange(anchor, nextFocus, widget.allItemIds, additive: isControlPressed);
      } else {
        if (!isControlPressed) {
           widget.selectionController.clearSelection();
           widget.selectionController.selectItem(widget.allItemIds[nextFocus], index: nextFocus);
        }
      }
      
      // 自动滚动显示焦点
      _ensureVisible(nextFocus);
    }
    return KeyEventResult.handled;
  }

  void _ensureVisible(int index) {
    if (index < 0 || index >= widget.allItemIds.length) return;
    final itemLayoutMap = widget.itemLayoutMap;
    if (itemLayoutMap == null || itemLayoutMap.isEmpty) return;

    final id = widget.allItemIds[index];
    final rect = itemLayoutMap[id];
    if (rect == null) return;

    final scrollController = widget.scrollController ?? Scrollable.maybeOf(context);
    if (scrollController == null) return;

    final double currentOffset = scrollController is ScrollController 
        ? (scrollController.hasClients ? scrollController.offset : 0.0)
        : (scrollController as ScrollableState).position.pixels;
    
    final double viewportHeight = context.size?.height ?? 0.0;
    if (viewportHeight <= 0) return;

    double targetOffset = currentOffset;
    
    // 如果项在上方不可见
    if (rect.top < currentOffset) {
      targetOffset = rect.top - 10; // 留一点边距
    } 
    // 如果项在下方不可见
    else if (rect.bottom > currentOffset + viewportHeight) {
      targetOffset = rect.bottom - viewportHeight + 10; // 留一点边距
    }

    if (targetOffset != currentOffset) {
       if (scrollController is ScrollController) {
          scrollController.jumpTo(targetOffset.clamp(0, scrollController.position.maxScrollExtent));
       } else {
          final scrollable = scrollController as ScrollableState;
          scrollable.position.jumpTo(targetOffset.clamp(0.0, scrollable.position.maxScrollExtent));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算当前显示在 UI 上的选框位置
    Rect? visualRect;
    if (_selectionStartLocal != null && _selectionEndLocal != null) {
      visualRect = Rect.fromPoints(_selectionStartLocal!, _selectionEndLocal!);
    }

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: GestureDetector(
        onLongPressStart: _handleLongPress,
        child: Stack(
          children: [
            Listener(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              behavior: HitTestBehavior.translucent, // 确保点击空白处也能触发
              child: widget.child,
            ),
            if (_isSelecting && visualRect != null)
              IgnorePointer(
                child: CustomPaint(
                  painter: widget.selectionBoxPainterBuilder?.call(visualRect, Theme.of(context).primaryColor) ??
                      _SelectionPainter(visualRect, Theme.of(context).primaryColor),
                  size: Size.infinite,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleLongPress(LongPressStartDetails details) {
    if (_isSelecting) return;

    final hitIndex = _getIndexAtPosition(details.globalPosition);
    if (hitIndex != null) {
      final index = hitIndex.offset;
      final itemId = widget.allItemIds[index];

      // 进入多选模式并选中该项
      if (!widget.selectionController.isSelectionActive) {
        widget.selectionController.setSelectionActive(true);
      }
      widget.selectionController.selectItem(itemId, index: index);
    }
  }
}

class _SelectionPainter extends CustomPainter {
  final Rect rect;
  final Color color;

  _SelectionPainter(this.rect, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color.withAlpha(40)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) => oldDelegate.rect != rect;
}
