import 'dart:math';

import 'package:flutter/material.dart';

import 'photo_grid_item.dart';
import '../core/photo_grid_segment.dart';
import '../core/photo_grid_sliver_segmented_list.dart';
import '../logic/photo_drag_region.dart';
import '../logic/photo_selection_controller.dart';

/// 构建网格照片项的函数：将数据模型转换为渲染所需的 Widget。
typedef PhotoGridItemBuilder = Widget Function(BuildContext context, PhotoGridItem item);
typedef PhotoGridHeaderBuilder = Widget Function(
  BuildContext context,
  Bucket bucket,
  HeaderType header,
  double height,
  int assetOffset,
);
typedef PhotoGridRowBuilder = Widget Function(
  BuildContext context,
  int assetIndex,
  int assetCount,
  double tileWidth,
  double tileHeight,
  double mainAxisSpacing,
  double crossAxisSpacing,
  int crossAxisCount,
);

/// 核心组合组件：提供高性能照片时间轴网格展示功能。
/// 
/// 内部集成 `CustomScrollView` 搭配 `SliverSegmentedList` 实现了照片按日期分组，
/// 并且在滚动时可以通过 `PhotoGridScrubber` 提供悬浮的侧边日期滑块导航。
/// 同时集成了 `PhotoDragRegion` 实现丝滑的跨屏幕拖拽选择体验。
class PhotoGridView extends StatefulWidget {
  /// 待渲染的所有时间轴元素集合。
  final List<PhotoGridItem> items;
  
  /// 照片项构建器：业务层通过此函数定义照片（缩略图）的展示样式。
  final PhotoGridItemBuilder itemBuilder;
  
  /// 每行展示的缩略图数量（默认 4）
  final int crossAxisCount;

  /// 项与项之间的间距大小（默认 3.0）
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final double? mainAxisExtent;

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

  /// 额外的顶部 Sliver 列表，直接传入 CustomScrollView 以支持独立的吸顶/偏移逻辑。
  final List<Widget>? topSlivers;

  /// 当内部布局信息（如每个项的 Rect）发生变化时触发的回调。
  /// 通常用于外部组件需要知道内部项的精确位置信息时。
  final void Function(Map<String, Rect>)? onLayoutInfoChanged;

  const PhotoGridView({
    super.key,
    required this.items,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 4.0,
    this.crossAxisSpacing = 4.0,
    this.childAspectRatio = 1.0,
    this.mainAxisExtent,
    this.groupBy = GroupPhotoBy.month,
    this.selectionController,
    this.controller,
    this.onSegmentsChanged,
    this.onRefresh,
    this.onTap,
    this.topSlivers,
    this.onLayoutInfoChanged,
    required this.itemBuilder,
  });

  /// 宫格模式：指定每行个数 [crossAxisCount] 和项宽高比 [childAspectRatio]。
  factory PhotoGridView.grid({
    Key? key,
    required List<PhotoGridItem> items,
    required int crossAxisCount,
    double mainAxisSpacing = 4.0,
    double crossAxisSpacing = 4.0,
    double childAspectRatio = 1.0,
    double? mainAxisExtent,
    GroupPhotoBy groupBy = GroupPhotoBy.month,
    PhotoSelectionController? selectionController,
    ScrollController? controller,
    void Function(List<Segment>)? onSegmentsChanged,
    Future<void> Function()? onRefresh,
    void Function(PhotoGridItem)? onTap,
    List<Widget>? topSlivers,
    void Function(Map<String, Rect>)? onLayoutInfoChanged,
    required PhotoGridItemBuilder itemBuilder,
  }) => PhotoGridView(
    key: key,
    items: items,
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
    mainAxisExtent: mainAxisExtent,
    groupBy: groupBy,
    selectionController: selectionController,
    controller: controller,
    onSegmentsChanged: onSegmentsChanged,
    onRefresh: onRefresh,
    onTap: onTap,
    topSlivers: topSlivers,
    onLayoutInfoChanged: onLayoutInfoChanged,
    itemBuilder: itemBuilder,
  );

