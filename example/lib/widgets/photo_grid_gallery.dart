import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';

/// 这是一个业务层面的组合组件示例。
/// 它将列表视图、滑动条和拖拽选择区域组合在一起，
/// 实现了曾经 PhotoGridView 内部集成的所有功能，但现在是以组合的方式。
class PhotoGridGallery extends StatefulWidget {
  final List<PhotoGridItem> items;
  final PhotoSelectionController? selectionController;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final double? mainAxisExtent;
  final GroupPhotoBy groupBy;
  final bool showScrubber;
  final void Function(PhotoGridItem)? onTap;
  final void Function(PhotoGridItem)? onDoubleTap;
  final void Function(PhotoGridItem)? onLongPress;
  final void Function(PhotoGridItem item, Offset position)? onSecondaryTap;
  final List<Widget>? topSlivers;
  final List<Widget>? endSlivers;
  final ScrubberLabelBuilder? scrubberLabelBuilder;
  final ScrubberThumbBuilder? scrubberThumbBuilder;
  final ScrubberSegmentBuilder? scrubberSegmentBuilder;
  final Duration? scrubberFadeInDuration;
  final Duration? scrubberAutoHideDuration;
  final double? scrubberThumbHeight;
  final int? scrubberSnapMinMonths;
  final double? scrubberMinSegmentSpacing;
  final double? scrubberSegmentEndOffset;
  final double? scrubberLabelEndOffset;
  final double? scrubberThumbEndOffset;
  final double? scrubberSnapThreshold;
  final bool alwaysShowScrubber;
  final double? scrubberTopPadding;
  final double? scrubberBottomPadding;
  final double? scrubberScrollOffsetBaseline;
  final VoidCallback? onScrubberDragStart;
  final VoidCallback? onScrubberDragUpdate;
  final VoidCallback? onScrubberDragEnd;
  final bool showScrubberPrompt;
  final bool showScrubberRuler;
  final PhotoGridItemBuilder itemBuilder;
  final PhotoGridHeaderBuilder? headerBuilder;
  final SelectionBoxPainterBuilder? selectionBoxPainterBuilder;
  final double Function(HeaderType)? headerExtentCalculator;
  final bool enableGrouping;

  const PhotoGridGallery({
    super.key,
    required this.items,
    this.selectionController,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 3.0,
    this.crossAxisSpacing = 3.0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
    this.groupBy = GroupPhotoBy.month,
    this.showScrubber = true,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.topSlivers,
    this.endSlivers,
    this.scrubberLabelBuilder,
    this.scrubberThumbBuilder,
    this.scrubberSegmentBuilder,
    this.scrubberFadeInDuration,
    this.scrubberAutoHideDuration,
    this.scrubberThumbHeight,
    this.scrubberSnapMinMonths,
    this.scrubberMinSegmentSpacing,
    this.scrubberSegmentEndOffset,
    this.scrubberLabelEndOffset,
    this.scrubberThumbEndOffset,
    this.scrubberSnapThreshold,
    this.alwaysShowScrubber = false,
    this.scrubberTopPadding,
    this.scrubberBottomPadding,
    this.scrubberScrollOffsetBaseline,
    this.onScrubberDragStart,
    this.onScrubberDragUpdate,
    this.onScrubberDragEnd,
    this.showScrubberPrompt = true,
    this.showScrubberRuler = true,
    required this.itemBuilder,
    this.headerBuilder,
    this.selectionBoxPainterBuilder,
    this.headerExtentCalculator,
    this.enableGrouping = true,
  });

