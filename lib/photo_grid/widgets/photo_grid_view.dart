import 'dart:math';

import 'package:flutter/material.dart';

import 'photo_grid_item.dart';
import '../core/photo_grid_segment.dart';
import '../core/photo_grid_sliver_segmented_list.dart';
import '../logic/photo_drag_region.dart';
import '../logic/photo_selection_controller.dart';

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

  /// 可选的滚动控制器。若不提供则内部自动创建一个。
  /// 当需要与外部组件（如 PhotoGridScrubber）联动时应当传入。
  final ScrollController? controller;

  /// 当内部段落数据重新生成后的回调。通常给 Scrubber 用于同步进度。
  final void Function(List<Segment> segments)? onSegmentsChanged;

  /// 下拉刷新回调
  final Future<void> Function()? onRefresh;

  /// 项点击回调
  final void Function(PhotoGridItem item)? onTap;

  /// 额外的顶部 Sliver
  final Widget? topSliver;

  const PhotoGridView({
    super.key,
    required this.items,
    this.assetsPerRow = 4,
    this.margin = 3.0,
    this.childAspectRatio = 1.0,
    this.groupBy = GroupPhotoBy.month,
    this.selectionController,
    this.controller,
    this.onSegmentsChanged,
    this.onRefresh,
    this.onTap,
    this.topSliver,
  });

  @override
  State<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends State<PhotoGridView> {
  ScrollController? _internalController;
  ScrollController get _scrollController => widget.controller ?? _internalController!;

  final List<Bucket> _buckets = [];
  List<Segment> _segments = [];

  double? _lastMaxWidth;
  List<Segment>? _cachedSegments;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = ScrollController();
    }
    _rebuildRenderList();
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PhotoGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      } else if (widget.controller == null) {
        _internalController = ScrollController();
      }
    }
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

  /// 获取当前生成的段落信息。用于给外部同步（如 Scrubber）。
  List<Segment> get segments => _segments;

  @override
  Widget build(BuildContext context) {
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
          
          if (widget.onSegmentsChanged != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               widget.onSegmentsChanged?.call(_segments);
            });
          }
        }

        final listWidget = PrimaryScrollController(
          controller: _scrollController,
          child: CustomScrollView(
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

        return widget.onRefresh == null
            ? listWidget
            : RefreshIndicator(onRefresh: widget.onRefresh!, child: listWidget);
      },
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
