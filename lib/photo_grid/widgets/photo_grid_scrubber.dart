import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/photo_grid_segment.dart';

const Duration kTimelineScrubberFadeInDuration = Duration(milliseconds: 150);
const Duration kTimelineScrubberFadeOutDuration = Duration(milliseconds: 2000);
const double kScrubberThumbHeight = 48.0;
const int kMinMonthsToEnableScrubberSnap = 12;

/// 一个高度定制的悬浮时间轴快速滚动轴 (Scrubber)。
///
/// 该组件实现了类似于 iOS/Google 相册右侧吸附滑动条。
/// 当展示超过数个月的数据量时，可以通过按住屏幕右侧并上下滑动，
/// 在不同月份的时间刻度之间进行磁吸跃迁 (Magnetic Snapping)。
/// 底层不依赖 ListView 的跳转索引，而通过预计算数学刻度进行绝对像素级的 [ScrollController] 跳转。
class PhotoGridScrubber extends StatefulWidget {

  /// 网格需要响应拖拽跳转的滚动控制器。
  final ScrollController controller;

  /// 用于提供给 Scrubber 在拖拽时显示的气泡中具体的“年、月”数据。
  final List<Segment> segments;

  /// 包裹在此滚动轴内的目标主体（通常为 [CustomScrollView] 或包裹层）。
  final Widget child;

  /// Scrubber 可视化的垂直总高度，通常等于 MediaQuery 的屏幕高度。
  final double timelineHeight;

  /// 顶部的 SafeArea 边距约束。
  final double topPadding;

  /// 底部的 SafeArea 边距约束。
  final double bottomPadding;

  const PhotoGridScrubber({
    super.key,
    required this.controller,
    required this.segments,
    required this.child,
    required this.timelineHeight,
    this.topPadding = 0.0,
    this.bottomPadding = 0.0,
  });

  @override
  State<PhotoGridScrubber> createState() => _PhotoGridScrubberState();
}

class _ScrubberSegment {
  final DateTime date;
  final double startOffset;
  final String scrollLabel;
  final bool showSegment;

  const _ScrubberSegment({
    required this.date,
    required this.startOffset,
    required this.scrollLabel,
    this.showSegment = false,
  });
}

List<_ScrubberSegment> _buildSegments({required List<Segment> layoutSegments, required double timelineHeight}) {
  final segments = <_ScrubberSegment>[];
  if (layoutSegments.isEmpty || layoutSegments.first.bucket is! TimeBucket) {
    return [];
  }

  double lastOffset = -28.0;
  
  for (final layoutSegment in layoutSegments) {
    final scrollPercentage = layoutSegment.startOffset / layoutSegments.last.endOffset;
    final startOffset = scrollPercentage * timelineHeight;

    final date = (layoutSegment.bucket as TimeBucket).date;
    final label = '${date.year}年${date.month}月';

    const double offsetThreshold = 28.0; 
    final showSegment = lastOffset + offsetThreshold <= startOffset;

    segments.add(_ScrubberSegment(date: date, startOffset: startOffset, scrollLabel: label, showSegment: showSegment));
    if (showSegment) {
      lastOffset = startOffset;
    }
  }

  return segments;
}

class _PhotoGridScrubberState extends State<PhotoGridScrubber> with TickerProviderStateMixin {
  String? _lastLabel;
  bool _isDragging = false;
  List<_ScrubberSegment> _segments = [];
  int _monthCount = 0;
  final ValueNotifier<double> _thumbTopOffset = ValueNotifier<double>(0.0);
  int _lastUpdateMs = 0; // 用于节流至 60 帧

  late AnimationController _thumbAnimationController;
  Timer? _fadeOutTimer;
  late Animation<double> _thumbAnimation;

  late AnimationController _labelAnimationController;
  late Animation<double> _labelAnimation;

  double get _scrubberHeight => widget.timelineHeight - widget.topPadding - widget.bottomPadding;

  double get _currentOffset {
    if (!widget.controller.hasClients) return 0.0;
    if (widget.controller.position.maxScrollExtent <= 0) return 0.0;
    final percentage = (widget.controller.offset / widget.controller.position.maxScrollExtent).clamp(0.0, 1.0);
    return percentage * _scrubberHeight;
  }

  @override
  void initState() {
    super.initState();
    _isDragging = false;
    _segments = _buildSegments(layoutSegments: widget.segments, timelineHeight: _scrubberHeight);
    _thumbAnimationController = AnimationController(vsync: this, duration: kTimelineScrubberFadeInDuration);
    _thumbAnimation = CurvedAnimation(parent: _thumbAnimationController, curve: Curves.fastEaseInToSlowEaseOut);
    _labelAnimationController = AnimationController(vsync: this, duration: kTimelineScrubberFadeInDuration);
    _monthCount = getMonthCount();

    _labelAnimation = CurvedAnimation(parent: _labelAnimationController, curve: Curves.fastOutSlowIn);
    widget.controller.addListener(_onListPositionChanged);
  }