  /// 列表模式：强制一行一个，并指定固定的项高度 [itemHeight]。
  factory PhotoGridView.list({
    Key? key,
    required List<PhotoGridItem> items,
    required double itemHeight,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    GroupPhotoBy groupBy = GroupPhotoBy.month,
    PhotoSelectionController? selectionController,
    ScrollController? controller,
    void Function(List<Segment>)? onSegmentsChanged,
    Future<void> Function()? onRefresh,
    void Function(PhotoGridItem)? onTap,
    List<Widget>? topSlivers,
    void Function(Map<String, Rect>)? onLayoutInfoChanged,
    required PhotoGridItemBuilder itemBuilder,
  }) => PhotoGridView(
    key: key,
    items: items,
    crossAxisCount: 1,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisExtent: itemHeight,
    childAspectRatio: 1.0,
    groupBy: groupBy,
    selectionController: selectionController,
    controller: controller,
    onSegmentsChanged: onSegmentsChanged,
    onRefresh: onRefresh,
    onTap: onTap,
    topSlivers: topSlivers,
    onLayoutInfoChanged: onLayoutInfoChanged,
    itemBuilder: itemBuilder,
  );

  @override
  State<PhotoGridView> createState() => _PhotoGridViewState();
}

class _PhotoGridViewState extends State<PhotoGridView> {
  ScrollController? _internalController;
  ScrollController get _scrollController => widget.controller ?? _internalController!;

  final List<Bucket> _buckets = [];
  List<Segment> _segments = [];

