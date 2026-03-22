import 'dart:math';

import 'package:flutter/material.dart';

import 'photo_grid_scrubber.dart';
import 'photo_drag_region.dart';
import 'photo_grid_item.dart';
import 'photo_grid_segment.dart';
import 'photo_grid_sliver_segmented_list.dart';
import 'photo_selection_controller.dart';

/// 核心组合组件：提供高性能照片时间轴网格展示功能。
/// 
/// 内部集成 `CustomScrollView` 搭配 `SliverSegmentedList` 实现了照片按日期分组，
/// 并且在滚动时可以通过 `PhotoGridScrubber` 提供悬浮的侧边日期滑块导航。
/// 同时集成了 `PhotoDragRegion` 实现丝滑的跨屏幕拖拽选择体验。
class PhotoGridView extends StatefulWidget {
  /// 待渲染的所有时间轴元素集合。这群元素必须实现 [PhotoGridItem] 接口。
  final List<PhotoGridItem> items;
  
  /// 每行展示的缩略图数量（默认 4）
  final int assetsPerRow;

  /// 项与项之间的间距大小（默认 3.0）
  final double margin;

  /// 单个缩略图的纵横比。
  /// (1.0 = 正方形网格; 3.0 = 适合普通垂直列表的宽边长条)
  final double childAspectRatio;

  /// 列表项时间轴的分组维度规则（[GroupPhotoBy.day], [GroupPhotoBy.month], [GroupPhotoBy.none]等）
  final GroupPhotoBy groupBy;

  /// 接管控制选中状态的全局控制器。
  /// 若传入此控制器，则开启相册的联动选择能力（单选与框选）。如果没有多选需求可以为 null。
  final PhotoSelectionController? selectionController;

  /// 是否启用右侧吸附悬浮的极速滚动轴 (滑动导航条)。
  /// 仅在照片总数量大于20条时自动展示。
  final bool showDragScroll;

  /// 下拉刷新回调（如果为空则不开启下拉刷新）
  final Future<void> Function()? onRefresh;

  /// 照片缩略图单击点击事件回调。
  /// 如果此时 [selectionController] 并未处于激活模式，则会直接触发该回调，通常用于路由至照片大图全屏预览页面。
  final void Function(PhotoGridItem item)? onTap;

  /// 高级布局插槽组合能力：可注入原生的诸如 `SliverAppBar` 或 `SliverPersistentHeader`。
  /// 使得 `PhotoGridView` 的内部滚动区域完美承接顶层的复杂下拉特效/吸顶效果。
  final Widget? topSliver;

  const PhotoGridView({
    super.key,
    required this.items,
    this.assetsPerRow = 4,
    this.margin = 3.0,
    this.childAspectRatio = 1.0,
    this.groupBy = GroupPhotoBy.month,
    this.selectionController,
    this.showDragScroll = true,
    this.onRefresh,
    this.onTap,
    this.topSliver,
  });

  @override
  State<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends State<PhotoGridView> {
  final ScrollController _scrollController = ScrollController();

  final List<Bucket> _buckets = [];
  List<Segment> _segments = [];

  int? _dragAnchorIndex;

  ScrollPhysics? _scrollPhysics;

  double? _lastMaxWidth;
  List<Segment>? _cachedSegments;

  @override
  void initState() {
    super.initState();
    _rebuildRenderList();
  }

  @override
  void didUpdateWidget(PhotoGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.groupBy != widget.groupBy) {
      _rebuildRenderList();
    }
  }