  /// 宫格模式：指定每行个数 [crossAxisCount] 和项宽高比 [childAspectRatio]。
  factory PhotoGridGallery.grid({
    Key? key,
    required List<PhotoGridItem> items,
    required int crossAxisCount,
    double mainAxisSpacing = 3.0,
    double crossAxisSpacing = 3.0,
    double childAspectRatio = 1.0,
    double? mainAxisExtent,
    GroupPhotoBy groupBy = GroupPhotoBy.month,
    bool showScrubber = true,
    PhotoSelectionController? selectionController,
    void Function(PhotoGridItem)? onTap,
    void Function(PhotoGridItem)? onDoubleTap,
    void Function(PhotoGridItem)? onLongPress,
    void Function(PhotoGridItem item, Offset position)? onSecondaryTap,
    List<Widget>? topSlivers,
    List<Widget>? endSlivers,
    required PhotoGridItemBuilder itemBuilder,
    PhotoGridHeaderBuilder? headerBuilder,
    // Scrubber 配置
    ScrubberLabelBuilder? scrubberLabelBuilder,
    ScrubberThumbBuilder? scrubberThumbBuilder,
    ScrubberSegmentBuilder? scrubberSegmentBuilder,
    Duration? scrubberFadeInDuration,
    Duration? scrubberAutoHideDuration,
    double? scrubberThumbHeight,
    int? scrubberSnapMinMonths,
    double? scrubberMinSegmentSpacing,
    double? scrubberSegmentEndOffset,
    double? scrubberLabelEndOffset,
    double? scrubberThumbEndOffset,
    double? scrubberSnapThreshold,
    bool alwaysShowScrubber = false,
    double? scrubberTopPadding,
    double? scrubberBottomPadding,
    double? scrubberScrollOffsetBaseline,
    VoidCallback? onScrubberDragStart,
    VoidCallback? onScrubberDragUpdate,
    VoidCallback? onScrubberDragEnd,
    bool showScrubberPrompt = true,
    bool showScrubberRuler = true,
    SelectionBoxPainterBuilder? selectionBoxPainterBuilder,
    double Function(HeaderType)? headerExtentCalculator,
    bool enableGrouping = true,
  }) {
    return PhotoGridGallery(
    key: key,
    items: items,
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
    mainAxisExtent: mainAxisExtent,
    groupBy: groupBy,
    showScrubber: showScrubber,
    selectionController: selectionController,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onSecondaryTap: onSecondaryTap,
    topSlivers: topSlivers,
    endSlivers: endSlivers,
    itemBuilder: itemBuilder,
    headerBuilder: headerBuilder,
    scrubberLabelBuilder: scrubberLabelBuilder,
    scrubberThumbBuilder: scrubberThumbBuilder,
    scrubberSegmentBuilder: scrubberSegmentBuilder,
    scrubberFadeInDuration: scrubberFadeInDuration,
    scrubberAutoHideDuration: scrubberAutoHideDuration,
    scrubberThumbHeight: scrubberThumbHeight,
    scrubberSnapMinMonths: scrubberSnapMinMonths,
    scrubberMinSegmentSpacing: scrubberMinSegmentSpacing,
    scrubberSegmentEndOffset: scrubberSegmentEndOffset,
    scrubberLabelEndOffset: scrubberLabelEndOffset,
    scrubberThumbEndOffset: scrubberThumbEndOffset,
    scrubberSnapThreshold: scrubberSnapThreshold,
    alwaysShowScrubber: alwaysShowScrubber,
    scrubberTopPadding: scrubberTopPadding,
    scrubberBottomPadding: scrubberBottomPadding,
    scrubberScrollOffsetBaseline: scrubberScrollOffsetBaseline,
    onScrubberDragStart: onScrubberDragStart,
    onScrubberDragUpdate: onScrubberDragUpdate,
    onScrubberDragEnd: onScrubberDragEnd,
    showScrubberPrompt: showScrubberPrompt,
    showScrubberRuler: showScrubberRuler,
    selectionBoxPainterBuilder: selectionBoxPainterBuilder,
    headerExtentCalculator: headerExtentCalculator,
    enableGrouping: enableGrouping,
  );
  }

