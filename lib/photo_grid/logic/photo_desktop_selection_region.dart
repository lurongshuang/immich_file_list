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
  // 框选相关状态使用 ValueNotifier 以便在 PointerMove 时实现局部重绘，避免触发整个 PhotoGridView 的 LayoutBuilder
  final ValueNotifier<Rect?> _selectionRectNotifier = ValueNotifier<Rect?>(null);
  
  // 核心逻辑坐标：相对于滚动内容顶部的偏移
  Offset? _logicStart; 
  bool _isSelecting = false;
  bool _dragHappened = false;           // 是否发生了实质性的位移（用于区分点击和框选）
  String? _pendingReduceSelectionId;    // 准备在 PointerUp 时执行唯一选中的 ID
  int? _pendingReduceSelectionIndex;    // 准备在 PointerUp 时执行唯一选中的索引
  final FocusNode _focusNode = FocusNode();

  // 辅助变量：记录当前的 selectionEndLocal 用于 AutoScroll 逻辑，不触发 UI 重播
  Offset? _selectionEndLocal;

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
    _selectionRectNotifier.dispose();
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

    _dragHappened = false;
    _pendingReduceSelectionId = null;
    _pendingReduceSelectionIndex = null;

    if (hitIndex != null) {
      final index = hitIndex.offset;
      final id = widget.allItemIds[index];

      if (isRightClick) {
        if (!widget.selectionController.selectedIds.contains(id)) {
          widget.selectionController.selectOnly(id, index: index);
        }
        return; 
      }

      if (isShiftPressed) {
        final anchor = widget.selectionController.selectionAnchorIndex ?? index;
        widget.selectionController.selectRange(anchor, index, widget.allItemIds, additive: isControlPressed);
      } else if (isControlPressed) {
        widget.selectionController.toggleItem(id, index: index);
        widget.selectionController.setAnchorIndex(index);
      } else {
        if (!widget.selectionController.selectedIds.contains(id)) {
          widget.selectionController.selectOnly(id, index: index);
        } else {
          _pendingReduceSelectionId = id;
          _pendingReduceSelectionIndex = index;
          widget.selectionController.setAnchorIndex(index);
        }
      }
    } else {
      if (isRightClick) return; 

      final scrollOffset = widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0;
      
      _logicStart = Offset(event.localPosition.dx, event.localPosition.dy + scrollOffset);
      
      // 不再使用 setState，直接更新 ValueNotifier。由于 build 中始终保留 ValueListenableBuilder，选框会根据 rect 是否为 null 自动显示/隐藏。
      _isSelecting = true;
      _selectionRectNotifier.value = Rect.fromPoints(event.localPosition, event.localPosition);
      _selectionEndLocal = event.localPosition;

      if (!isControlPressed && !isShiftPressed && !isHeader) {
        widget.selectionController.clearSelection();
      }
      widget.selectionController.startDragSelection(null); 
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_dragHappened && (event.localDelta.dx.abs() > 2 || event.localDelta.dy.abs() > 2)) {
       _dragHappened = true;
    }

    if (!_isSelecting || _logicStart == null) return;

    final startLocal = Offset(_logicStart!.dx, _logicStart!.dy - (widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0));
    _selectionRectNotifier.value = Rect.fromPoints(startLocal, event.localPosition);
    _selectionEndLocal = event.localPosition;

    _updateSelection(event.localPosition);
    _checkAutoScroll(event.localPosition);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_pendingReduceSelectionId != null) {
      if (!_dragHappened) {
         widget.selectionController.selectOnly(_pendingReduceSelectionId!, index: _pendingReduceSelectionIndex);
      }
      _pendingReduceSelectionId = null;
      _pendingReduceSelectionIndex = null;
    }
    _dragHappened = false;

    if (_isSelecting) {
      // 这里的清理全部改为通过 ValueNotifier 触发局部刷新，不再调用 setState 导致整个 grid 重建
      _isSelecting = false;
      _selectionRectNotifier.value = null;
      _logicStart = null;
      _selectionEndLocal = null;
      _scrollVelocity = 0;
      
      if (_scrollTicker.isActive) _scrollTicker.stop();
      widget.selectionController.endDragSelection();
    }
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
      final ids = <String>{};
      
      // 优化：仅遍历与当前框选矩形在 Y 轴上有重叠的项
      // 由于 layoutMap 通常是按时间顺序生成的，其 Rect.top 往往具有一定的单调性
      // 这里进行简单的边界过滤以减少不必要的 overlaps 计算
      final viewTop = logicRect.top;
      final viewBottom = logicRect.bottom;
      
      widget.itemLayoutMap!.forEach((id, rect) {
         if (rect.bottom < viewTop || rect.top > viewBottom) return;
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
        // Rect targetTestRect = rect; // This line is not needed, rect is already the target test rect

        if (contentSpace) {
           final offset = widget.scrollController?.hasClients == true ? widget.scrollController!.offset : 0.0;
           // 将测试矩形转换回 Viewport 空间，或者将 childRect 转换为内容空间。
           // 这里我们将 childRect 转换为内容空间进行比较更稳健
           targetChildRect = childRectInViewport.shift(Offset(0, offset));
        }
        
        if (rect.overlaps(targetChildRect)) {
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
    
    // 优化：优先使用 Flutter 原生的 Render Tree Hit Test (O(log N))
    // 对于已经显示在屏幕上的项，这是最快、最准确的方式
    final hitTestResult = BoxHitTestResult();
    if (box.hitTest(hitTestResult, position: local)) {
      for (final hit in hitTestResult.path) {
        if (hit.target is PhotoGridItemIndexProxy) {
          return (hit.target as PhotoGridItemIndexProxy).index;
        }
      }
    }

    // 备选方案：只有 Hit Test 没中时（可能点击了 item 间隙但 layoutMap 认为在范围内，或者坐标偏移），才检查 LayoutMap
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
    final themeColor = Theme.of(context).primaryColor;

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
              behavior: HitTestBehavior.translucent, 
              child: widget.child,
            ),
            // 使用 ValueListenableBuilder 局部刷新选框，避免重建整个 grid 子树
            ValueListenableBuilder<Rect?>(
              valueListenable: _selectionRectNotifier,
              builder: (context, rect, _) {
                if (!_isSelecting || rect == null) return const SizedBox.shrink();
                return IgnorePointer(
                  child: CustomPaint(
                    painter: widget.selectionBoxPainterBuilder?.call(rect, themeColor) ??
                        _SelectionPainter(rect, themeColor),
                    size: Size.infinite,
                  ),
                );
              },
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
