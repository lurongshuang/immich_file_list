import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/photo_grid_segment.dart';
import 'photo_grid_item.dart';

const Duration kDefaultScrubberFadeInDuration = Duration(milliseconds: 150);
const Duration kDefaultScrubberFadeOutDuration = Duration(milliseconds: 2000);
const double kDefaultScrubberThumbHeight = 48.0;
const int kDefaultMinMonthsToEnableScrubberSnap = 12;
const double kDefaultMinSegmentSpacing = 28.0;
const double kDefaultScrubberSnapThreshold = 16.0;

/// 构建气泡标签的函数。当用户拖拽滑块时，会显示该标签。
typedef ScrubberLabelBuilder = Widget Function(BuildContext context, String label, bool isDragging);
/// 构建滑块手柄的函数。
typedef ScrubberThumbBuilder = Widget Function(BuildContext context, double offset, bool isDragging);
/// 构建背景刻度段的函数。
typedef ScrubberSegmentBuilder = Widget Function(BuildContext context, String label, DateTime date);

/// 一个高度定制的悬浮时间轴快速滚动轴 (Scrubber)。
class PhotoGridScrubber extends StatefulWidget {
  /// 滚动的控制器。
  final ScrollController controller;
  /// 网格布局生成的段落信息，用于计算刻度对齐。
  final List<Segment> segments;
  /// 被包裹的内容（通常是 PhotoGridView）。
  final Widget child;
  /// 时间轴的总高度。
  final double timelineHeight;
  /// 顶部边距（如避开 AppBar）。
  final double topPadding;
  /// 底部边距（如避开 BottomBar）。
  final double bottomPadding;
  /// 是否显示背景刻度。
  final bool showSegments;
  /// 自定义气泡 Builder。
  final ScrubberLabelBuilder? labelBuilder;
  /// 自定义滑块 Builder。
  final ScrubberThumbBuilder? thumbBuilder;
  /// 自定义刻度 Builder。
  final ScrubberSegmentBuilder? segmentBuilder;
  /// 滑块淡入时长。
  final Duration fadeInDuration;
  /// 自动隐藏的延迟时长。
  final Duration autoHideDuration;
  /// 滑块手柄的高度。
  final double thumbHeight;
  /// 启用磁吸的最小月份跨度。
  final int snapMinMonths;
  /// 刻度之间的最小像素间距，用于防挤压。
  final double minSegmentSpacing;
  /// 是否始终显示滑块而不隐藏。
  final bool alwaysShow;
  /// 刻度相对于右侧的偏移。
  final double segmentEndOffset;
  /// 气泡相对于右侧的偏移。
  final double labelEndOffset;
  /// 滑块相对于右侧的偏移。
  final double thumbEndOffset;
  /// 磁吸生效的像素阈值。
  final double snapThreshold;
  /// 聚合维度（年/月）。
  final GroupPhotoBy groupBy;