  /// 列表模式：强制一行一个，并指定固定的项高度 [itemHeight]。
  factory PhotoGridGallery.list({
    Key? key,
    required List<PhotoGridItem> items,
    required double itemHeight,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    GroupPhotoBy groupBy = GroupPhotoBy.month,
    bool showScrubber = true,
    PhotoSelectionController? selectionController,
    void Function(PhotoGridItem)? onTap,
    void Function(PhotoGridItem)? onDoubleTap,
    void Function(PhotoGridItem)? onLongPress,
    void Function(PhotoGridItem item, Offset position)? onSecondaryTap,
    List<Widget>? topSlivers,
    List<Widget>? endSlivers,
    required PhotoGridItemBuilder itemBuilder,
    PhotoGridHeaderBuilder? headerBuilder,
    // Scrubber 配置
    ScrubberLabelBuilder? scrubberLabelBuilder,
    ScrubberThumbBuilder? scrubberThumbBuilder,
    ScrubberSegmentBuilder? scrubberSegmentBuilder,
    Duration? scrubberFadeInDuration,
    Duration? scrubberAutoHideDuration,
    double? scrubberThumbHeight,
    int? scrubberSnapMinMonths,
    double? scrubberMinSegmentSpacing,
    double? scrubberSegmentEndOffset,
    double? scrubberLabelEndOffset,
    double? scrubberThumbEndOffset,
    double? scrubberSnapThreshold,
    bool alwaysShowScrubber = false,
    double? scrubberTopPadding,
    double? scrubberBottomPadding,
    double? scrubberScrollOffsetBaseline,
    VoidCallback? onScrubberDragStart,
    VoidCallback? onScrubberDragUpdate,
    VoidCallback? onScrubberDragEnd,
    bool showScrubberPrompt = true,
    bool showScrubberRuler = true,
    SelectionBoxPainterBuilder? selectionBoxPainterBuilder,
    double Function(HeaderType)? headerExtentCalculator,
    bool enableGrouping = true,
  }) {
    return PhotoGridGallery(
    key: key,
    items: items,
    crossAxisCount: 1,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisExtent: itemHeight,
    childAspectRatio: 1.0,
    groupBy: groupBy,
    showScrubber: showScrubber,
    selectionController: selectionController,
    onTap: onTap,
    onDoubleTap: onDoubleTap,
    onLongPress: onLongPress,
    onSecondaryTap: onSecondaryTap,
    topSlivers: topSlivers,
    endSlivers: endSlivers,
    itemBuilder: itemBuilder,
    headerBuilder: headerBuilder,
    scrubberLabelBuilder: scrubberLabelBuilder,
    scrubberThumbBuilder: scrubberThumbBuilder,
    scrubberSegmentBuilder: scrubberSegmentBuilder,
    scrubberFadeInDuration: scrubberFadeInDuration,
    scrubberAutoHideDuration: scrubberAutoHideDuration,
    scrubberThumbHeight: scrubberThumbHeight,
    scrubberSnapMinMonths: scrubberSnapMinMonths,
    scrubberMinSegmentSpacing: scrubberMinSegmentSpacing,
    scrubberSegmentEndOffset: scrubberSegmentEndOffset,
    scrubberLabelEndOffset: scrubberLabelEndOffset,
    scrubberThumbEndOffset: scrubberThumbEndOffset,
    scrubberSnapThreshold: scrubberSnapThreshold,
    alwaysShowScrubber: alwaysShowScrubber,
    scrubberTopPadding: scrubberTopPadding,
    scrubberBottomPadding: scrubberBottomPadding,
    scrubberScrollOffsetBaseline: scrubberScrollOffsetBaseline,
    onScrubberDragStart: onScrubberDragStart,
    onScrubberDragUpdate: onScrubberDragUpdate,
    onScrubberDragEnd: onScrubberDragEnd,
    showScrubberPrompt: showScrubberPrompt,
    showScrubberRuler: showScrubberRuler,
    selectionBoxPainterBuilder: selectionBoxPainterBuilder,
    headerExtentCalculator: headerExtentCalculator,
    enableGrouping: enableGrouping,
  );
  }

  @override
  State<PhotoGridGallery> createState() => _PhotoGridGalleryState();
}

class _PhotoGridGalleryState extends State<PhotoGridGallery> {
  final ScrollController _scrollController = ScrollController();
  List<Segment> _segments = [];
  Map<String, Rect> _itemLayoutMap = {};
  
  // 用于拖拽选择
  int? _dragAnchorIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onSegmentsChanged(List<Segment> segments) {
    if (mounted) {
      setState(() {
        _segments = segments;
      });
    }
  }

  void _onLayoutInfoChanged(Map<String, Rect> layoutMap) {
    if (mounted) {
      setState(() {
        _itemLayoutMap = layoutMap;
      });
    }
  }

  // 以下是之前继承自 PhotoGridView 的拖拽选择逻辑，现在在业务组合层实现
  void _setDragStartIndex(PhotoGridItemIndex index) {
    if (widget.selectionController == null) return;
    setState(() {
      _dragAnchorIndex = index.offset;
      
      if (_dragAnchorIndex != null && _dragAnchorIndex! < widget.items.length) {
         final anchorItemId = widget.items[_dragAnchorIndex!].id;
         widget.selectionController!.startDragSelection(anchorItemId);
      }
    });
  }

  void _stopDrag() {
    if (widget.selectionController == null) return;
    widget.selectionController!.endDragSelection();
  }

  void _dragScroll(double delta) {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = (currentOffset + delta).clamp(0.0, maxScrollExtent);
    _scrollController.jumpTo(targetOffset);
  }