  @override
  void didUpdateWidget(covariant PhotoGridScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onListPositionChanged);
      widget.controller.addListener(_onListPositionChanged);
    }

    if (oldWidget.segments.lastOrNull?.endOffset != widget.segments.lastOrNull?.endOffset) {
      _segments = _buildSegments(layoutSegments: widget.segments, timelineHeight: _scrubberHeight);
      _monthCount = getMonthCount();
      _thumbTopOffset.value = _currentOffset;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onListPositionChanged);
    _thumbAnimationController.dispose();
    _labelAnimationController.dispose();
    _fadeOutTimer?.cancel();
    _thumbTopOffset.dispose();
    super.dispose();
  }

  void _resetThumbTimer() {
    _fadeOutTimer?.cancel();
    _fadeOutTimer = Timer(kTimelineScrubberFadeOutDuration, () {
      _thumbAnimationController.reverse();
      _fadeOutTimer = null;
    });
  }

  int getMonthCount() {
    return _segments.map((e) => "${e.date.month}_${e.date.year}").toSet().length;
  }

  void _onListPositionChanged() {
    if (_isDragging) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateMs < 16) return; // 节流至 60 帧
    _lastUpdateMs = now;

    _thumbTopOffset.value = _currentOffset;
    if (_labelAnimation.status != AnimationStatus.reverse) {
      _labelAnimationController.reverse();
    }
    if (_thumbAnimationController.status != AnimationStatus.forward) {
      _thumbAnimationController.forward();
    }
    _resetThumbTimer();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_isDragging) return false;

    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastUpdateMs < 16) return false;
      _lastUpdateMs = now;

      _thumbTopOffset.value = _currentOffset;
      if (_labelAnimation.status != AnimationStatus.reverse) {
        _labelAnimationController.reverse();
      }
      if (_thumbAnimationController.status != AnimationStatus.forward) {
        _thumbAnimationController.forward();
      }
    }
    _resetThumbTimer();

    return false;
  }

  double _dragStartOffsetDiff = 0.0;

  void _onDragStart(DragStartDetails details) {
    final dragAreaTop = widget.topPadding;
    final relativePosition = details.globalPosition.dy - dragAreaTop;
    _dragStartOffsetDiff = relativePosition - _thumbTopOffset.value;

    setState(() {
      _isDragging = true;
      _labelAnimationController.forward();
      _fadeOutTimer?.cancel();
      _lastLabel = null;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    if (_thumbAnimationController.status != AnimationStatus.forward) {
      _thumbAnimationController.forward();
    }

    final rawDragPosition = _calculateDragPosition(details.globalPosition);
    final dragPosition = (rawDragPosition - _dragStartOffsetDiff).clamp(0.0, _scrubberHeight);
    final nearestMonthSegment = _findNearestMonthSegment(dragPosition);

    if (nearestMonthSegment != null) {
      final label = nearestMonthSegment.scrollLabel;
      if (_lastLabel != label) {
        HapticFeedback.selectionClick();
        _lastLabel = label;
      }
    }

    if (_monthCount < kMinMonthsToEnableScrubberSnap) {
      // If there are less than 2 months, we don't need to snap to segments
      _thumbTopOffset.value = dragPosition;
      if (widget.controller.hasClients) {
        widget.controller.jumpTo((dragPosition / _scrubberHeight) * widget.controller.position.maxScrollExtent);
      }
    } else if (nearestMonthSegment != null) {
      _snapToSegment(nearestMonthSegment);
    }
  }

  double _calculateDragPosition(Offset globalPosition) {
    final dragAreaTop = widget.topPadding;
    final dragAreaBottom = widget.timelineHeight - widget.bottomPadding;
    final dragAreaHeight = dragAreaBottom - dragAreaTop;

    final relativePosition = globalPosition.dy - dragAreaTop;
    return relativePosition.clamp(0.0, dragAreaHeight);
  }

  _ScrubberSegment? _findNearestMonthSegment(double position) {
    _ScrubberSegment? nearestSegment;
    double minDistance = double.infinity;

    for (final segment in _segments) {
      final distance = (segment.startOffset - position).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearestSegment = segment;
      }
    }

    return nearestSegment;
  }

  void _snapToSegment(_ScrubberSegment segment) {
    _thumbTopOffset.value = segment.startOffset; // Assuming segment.startOffset is the scrubberPosition
    if (widget.controller.hasClients) {
      final layoutSegmentIndex = _findLayoutSegmentIndex(segment);
      if (layoutSegmentIndex >= 0) {
        final layoutSegment = widget.segments[layoutSegmentIndex];
        final maxScrollExtent = widget.controller.position.maxScrollExtent;
        final viewportHeight = widget.controller.position.viewportDimension;

        final targetScrollOffset = layoutSegment.startOffset;
        final centeredOffset = targetScrollOffset - (viewportHeight / 4) + 100;

        widget.controller.jumpTo(centeredOffset.clamp(0.0, maxScrollExtent));
      }
    }
  }

  int _findLayoutSegmentIndex(_ScrubberSegment segment) {
    return widget.segments.indexWhere((layoutSegment) {
      if (layoutSegment.bucket is! TimeBucket) return false;
      final bucket = layoutSegment.bucket as TimeBucket;
      return bucket.date.year == segment.date.year && bucket.date.month == segment.date.month;
    });
  }
  void _onDragEnd(DragEndDetails _) {
    _labelAnimationController.reverse();
    setState(() {
      _isDragging = false;
    });
    _resetThumbTimer();
  }

  @override
  Widget build(BuildContext ctx) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          // Scroll Segments
          RepaintBoundary(
            child: Visibility(
              visible: _isDragging,
              child: Stack(
                children: _segments
                    .where((segment) => segment.showSegment)
                    .map(
                      (segment) => PositionedDirectional(
                        key: ValueKey('segment_${segment.date.millisecondsSinceEpoch}'),
                        top: widget.topPadding + segment.startOffset,
                        end: 100,
                        child: RepaintBoundary(
                          child: Container(
                            margin: const EdgeInsets.only(right: 36.0),
                            child: Material(
                              color: Theme.of(ctx).colorScheme.surface,
                              borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 28),
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                alignment: Alignment.center,
                                child: Text(
                                  segment.scrollLabel,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          ValueListenableBuilder<double>(
            valueListenable: _thumbTopOffset,
            builder: (ctx, offset, _) {
              if (!widget.controller.hasClients) {
                return const SizedBox();
              }
              final position = widget.controller.position;
              if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
                return const SizedBox();
              }
              final nearestSegment = _findNearestMonthSegment(offset);
              final labelText = nearestSegment?.scrollLabel;
              final label = labelText != null
                  ? Text(
                      labelText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    )
                  : null;
              return PositionedDirectional(
                top: offset + widget.topPadding,
                end: 0,
                child: RepaintBoundary(
                    child: GestureDetector(
                      onVerticalDragStart: _onDragStart,
                      onVerticalDragUpdate: _onDragUpdate,
                      onVerticalDragEnd: _onDragEnd,
                      child: AnimatedBuilder(
                        animation: _thumbAnimation,
                        builder: (context, child) => _thumbAnimation.value == 0.0 ? const SizedBox() : child!,
                        child: FadeTransition(
                          opacity: _thumbAnimation,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (label != null)
                                FadeTransition(
                                  opacity: _labelAnimation,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12.0),
                                    child: Material(
                                      elevation: 4.0,
                                      color: Theme.of(ctx).primaryColor,
                                      borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                      child: Container(
                                        constraints: const BoxConstraints(maxHeight: 28),
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                        alignment: Alignment.center,
                                        child: label,
                                      ),
                                    ),
                                  ),
                                ),
                              CustomPaint(
                                foregroundPainter: const _ArrowPainter(Colors.white),
                                child: Material(
                                  elevation: 4.0,
                                  color: Theme.of(ctx).primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(kScrubberThumbHeight),
                                    bottomLeft: Radius.circular(kScrubberThumbHeight),
                                    topRight: Radius.circular(4.0),
                                    bottomRight: Radius.circular(4.0),
                                  ),
                                  child: Container(
                                    constraints: BoxConstraints.tight(const Size(kScrubberThumbHeight * 0.6, kScrubberThumbHeight)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  const _ArrowPainter(this.color);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const width = 12.0;
    const height = 8.0;
    final baseX = size.width / 2;
    final baseY = size.height / 2;

    canvas.drawPath(_trianglePath(Offset(baseX, baseY - 2.0), width, height, true), paint);
    canvas.drawPath(_trianglePath(Offset(baseX, baseY + 2.0), width, height, false), paint);
  }

  static Path _trianglePath(Offset o, double width, double height, bool isUp) {
    return Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + width, o.dy)
      ..lineTo(o.dx + (width / 2), isUp ? o.dy - height : o.dy + height)
      ..close();
  }
}