  void _rebuildRenderList() {
    _cachedSegments = null;
    _lastMaxWidth = null;
    _buckets.clear();
    if (widget.items.isEmpty) return;

    int count = 0;
    DateTime? currentDate;

    for (final item in widget.items) {
      final date = item.date;
      if (currentDate == null) {
        currentDate = date;
        count = 1;
      } else {
        bool sameGroup = false;
        if (widget.groupBy == GroupPhotoBy.day) {
          sameGroup =
              date.year == currentDate.year &&
              date.month == currentDate.month &&
              date.day == currentDate.day;
        } else if (widget.groupBy == GroupPhotoBy.month) {
          sameGroup =
              date.year == currentDate.year && date.month == currentDate.month;
        }

        if (sameGroup) {
          count++;
        } else {
          _buckets.add(TimeBucket(date: currentDate, assetCount: count));
          currentDate = date;
          count = 1;
        }
      }
    }
    if (currentDate != null && count > 0) {
      _buckets.add(TimeBucket(date: currentDate, assetCount: count));
    }
  }

  void _setDragStartIndex(PhotoGridItemIndex index) {
    if (widget.selectionController == null) return;
    setState(() {
      _scrollPhysics = const ClampingScrollPhysics();
      _dragAnchorIndex = index.offset;
      
      if (_dragAnchorIndex != null && _dragAnchorIndex! < widget.items.length) {
         final anchorItemId = widget.items[_dragAnchorIndex!].id;
         widget.selectionController!.startDragSelection(anchorItemId);
      }
    });
  }

