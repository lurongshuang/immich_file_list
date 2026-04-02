import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// 网格照片项的数学坐标轴结构
class PhotoGridItemIndex {
  /// 项在一维打平数组中的真实角标偏移 (相当于 IndexPath 的 row)
  final int offset;

  const PhotoGridItemIndex(this.offset);

  @override
  bool operator ==(covariant PhotoGridItemIndex other) {
    if (identical(this, other)) return true;
    return other.offset == offset;
  }

  @override
  int get hashCode => offset.hashCode;
}

/// [PhotoDragRegion] 是滑动框选的专门感应与计算容器。
///
/// 它包裹整个照片网格，监听长按 (`onLongPress`) 与随后的拖拽手势 (Drag)，从而执行类似
/// 手机系统相册的多选滑动交互，支持跨屏幕连续选中/反选。
/// 通过与内层的 [PhotoGridItemIndexWrapper] 配合，它可以精准获知用户长按时选中的起始项，
/// 以及拖拽过程中手指划过的所有项的 `offset`，并抛出给顶层容器。
class PhotoDragRegion extends StatefulWidget {
  final Widget child;

  /// 长按并开始拖动时的回调。
  /// 将抛出被按下元素的确切坐标 [PhotoGridItemIndex]。
  final void Function(PhotoGridItemIndex index) onStart;

  /// 当拖动的手指进入该项所在的识别框时触发一次。
  /// 这里是提供高频多选连滑事件的引擎核心位置。
  final void Function(PhotoGridItemIndex index) onAssetEnter;

  /// 拖动或长按结束/被取消时回调。
  final void Function() onEnd;

  /// 滚轮事件触发准备开始时的钩子。
  final void Function()? onScrollStart;

  /// 当手势触及屏幕边缘时触发滚动回调。参数 delta 为应当跳转的相对像素距离（已结合硬件帧率平滑处理）。
  final void Function(double delta) onScroll;

  const PhotoDragRegion({
    super.key,
    required this.child,
    required this.onStart,
    required this.onAssetEnter,
    required this.onEnd,
    this.onScrollStart, // Kept as optional, as it's used internally but not documented in the new instruction
    required this.onScroll,
  });

  @override
  State<PhotoDragRegion> createState() => _PhotoDragRegionState();
}

class _PhotoDragRegionState extends State<PhotoDragRegion> with SingleTickerProviderStateMixin {
  PhotoGridItemIndex? anchorAsset;
  PhotoGridItemIndex? assetUnderPointer;

  static const double scrollOffset = 0.10;
  double? topScrollOffset;
  double? bottomScrollOffset;

  Ticker? _ticker;
  double _velocity = 0; // 像素/秒
  Duration? _lastElapsed;
  bool scrollNotified = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (_velocity == 0) {
      _lastElapsed = null;
      return;
    }
    
    if (_lastElapsed == null) {
      _lastElapsed = elapsed;
      return;
    }

    final Duration delta = elapsed - _lastElapsed!;
    const Duration frameTarget = Duration(milliseconds: 16); // 60帧基础心跳

    // 只有当距离上一帧至少过了 16ms 才更新逻辑，确保即便在 120Hz 高刷屏上也能稳定在 60 帧更新，减少 CPU 压力和视觉“闪烁”感
    if (delta < frameTarget) return;

    final double deltaSec = delta.inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;

    if (deltaSec == 0) return;

    final double pixelDelta = _velocity * deltaSec;
    