  void _handleDragAssetEnter(PhotoGridItemIndex index) {
    if (_dragAnchorIndex == null || widget.selectionController == null) return;
    final dragAnchor = _dragAnchorIndex!;
    final currentOffset = index.offset;

    int start = (dragAnchor < currentOffset) ? dragAnchor : currentOffset;
    int end = (dragAnchor > currentOffset) ? dragAnchor : currentOffset;

    final affectedIds = <String>{};
    for (int i = start; i <= end; i++) {
      if (i < widget.items.length) {
        affectedIds.add(widget.items[i].id);
      }
    }
    widget.selectionController!.updateDragSelection(affectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;

        Widget grid = PhotoGridView(
          items: widget.items,
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing,
          crossAxisSpacing: widget.crossAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
          mainAxisExtent: widget.mainAxisExtent,
          groupBy: widget.groupBy,
          selectionController: widget.selectionController,
          controller: _scrollController,
          onSegmentsChanged: _onSegmentsChanged,
          onLayoutInfoChanged: _onLayoutInfoChanged,
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          onSecondaryTap: widget.onSecondaryTap,
          topSlivers: widget.topSlivers,
          endSlivers: widget.endSlivers,
          itemBuilder: widget.itemBuilder,
          headerBuilder: widget.headerBuilder,
          headerExtentCalculator: widget.headerExtentCalculator,
          enableGrouping: widget.enableGrouping,
          disableInternalSelectionToggle: widget.selectionController != null,
        );

        // 包装拖拽选择区域
        grid = PhotoDragRegion(
          onStart: _setDragStartIndex,
          onAssetEnter: _handleDragAssetEnter,
          onEnd: _stopDrag,
          onScroll: _dragScroll,
          child: grid,
        );

        // 包装桌面端特有的键鼠交互
        if (widget.selectionController != null) {
          grid = PhotoDesktopSelectionRegion(
            selectionController: widget.selectionController!,
            allItemIds: widget.items.map((e) => e.id).toList(),
            crossAxisCount: widget.crossAxisCount,
            scrollController: _scrollController,
            itemLayoutMap: _itemLayoutMap,
            selectionBoxPainterBuilder: widget.selectionBoxPainterBuilder,
            child: grid,
          );
        }

        // 如果启用，包装滑动条
        if (widget.showScrubber && widget.items.length >= 20 && _segments.isNotEmpty) {
          grid = PhotoGridScrubber(
            controller: _scrollController,
            segments: _segments,
            timelineHeight: height,
            topPadding: widget.scrubberTopPadding ?? (MediaQuery.of(context).padding.top + 16.0),
            bottomPadding: widget.scrubberBottomPadding ?? (MediaQuery.of(context).padding.bottom + 16.0),
            labelBuilder: widget.scrubberLabelBuilder,
            thumbBuilder: widget.scrubberThumbBuilder,
            segmentBuilder: widget.scrubberSegmentBuilder,
            fadeInDuration: widget.scrubberFadeInDuration ?? const Duration(milliseconds: 150),
            autoHideDuration: widget.scrubberAutoHideDuration ?? const Duration(milliseconds: 2000),
            thumbHeight: widget.scrubberThumbHeight ?? 48.0,
            snapMinMonths: widget.scrubberSnapMinMonths ?? 12,
            minSegmentSpacing: widget.scrubberMinSegmentSpacing ?? 28.0,
            segmentEndOffset: widget.scrubberSegmentEndOffset ?? 100.0,
            labelEndOffset: widget.scrubberLabelEndOffset ?? 12.0,
            thumbEndOffset: widget.scrubberThumbEndOffset ?? 0.0,
            snapThreshold: widget.scrubberSnapThreshold ?? 16.0,
            alwaysShow: widget.alwaysShowScrubber,
            groupBy: widget.groupBy,
            scrollOffsetBaseline: widget.scrubberScrollOffsetBaseline ?? 0.0,
            onDragStart: widget.onScrubberDragStart,
            onDragUpdate: widget.onScrubberDragUpdate,
            onDragEnd: widget.onScrubberDragEnd,
            showPrompt: widget.showScrubberPrompt,
            showRuler: widget.showScrubberRuler,
            child: grid,
          );
        }

        // 在桌面端，默认的 Scrollbar 可能会与我们自定义的冲突，
        // 这里通过 ScrollConfiguration 禁用默认滚动条。
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: grid,
        );
      },
    );
  }
}