  double? _lastMaxWidth;
  int? _lastCrossAxisCount;
  double? _lastMainAxisSpacing;
  double? _lastCrossAxisSpacing;
  double? _lastAspectRatio;
  double? _lastMainAxisExtent;
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
        oldWidget.groupBy != widget.groupBy ||
        oldWidget.crossAxisCount != widget.crossAxisCount ||
        oldWidget.mainAxisSpacing != widget.mainAxisSpacing ||
        oldWidget.crossAxisSpacing != widget.crossAxisSpacing ||
        oldWidget.childAspectRatio != widget.childAspectRatio ||
        oldWidget.mainAxisExtent != widget.mainAxisExtent) {
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
        } else if (widget.groupBy == GroupPhotoBy.year) {
          sameGroup = date.year == currentDate.year;
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

  /// 构建时间轴段落的头部标题。
  Widget _buildHeader(
    BuildContext context,
    Bucket bucket,
    HeaderType type,
    double height,
    int assetOffset,
  ) {
    if (bucket is TimeBucket) {
      if (assetOffset < 0 || assetOffset >= widget.items.length) {
        return SizedBox(height: height);
      }

      String title = '${bucket.date.year}年度';
      if (type == HeaderType.month) {
        title = '${bucket.date.year}年${bucket.date.month}月';
      } else if (type == HeaderType.day || type == HeaderType.monthAndDay) {
        title = '${bucket.date.year}年${bucket.date.month}月${bucket.date.day}日';
      }

      final startIndex = assetOffset;
      final endIndex = min(
        assetOffset + bucket.assetCount,
        widget.items.length,
      );

      if (startIndex >= endIndex) {
         return SizedBox(height: height);
      }

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

  /// 构建网格中的一行照片。
  Widget _buildRow(
    BuildContext context,
    int assetIndex,
    int count,
    double tileWidth,
    double tileHeight,
    double mainAxisSpacing,
    double crossAxisSpacing,
    int crossAxisCount,
  ) {
    if (assetIndex < 0 || assetIndex >= widget.items.length) {
      return const SizedBox.shrink();
    }
    final end = min(assetIndex + count, widget.items.length);

    if (assetIndex >= end) {
      return const SizedBox.shrink();
    }

    return _AssetRow(
      items: widget.items.sublist(assetIndex, end),
      absoluteOffset: assetIndex,
      width: tileWidth,
      height: tileHeight,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      crossAxisCount: crossAxisCount,
      selectionController: widget.selectionController,
      onTap: widget.onTap,
      itemBuilder: widget.itemBuilder,
    );
  }

  /// 获取当前生成的段落信息。用于给外部同步（如 Scrubber）。
  List<Segment> get segments => _segments;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        if (_cachedSegments != null && 
            _lastMaxWidth == screenWidth && 
            _lastCrossAxisCount == widget.crossAxisCount &&
            _lastMainAxisSpacing == widget.mainAxisSpacing &&
            _lastCrossAxisSpacing == widget.crossAxisSpacing &&
            _lastAspectRatio == widget.childAspectRatio &&
            _lastMainAxisExtent == widget.mainAxisExtent &&
            _buckets.isNotEmpty) {
           _segments = _cachedSegments!;
        } else {
          final double mainAxisSpacing = widget.mainAxisSpacing;
          final double crossAxisSpacing = widget.crossAxisSpacing;
          final int crossAxisCount = widget.crossAxisCount;
          
          final double tileWidth = (screenWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
          final double tileHeight = widget.mainAxisExtent ?? (tileWidth / widget.childAspectRatio);

          final builder = FixedSegmentBuilder(
            buckets: _buckets,
            tileHeight: tileHeight,
            tileWidth: tileWidth,
            columnCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            groupBy: widget.groupBy == GroupPhotoBy.day
                ? GroupAssetsBy.day
                : widget.groupBy == GroupPhotoBy.month
                ? GroupAssetsBy.month
                : widget.groupBy == GroupPhotoBy.year
                ? GroupAssetsBy.year
                : GroupAssetsBy.auto,
          );

          final List<Segment> generatedSegments = builder.generate();
          
          // 计算全量项的布局坐标用于桌面端圈选持久化
          final Map<String, Rect> layoutMap = {};
          for (final segment in generatedSegments) {
            if (segment is FixedSegment) {
               final assetCount = segment.bucket.assetCount;
               final rows = (assetCount / segment.columnCount).ceil();
               final startAssetIndex = segment.firstAssetIndex;
               
               for (int r = 0; r < rows; r++) {
                 final rowY = segment.gridOffset + (r * (segment.tileHeight + segment.mainAxisSpacing));
                 final rowStartAsset = startAssetIndex + (r * segment.columnCount);
                 final rowCount = min(segment.columnCount, assetCount - (r * segment.columnCount));
                 
                 for (int c = 0; c < rowCount; c++) {
                   final assetIndex = rowStartAsset + c;
                   if (assetIndex < widget.items.length) {
                     final item = widget.items[assetIndex];
                     final x = c * (segment.tileWidth + segment.crossAxisSpacing);
                     layoutMap[item.id] = Rect.fromLTWH(x, rowY, segment.tileWidth, segment.tileHeight);
                   }
                 }
               }
            }
          }

          _segments = generatedSegments;
          _cachedSegments = _segments;
          _lastMaxWidth = screenWidth;
          _lastCrossAxisCount = widget.crossAxisCount;
          _lastMainAxisSpacing = widget.mainAxisSpacing;
          _lastCrossAxisSpacing = widget.crossAxisSpacing;
          _lastAspectRatio = widget.childAspectRatio;
          _lastMainAxisExtent = widget.mainAxisExtent;
          
          if (widget.onSegmentsChanged != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               widget.onSegmentsChanged?.call(_segments);
            });
          }

          if (widget.onLayoutInfoChanged != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               widget.onLayoutInfoChanged?.call(layoutMap);
            });
          }
        }

        final listWidget = PrimaryScrollController(
          controller: _scrollController,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), // 确保始终可滚动触发通知
            slivers: [
              if (widget.topSlivers != null) ...widget.topSlivers!,
              SliverSegmentedList(
                segments: _segments,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final segment = _segments.findByIndex(index);
                    return _buildSegmentChild(context, segment, index);
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

  /// 构建段落中的具体子项（Header 或 Row）。
  Widget _buildSegmentChild(BuildContext context, Segment? segment, int index) {
    if (segment == null) return const SizedBox.shrink();

    if (segment is FixedSegment) {
      if (index == segment.firstIndex) {
        return _buildHeader(
          context,
          segment.bucket,
          segment.header,
          segment.headerExtent,
          segment.firstAssetIndex,
        );
      }

      final rowIndexInSegment = index - (segment.firstIndex + 1);
      final assetIndex = rowIndexInSegment * segment.columnCount;
      final assetCount = segment.bucket.assetCount;

      // 计算当前行具体包含多少个项（如果是段落最后一行，可能少于 columnCount）
      int numberOfAssets = segment.columnCount;
      if (assetIndex + segment.columnCount > assetCount) {
        numberOfAssets = assetCount - assetIndex;
      }

      return _buildRow(
        context,
        segment.firstAssetIndex + assetIndex,
        numberOfAssets,
        segment.tileWidth,
        segment.tileHeight,
        segment.mainAxisSpacing,
        segment.crossAxisSpacing,
        segment.columnCount,
      );
    }

    return const SizedBox.shrink();
  }
}

class _AssetRow extends StatelessWidget {
  final List<PhotoGridItem> items;
  final int absoluteOffset;
  final double width;
  final double height;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final int crossAxisCount;
  final PhotoSelectionController? selectionController;
  final void Function(PhotoGridItem)? onTap;
  final PhotoGridItemBuilder itemBuilder;

  const _AssetRow({
    required this.items,
    required this.absoluteOffset,
    required this.width,
    required this.height,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    required this.crossAxisCount,
    this.selectionController,
    this.onTap,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // 列表模式或者单项行优化：强制填满宽度以避免渲染细缝
    if (crossAxisCount == 1 && items.length == 1) {
      final item = items.first;
      return PhotoGridItemIndexWrapper(
        offset: absoluteOffset,
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: _buildItemContent(context, item, absoluteOffset),
        ),
      );
    }

    // 满行优化：使用 Expanded 动态平分宽度，彻底解决 sub-pixel 留白问题
    if (items.length == crossAxisCount) {
      return Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final last = index + 1 == crossAxisCount;
          final offsetIndex = absoluteOffset + index;

          return Expanded(
            child: PhotoGridItemIndexWrapper(
              offset: offsetIndex,
              child: SizedBox(
                height: height,
                child: Container(
                  margin: EdgeInsets.only(right: last ? 0.0 : crossAxisSpacing),
                  child: selectionController != null
                      ? AnimatedBuilder(
                          animation: selectionController!,
                          builder: (context, _) => _buildItemContent(context, item, offsetIndex),
                        )
                      : _buildItemContent(context, item, offsetIndex),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    // 不满行（通常是 Bucket 的最后一行）：保持原有的固定宽度计算，遵循 GridView 靠左对齐逻辑
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final last = index + 1 == crossAxisCount;
        final offsetIndex = absoluteOffset + index;

        return PhotoGridItemIndexWrapper(
          offset: offsetIndex,
          child: SizedBox(
            width: width,
            height: height,
            child: Container(
              margin: EdgeInsets.only(right: last ? 0.0 : crossAxisSpacing),
              child: selectionController != null
                  ? AnimatedBuilder(
                      animation: selectionController!,
                      builder: (context, _) => _buildItemContent(context, item, offsetIndex),
                    )
                  : _buildItemContent(context, item, offsetIndex),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建具体的单项内容（缩略图、选中遮罩、焦点环等）。
  Widget _buildItemContent(BuildContext context, PhotoGridItem item, int absoluteOffset) {
    final bool selectionActive = selectionController?.isSelectionActive ?? false;
    final bool isSelected = selectionController?.selectedIds.contains(item.id) ?? false;
    final bool isFocused = selectionController?.focusedIndex == absoluteOffset;

    return GestureDetector(
      onTap: () {
        if (selectionActive) {
          selectionController!.toggleItem(item.id, index: absoluteOffset);
        } else {
          onTap?.call(item);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          itemBuilder(context, item),
          // 选中遮罩
          if (selectionActive || isSelected)
            Container(
              color: isSelected
                  ? (Theme.of(context).primaryColor.withAlpha(50))
                  : Colors.transparent,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.all(4.0),
              child: selectionActive ? Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).primaryColor : Colors.white70,
              ) : null,
            ),
          // 焦点环 (macOS 风格)
          if (isFocused)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