    widget.onScroll.call(pixelDelta);
    _checkPointerAgainstAssets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    topScrollOffset = null;
    bottomScrollOffset = null;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _CustomLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<_CustomLongPressGestureRecognizer>(
          () => _CustomLongPressGestureRecognizer(),
          _registerCallbacks,
        ),
      },
      child: widget.child,
    );
  }

  void _registerCallbacks(_CustomLongPressGestureRecognizer recognizer) {
    recognizer.onLongPressMoveUpdate = _onLongPressMove;
    recognizer.onLongPressStart = _onLongPressStart;
    recognizer.onLongPressUp = _onLongPressEnd;
  }

  PhotoGridItemIndex? _getIndexAtPosition(Offset position) {
    final box = context.findAncestorRenderObjectOfType<RenderBox>();
    if (box == null) return null;

    final hitTestResult = BoxHitTestResult();
    final local = box.globalToLocal(position);
    if (!box.hitTest(hitTestResult, position: local)) return null;

    for (final hit in hitTestResult.path) {
      if (hit.target is PhotoGridItemIndexProxy) {
        return (hit.target as PhotoGridItemIndexProxy).index;
      }
    }
    return null;
  }

  void _onLongPressStart(LongPressStartDetails event) {
    final height = context.size?.height;
    if (height != null && (topScrollOffset == null || bottomScrollOffset == null)) {
      topScrollOffset = height * scrollOffset;
      bottomScrollOffset = height - topScrollOffset!;
    }

    final initialHit = _getIndexAtPosition(event.globalPosition);
    anchorAsset = initialHit;
    debugPrint('PhotoDragRegion: _onLongPressStart at ${event.globalPosition}, asset index: ${initialHit?.offset}');
    if (initialHit == null) return;

    if (anchorAsset != null) {
      widget.onStart.call(anchorAsset!);
    }
  }

  Offset? _lastGlobalPosition;

  void _onLongPressEnd() {
    debugPrint('PhotoDragRegion: _onLongPressEnd');
    _lastGlobalPosition = null;
    scrollNotified = false;
    _velocity = 0;
    if (_ticker?.isActive == true) _ticker?.stop();
    widget.onEnd.call();
  }

  void _checkPointerAgainstAssets() {
    if (_lastGlobalPosition == null) return;
    final currentlyTouchingAsset = _getIndexAtPosition(_lastGlobalPosition!);
    if (currentlyTouchingAsset == null) return;

    if (assetUnderPointer != currentlyTouchingAsset) {
      if (!scrollNotified) {
        scrollNotified = true;
        widget.onScrollStart?.call();
      }

      widget.onAssetEnter.call(currentlyTouchingAsset);
      assetUnderPointer = currentlyTouchingAsset;
    }
  }

  void _onLongPressMove(LongPressMoveUpdateDetails event) {
    if (anchorAsset == null) return;
    if (topScrollOffset == null || bottomScrollOffset == null) return;

    _lastGlobalPosition = event.globalPosition;
    final currentDy = event.localPosition.dy;

    const double maxSpeed = 2500.0; // 甚至可以更快
    const double minSpeed = 500.0;

    if (currentDy > bottomScrollOffset!) {
      // 距离越深，速度越快
      final double overflow = (currentDy - bottomScrollOffset!);
      final double normalized = (overflow / topScrollOffset!).clamp(0.0, 1.0);
      _velocity = minSpeed + (maxSpeed - minSpeed) * normalized;

      if (_ticker?.isActive == false) {
        _lastElapsed = null;
        _ticker?.start();
      }
    } else if (currentDy < topScrollOffset!) {
      // 往上滚
      final double overflow = (topScrollOffset! - currentDy);
      final double normalized = (overflow / topScrollOffset!).clamp(0.0, 1.0);
      _velocity = -(minSpeed + (maxSpeed - minSpeed) * normalized);

      if (_ticker?.isActive == false) {
        _lastElapsed = null;
        _ticker?.start();
      }
    } else {
      _velocity = 0;
      if (_ticker?.isActive == true) _ticker?.stop();
    }

    _checkPointerAgainstAssets();
  }
}

class _CustomLongPressGestureRecognizer extends LongPressGestureRecognizer {
}

class PhotoGridItemIndexWrapper extends SingleChildRenderObjectWidget {
  final int offset;

  const PhotoGridItemIndexWrapper({
    required Widget super.child,
    required this.offset,
    super.key,
  });

  @override
  PhotoGridItemIndexProxy createRenderObject(BuildContext context) {
    return PhotoGridItemIndexProxy(
      index: PhotoGridItemIndex(offset),
    );
  }

  @override
  void updateRenderObject(BuildContext context, PhotoGridItemIndexProxy renderObject) {
    renderObject.index = PhotoGridItemIndex(offset);
  }
}

class PhotoGridItemIndexProxy extends RenderProxyBox {
  PhotoGridItemIndex index;

  PhotoGridItemIndexProxy({required this.index});
}

/// 用于标识 Header 的 Proxy，帮助 SelectionRegion 区分空白区域和 Header 区域。
class PhotoGridHeaderWrapper extends SingleChildRenderObjectWidget {
  const PhotoGridHeaderWrapper({
    required Widget super.child,
    super.key,
  });

  @override
  PhotoGridHeaderProxy createRenderObject(BuildContext context) {
    return PhotoGridHeaderProxy();
  }
}

class PhotoGridHeaderProxy extends RenderProxyBox {}