  void _stopDrag() {
    if (widget.selectionController == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _scrollPhysics = null;
      });
    });
    setState(() {
      widget.selectionController!.endDragSelection();
    });
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

    int start = min(dragAnchor, currentOffset);
    int end = max(dragAnchor, currentOffset);

    final affectedIds = <String>{};
    for (int i = start; i <= end; i++) {
      if (i < widget.items.length) {
        affectedIds.add(widget.items[i].id);
      }
    }

    widget.selectionController!.updateDragSelection(affectedIds);
  }

  Widget _buildHeader(
    BuildContext context,
    Bucket bucket,
    HeaderType type,
    double height,
    int assetOffset,
  ) {
    if (bucket is TimeBucket) {
      String title = '${bucket.date.year}年${bucket.date.month}月';
      if (type == HeaderType.day || type == HeaderType.monthAndDay) {
        title = '${bucket.date.year}年${bucket.date.month}月${bucket.date.day}日';
      }

      final startIndex = assetOffset;
      final endIndex = min(
        assetOffset + bucket.assetCount,
        widget.items.length,
      );
      final sectionIds = widget.items
          .sublist(startIndex, endIndex)
          .map((e) => e.id)
          .toList();

      return SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.selectionController?.isSelectionActive == true && bucket.assetCount > 0)
                AnimatedBuilder(
                  animation: widget.selectionController!,
                  builder: (context, _) {
                    final allSelected = sectionIds.every((id) => widget.selectionController!.selectedIds.contains(id));
                    return GestureDetector(
                      onTap: () {
                        if (allSelected) {
                          for (final id in sectionIds) {
                            widget.selectionController!.selectedIds.remove(id);
                          }
                        } else {
                          widget.selectionController!.selectAll(sectionIds);
                        }
                        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                        widget.selectionController!.notifyListeners();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Icon(
                          allSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: allSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }
    return SizedBox(height: height);
  }

  Widget _buildRow(
    BuildContext context,
    int assetIndex,
    int count,
    double tileHeight,
    double spacing,
    int columnCount,
  ) {
    final end = min(assetIndex + count, widget.items.length);
    // tileWidth can simply be derived from constraints if needed, but since AssetRow is built inside _buildGrid,
    // we can calculate the tile Width by aspectRatio. 
    final tileWidth = tileHeight * widget.childAspectRatio;
    return _AssetRow(
      items: widget.items.sublist(assetIndex, end),
      absoluteOffset: assetIndex,
      width: tileWidth,
      height: tileHeight,
      margin: spacing,
      assetsPerRow: columnCount,
      selectionController: widget.selectionController,
      onTap: widget.onTap,
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (_cachedSegments != null && _lastMaxWidth == screenWidth && _buckets.isNotEmpty) {
           _segments = _cachedSegments!;
        } else {
          final rowSpacing = widget.margin * (widget.assetsPerRow - 1);
          final double tileWidth = (screenWidth - rowSpacing) / widget.assetsPerRow;
          final double tileHeight = tileWidth / widget.childAspectRatio;

          final builder = FixedSegmentBuilder(
            buckets: _buckets,
            tileHeight: tileHeight,
            columnCount: widget.assetsPerRow,
            spacing: widget.margin,
            groupBy: widget.groupBy == GroupPhotoBy.day
                ? GroupAssetsBy.day
                : widget.groupBy == GroupPhotoBy.month
                ? GroupAssetsBy.month
                : GroupAssetsBy.auto,
            headerBuilder: _buildHeader,
            rowBuilder: _buildRow,
          );

          _segments = builder.generate();
          _cachedSegments = _segments;
          _lastMaxWidth = screenWidth;
        }

        final listWidget = PrimaryScrollController(
          controller: _scrollController,
          child: CustomScrollView(
            physics: _scrollPhysics,
            slivers: [
              if (widget.topSliver != null) widget.topSliver!,
              SliverSegmentedList(
                segments: _segments,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final segment = _segments.findByIndex(index);
                    return segment?.builder(context, index) ??
                        const SizedBox.shrink();
                  },
                  childCount: _segments.isNotEmpty
                      ? _segments.last.lastIndex + 1
                      : 0,
                ),
              ),
            ],
          ),
        );

        final child = (widget.showDragScroll && widget.items.length >= 20)
            ? PhotoGridScrubber(
                controller: _scrollController,
                segments: _segments,
                timelineHeight: MediaQuery.of(context).size.height,
                topPadding: MediaQuery.of(context).padding.top + 50,
                bottomPadding: MediaQuery.of(context).padding.bottom + 48.0,
                child: listWidget,
              )
            : listWidget;

        return widget.onRefresh == null
            ? child
            : RefreshIndicator(onRefresh: widget.onRefresh!, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PhotoDragRegion(
      onStart: _setDragStartIndex,
      onAssetEnter: _handleDragAssetEnter,
      onEnd: _stopDrag,
      onScroll: _dragScroll,
      child: _buildGrid(context),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final List<PhotoGridItem> items;
  final int absoluteOffset;
  final double width;
  final double height;
  final double margin;
  final int assetsPerRow;
  final PhotoSelectionController? selectionController;
  final void Function(PhotoGridItem)? onTap;

  const _AssetRow({
    required this.items,
    required this.absoluteOffset,
    required this.width,
    required this.height,
    required this.margin,
    required this.assetsPerRow,
    this.selectionController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final last = index + 1 == assetsPerRow;
        final offsetIndex = absoluteOffset + index;

        final itemWidget = PhotoGridItemIndexWrapper(
          offset: offsetIndex,
          child: SizedBox(
            width: width,
            height: height,
            child: Container(
              margin: EdgeInsets.only(right: last ? 0.0 : margin),
              child: selectionController != null
                  ? AnimatedBuilder(
                      animation: selectionController!,
                      builder: (context, _) => _buildItemContent(context, item),
                    )
                  : _buildItemContent(context, item),
            ),
          ),
        );

        return itemWidget;
      }).toList(),
    );
  }

  Widget _buildItemContent(BuildContext context, PhotoGridItem item) {
    final bool selectionActive = selectionController?.isSelectionActive ?? false;
    final bool isSelected = selectionController?.selectedIds.contains(item.id) ?? false;

    return GestureDetector(
      onTap: () {
        if (selectionActive) {
          selectionController!.toggleItem(item.id);
        } else {
          onTap?.call(item);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          item.buildThumbnail(context),
          if (selectionActive)
            Container(
              color: isSelected
                  ? Colors.black.withAlpha(102)
                  : Colors.transparent,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
              ),
            ),
        ],
      ),
    );
  }
}
