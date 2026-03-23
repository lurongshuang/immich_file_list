import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';

/// 这是一个业务层面的组合组件示例。
/// 它将列表视图、滑动条和拖拽选择区域组合在一起，
/// 实现了曾经 PhotoGridView 内部集成的所有功能，但现在是以组合的方式。
class PhotoGridGallery extends StatefulWidget {
  final List<PhotoGridItem> items;
  final PhotoSelectionController? selectionController;
  final int assetsPerRow;
  final double margin;
  final double childAspectRatio;
  final GroupPhotoBy groupBy;
  final bool showScrubber;
  final void Function(PhotoGridItem)? onTap;
  final Widget? topSliver;

  const PhotoGridGallery({
    super.key,
    required this.items,
    this.selectionController,
    this.assetsPerRow = 4,
    this.margin = 3.0,
    this.childAspectRatio = 1.0,
    this.groupBy = GroupPhotoBy.month,
    this.showScrubber = true,
    this.onTap,
    this.topSliver,
  });

  @override
  State<PhotoGridGallery> createState() => _PhotoGridGalleryState();
}

class _PhotoGridGalleryState extends State<PhotoGridGallery> {
  final ScrollController _scrollController = ScrollController();
  List<Segment> _segments = [];
  
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
    Widget grid = PhotoGridView(
      items: widget.items,
      assetsPerRow: widget.assetsPerRow,
      margin: widget.margin,
      childAspectRatio: widget.childAspectRatio,
      groupBy: widget.groupBy,
      selectionController: widget.selectionController,
      controller: _scrollController,
      onSegmentsChanged: _onSegmentsChanged,
      onTap: widget.onTap,
      topSliver: widget.topSliver,
    );

    // 包装拖拽选择区域
    grid = PhotoDragRegion(
      onStart: _setDragStartIndex,
      onAssetEnter: _handleDragAssetEnter,
      onEnd: _stopDrag,
      onScroll: _dragScroll,
      child: grid,
    );

    // 如果启用，包装滑动条
    if (widget.showScrubber && widget.items.length >= 20 && _segments.isNotEmpty) {
      grid = PhotoGridScrubber(
        controller: _scrollController,
        segments: _segments,
        timelineHeight: MediaQuery.of(context).size.height,
        topPadding: MediaQuery.of(context).padding.top + 50,
        bottomPadding: MediaQuery.of(context).padding.bottom + 48.0,
        child: grid,
      );
    }

    return grid;
  }
}