  const PhotoGridScrubber({
    super.key,
    required this.controller,
    required this.segments,
    required this.child,
    required this.timelineHeight,
    this.topPadding = 0.0,
    this.bottomPadding = 0.0,
    this.showSegments = true,
    this.labelBuilder,
    this.thumbBuilder,
    this.segmentBuilder,
    this.fadeInDuration = kDefaultScrubberFadeInDuration,
    this.autoHideDuration = kDefaultScrubberFadeOutDuration,
    this.thumbHeight = kDefaultScrubberThumbHeight,
    this.snapMinMonths = kDefaultMinMonthsToEnableScrubberSnap,
    this.minSegmentSpacing = kDefaultMinSegmentSpacing,
    this.alwaysShow = false,
    this.segmentEndOffset = 100.0,
    this.labelEndOffset = 12.0,
    this.thumbEndOffset = 0.0,
    this.snapThreshold = kDefaultScrubberSnapThreshold,
    this.groupBy = GroupPhotoBy.month,
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

List<_ScrubberSegment> _buildSegments({
  required List<Segment> layoutSegments,
  required double trackHeight,
  required double minSegmentSpacing,
  required GroupPhotoBy groupBy,
}) {
  if (layoutSegments.isEmpty) return [];

  final Map<String, Segment> displaySegments = {};
  for (final segment in layoutSegments) {
    if (segment.bucket is! TimeBucket) continue;
    final date = (segment.bucket as TimeBucket).date;
    final key = groupBy == GroupPhotoBy.year ? "${date.year}" : "${date.year}-${date.month}";
    if (!displaySegments.containsKey(key)) {
      displaySegments[key] = segment;
    }
  }

  if (displaySegments.isEmpty) return [];

  final List<_ScrubberSegment> segments = [];
  final maxOffset = layoutSegments.last.endOffset;
  if (maxOffset <= 0) return [];

  double lastVisibleOffset = -minSegmentSpacing;

  final sortedKeys = displaySegments.keys.toList();
  for (final key in sortedKeys) {
    final layoutSegment = displaySegments[key]!;
    final scrollPercentage = (layoutSegment.startOffset / maxOffset).clamp(0.0, 1.0);
    final startOffset = scrollPercentage * trackHeight;

    final date = (layoutSegment.bucket as TimeBucket).date;
    final label = groupBy == GroupPhotoBy.year ? '${date.year}年度' : '${date.year}年${date.month}月';
    // 检查当前刻度与上一个可见刻度的间距，如果太挤则隐藏（防重复/防挤压）
    final showSegment = (startOffset - lastVisibleOffset).abs() >= minSegmentSpacing;

    segments.add(_ScrubberSegment(
      date: date,
      startOffset: startOffset,
      scrollLabel: label,
      showSegment: showSegment,
    ));

    if (showSegment) {
      lastVisibleOffset = startOffset;
    }
  }

  return segments;
}

class _PhotoGridScrubberState extends State<PhotoGridScrubber> with TickerProviderStateMixin {
  String? _lastLabel;
  bool _isDragging = false;
  List<_ScrubberSegment> _segments = [];
  final ValueNotifier<double> _thumbTopOffset = ValueNotifier<double>(0.0);
  int _lastUpdateMs = 0;

  late AnimationController _thumbAnimationController;
  Timer? _fadeOutTimer;
  late Animation<double> _thumbAnimation;
  late AnimationController _labelAnimationController;
  late Animation<double> _labelAnimation;

  double get _trackHeight => widget.timelineHeight - widget.topPadding - widget.bottomPadding;

  /// 这里的 offset 是滑块顶部相对于 trackHeight 的位置。
  /// 计算公式：滚动百分比 * (总轨迹高度 - 滑块自身高度)。
  /// 减去 thumbHeight 是为了确保当列表滚动到底部时，滑块底部正好贴紧轨道底部。
  double get _currentOffset {
    if (!widget.controller.hasClients) return 0.0;
    final pos = widget.controller.position;
    if (!pos.hasContentDimensions || pos.maxScrollExtent <= 0) return 0.0;
    final percentage = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
    return percentage * (_trackHeight - widget.thumbHeight);
  }

  @override
  void initState() {
    super.initState();
    _rebuildSegments();
    _thumbAnimationController = AnimationController(vsync: this, duration: widget.fadeInDuration);
    if (widget.alwaysShow) _thumbAnimationController.value = 1.0;
    _thumbAnimation = CurvedAnimation(parent: _thumbAnimationController, curve: Curves.fastEaseInToSlowEaseOut);
    _labelAnimationController = AnimationController(vsync: this, duration: widget.fadeInDuration);
    _labelAnimation = CurvedAnimation(parent: _labelAnimationController, curve: Curves.fastOutSlowIn);
    widget.controller.addListener(_onListPositionChanged);
  }

  /// 根据最新的布局段落重新生成背景刻度。
  void _rebuildSegments() {
    _segments = _buildSegments(
      layoutSegments: widget.segments,
      trackHeight: _trackHeight - widget.thumbHeight, // 刻度线也按照滑块行程映射，保证 100% 时对位
      minSegmentSpacing: widget.minSegmentSpacing,
      groupBy: widget.groupBy,
    );
  }

  @override
  void didUpdateWidget(covariant PhotoGridScrubber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onListPositionChanged);
      widget.controller.addListener(_onListPositionChanged);
    }
    if (oldWidget.alwaysShow != widget.alwaysShow) {
      if (widget.alwaysShow) {
        _thumbAnimationController.forward();
        _fadeOutTimer?.cancel();
      } else {
        _resetThumbTimer();
      }
    }
    if (oldWidget.segments.lastOrNull?.endOffset != widget.segments.lastOrNull?.endOffset ||
        oldWidget.timelineHeight != widget.timelineHeight ||
        oldWidget.groupBy != widget.groupBy) {
      _rebuildSegments();
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
    if (widget.alwaysShow) return;
    _fadeOutTimer?.cancel();
    _fadeOutTimer = Timer(widget.autoHideDuration, () {
      _thumbAnimationController.reverse();
      _fadeOutTimer = null;
    });
  }

  void _onListPositionChanged() {
    if (_isDragging) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateMs < 16) return;
    _lastUpdateMs = now;
    _thumbTopOffset.value = _currentOffset;
    if (_labelAnimation.status != AnimationStatus.reverse) _labelAnimationController.reverse();
    if (_thumbAnimationController.status != AnimationStatus.forward) _thumbAnimationController.forward();
    _resetThumbTimer();
  }

  /// 处理滚动通知，实时更新滑块位置（非拖拽状态下）。
  bool _onScrollNotification(ScrollNotification notification) {
    if (_isDragging) return false;
    if (notification is ScrollUpdateNotification) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastUpdateMs < 16) return false; // 节流，保证 60fps 性能
      _lastUpdateMs = now;
      _thumbTopOffset.value = _currentOffset;
      // 滚动时淡入滑块，淡出气泡
      if (_labelAnimation.status != AnimationStatus.reverse) _labelAnimationController.reverse();
      if (_thumbAnimationController.status != AnimationStatus.forward) _thumbAnimationController.forward();
    }
    _resetThumbTimer();
    return false;
  }

  /// 记录手指按下时相对于滑块顶部的偏移量，防止起手跳动（Jitter）。
  double _dragStartOffsetDiff = 0.0;

  /// 手势开始拖拽：锁定坐标差值，触发气泡显示。
  void _onDragStart(DragStartDetails details) {
    _dragStartOffsetDiff = details.localPosition.dy.clamp(0.0, widget.thumbHeight);

    setState(() {
      _isDragging = true;
      _labelAnimationController.forward();
      _fadeOutTimer?.cancel();
      _lastLabel = null;
    });
  }

  /// 手势移动：计算局部映射坐标，执行跳转并处理磁吸。
  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || !widget.controller.hasClients) return;

    if (_thumbAnimationController.status != AnimationStatus.forward) _thumbAnimationController.forward();

    // 利用 RenderBox 获取相对于自身的局部坐标，解决 parent 偏移导致的定位不准问题
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final relativePosition = localPosition.dy - widget.topPadding;
    final effectiveTrackHeight = _trackHeight - widget.thumbHeight;
    
    // 计算滑块顶部应该在的位置（通过 initial offset 修正）
    double dragTop = (relativePosition - _dragStartOffsetDiff).clamp(0.0, effectiveTrackHeight);
    
    // 磁吸判断：寻找最近的刻度段
    final nearest = _findNearestSegment(dragTop);
    bool snapped = false;
    if (nearest != null) {
      final distance = (dragTop - nearest.startOffset).abs();
      // 年度试图下磁吸更强
      final threshold = (widget.groupBy == GroupPhotoBy.year) ? 24.0 : widget.snapThreshold;
      if (distance < threshold) {
        dragTop = nearest.startOffset;
        snapped = true;
      }
    }

    _thumbTopOffset.value = dragTop;
    final percentage = dragTop / effectiveTrackHeight;
    
    if (snapped && nearest != null) {
      // 磁吸状态：精确跳转到对应数据段
      _jumpToSegment(nearest);
    } else {
      // 自由状态：按比例跳转百分比
      widget.controller.jumpTo(percentage * widget.controller.position.maxScrollExtent);
    }

    // 触感反馈：跨越段落时震动
    if (nearest != null && _lastLabel != nearest.scrollLabel) {
      HapticFeedback.selectionClick();
      _lastLabel = nearest.scrollLabel;
    }
  }

  _ScrubberSegment? _findNearestSegment(double position) {
    _ScrubberSegment? nearest;
    double minDistance = double.infinity;
    for (final segment in _segments) {
      final distance = (segment.startOffset - position).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = segment;
      }
    }
    return nearest;
  }

  void _jumpToSegment(_ScrubberSegment segment) {
    final layoutSegmentIndex = widget.segments.indexWhere((ls) {
      if (ls.bucket is! TimeBucket) return false;
      final bucket = ls.bucket as TimeBucket;
      if (widget.groupBy == GroupPhotoBy.year) return bucket.date.year == segment.date.year;
      return bucket.date.year == segment.date.year && bucket.date.month == segment.date.month;
    });

    if (layoutSegmentIndex >= 0) {
      final target = widget.segments[layoutSegmentIndex].startOffset;
      widget.controller.jumpTo(target.clamp(0.0, widget.controller.position.maxScrollExtent));
    }
  }

  void _onDragEnd(DragEndDetails _) {
    _labelAnimationController.reverse();
    setState(() => _isDragging = false);
    _resetThumbTimer();
  }

  @override
  Widget build(BuildContext ctx) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          RepaintBoundary(child: widget.child),
          if (_isDragging && widget.showSegments)
            ..._segments.where((s) => s.showSegment).map((s) => PositionedDirectional(
                  key: ValueKey('seg_${s.date.millisecondsSinceEpoch}'),
                  top: widget.topPadding + s.startOffset,
                  end: widget.segmentEndOffset,
                  child: widget.segmentBuilder != null
                      ? widget.segmentBuilder!(ctx, s.scrollLabel, s.date)
                      : Container(
                          margin: const EdgeInsets.only(right: 36.0),
                          child: Material(
                            color: Theme.of(ctx).colorScheme.surface,
                            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 28),
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              alignment: Alignment.center,
                              child: Text(
                                s.scrollLabel,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                )),
          ValueListenableBuilder<double>(
            valueListenable: _thumbTopOffset,
            builder: (ctx, offset, _) {
              if (!widget.controller.hasClients) return const SizedBox();
              final nearest = _findNearestSegment(offset);
              final labelText = nearest?.scrollLabel;

              return PositionedDirectional(
                top: offset + widget.topPadding,
                end: widget.thumbEndOffset,
                child: GestureDetector(
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: _onDragUpdate,
                  onVerticalDragEnd: _onDragEnd,
                  child: FadeTransition(
                    opacity: _thumbAnimation,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (labelText != null)
                          FadeTransition(
                            opacity: _labelAnimation,
                            child: widget.labelBuilder?.call(ctx, labelText, _isDragging) ??
                                Container(
                                  margin: const EdgeInsets.only(right: 12.0),
                                  child: Material(
                                    elevation: 4.0,
                                    color: Theme.of(ctx).primaryColor,
                                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 28),
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      alignment: Alignment.center,
                                      child: Text(
                                        labelText,
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                        const SizedBox(width: 8),
                        widget.thumbBuilder?.call(ctx, offset, _isDragging) ??
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _isDragging ? 12 : 8,
                              height: widget.thumbHeight,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: _isDragging 
                                    ? Theme.of(ctx).primaryColor 
                                    : Colors.grey.withAlpha(150),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _isDragging 
                                    ? [BoxShadow(
                                        color: Theme.of(ctx).primaryColor.withAlpha(100), 
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )] 
                                    : [],
                              ),
                            ),
                      ],
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
