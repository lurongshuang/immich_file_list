import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

enum GroupAssetsBy { day, month, year, auto, none }

enum HeaderType { none, year, month, day, monthAndDay }

/// 分组渲染的数据桶抽象基类，用于承载一簇相同条件（如同一天）的照片数量。
abstract class Bucket {
  /// 该桶内包含的照片子项总数。
  int get assetCount;
}

/// 基于时间跨度的数据桶，用于记录特定日期下的相片数量。
class TimeBucket extends Bucket {
  final DateTime date;
  final int _assetCount;

  TimeBucket({required this.date, required int assetCount})
      : _assetCount = assetCount;

  @override
  int get assetCount => _assetCount;
}

/// 预计算生成的绘制渲染段 (Segment)。
///
/// `FixedSegmentBuilder` 会将外部的 `Bucket`（如按月或按天分组成的数据源）
/// 预先展开并精确计算好每一个 Item 面板与 Header 标签在 Sliver 网格中的物理坐标与高度。
/// 是支撑高性能滚动的结构核心。
abstract class Segment {
  final int firstIndex;
  final int lastIndex;
  final double startOffset;
  final double endOffset;
  final double spacing;
  final double headerExtent;
  final int firstAssetIndex;
  final Bucket bucket;

  final int gridIndex;
  final double gridOffset;
  final HeaderType header;

  const Segment({
    required this.firstIndex,
    required this.lastIndex,
    required this.startOffset,
    required this.endOffset,
    required this.firstAssetIndex,
    required this.bucket,
    required this.headerExtent,
    required this.spacing,
    required this.header,
  })  : gridIndex = firstIndex + 1,
        gridOffset = startOffset + headerExtent + spacing;

  bool containsIndex(int index) => firstIndex <= index && index <= lastIndex;
  bool isWithinOffset(double offset) => startOffset <= offset && offset <= endOffset;

  /// 将给定的滚动偏移量转换为该段落内的最小子项索引。
  int getMinChildIndexForScrollOffset(double scrollOffset);
  /// 将给定的滚动偏移量转换为该段落内的最大子项索引。
  int getMaxChildIndexForScrollOffset(double scrollOffset);
  /// 将子项索引转换为绝对布局偏移。
  double indexToLayoutOffset(int index);

  /// 构建视图项的 Builder。
  Widget builder(BuildContext context, int index);
}

extension SegmentListExtension on List<Segment> {
  bool equals(List<Segment> other) => length == other.length && lastOrNull?.endOffset == other.lastOrNull?.endOffset;
  Segment? findByIndex(int index) => firstWhereOrNull((s) => s.containsIndex(index));
  Segment? findByOffset(double offset) => firstWhereOrNull((s) => s.isWithinOffset(offset)) ?? lastOrNull;
}

typedef PhotoGridHeaderBuilder = Widget Function(BuildContext context, Bucket bucket, HeaderType header, double height, int assetOffset);
typedef PhotoGridRowBuilder = Widget Function(BuildContext context, int assetIndex, int assetCount, double tileHeight, double spacing, int columnCount);

class FixedSegment extends Segment {
  final double tileHeight;
  final int columnCount;
  final double mainAxisExtend;
  final PhotoGridHeaderBuilder headerBuilder;
  final PhotoGridRowBuilder rowBuilder;

  const FixedSegment({
    required super.firstIndex,
    required super.lastIndex,
    required super.startOffset,
    required super.endOffset,
    required super.firstAssetIndex,
    required super.bucket,
    required this.tileHeight,
    required this.columnCount,
    required super.headerExtent,
    required super.spacing,
    required super.header,
    required this.headerBuilder,
    required this.rowBuilder,
  })  : assert(tileHeight != 0),
        mainAxisExtend = tileHeight + spacing;

  @override
  double indexToLayoutOffset(int index) {
    final relativeIndex = index - gridIndex;
    return relativeIndex < 0 ? startOffset : gridOffset + (mainAxisExtend * relativeIndex);
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    final adjustedOffset = scrollOffset - gridOffset;
    if (!adjustedOffset.isFinite || adjustedOffset < 0) return firstIndex;
    return gridIndex + (adjustedOffset / mainAxisExtend).floor();
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    final adjustedOffset = scrollOffset - gridOffset;
    if (!adjustedOffset.isFinite || adjustedOffset < 0) return firstIndex;
    return gridIndex + (adjustedOffset / mainAxisExtend).ceil() - 1;
  }

  @override
  Widget builder(BuildContext context, int index) {
    if (index == firstIndex) {
      return headerBuilder(context, bucket, header, headerExtent, firstAssetIndex);
    }
    
    final rowIndexInSegment = index - (firstIndex + 1);
    final assetIndex = rowIndexInSegment * columnCount;
    final assetCount = bucket.assetCount;
    // 计算当前行具体包含多少个项（如果是段落最后一行，可能少于 columnCount）
    int numberOfAssets = columnCount;
    if (assetIndex + columnCount > assetCount) {
      numberOfAssets = assetCount - assetIndex;
    }

    return rowBuilder(
      context,
      firstAssetIndex + assetIndex,
      numberOfAssets,
      tileHeight,
      spacing,
      columnCount,
    );
  }
}

class FixedSegmentBuilder {
  final List<Bucket> buckets;
  final double tileHeight;
  final int columnCount;
  final double spacing;
  final GroupAssetsBy groupBy;
  final PhotoGridHeaderBuilder headerBuilder;
  final PhotoGridRowBuilder rowBuilder;

  const FixedSegmentBuilder({
    required this.buckets,
    required this.tileHeight,
    required this.columnCount,
    this.spacing = 2.0,
    this.groupBy = GroupAssetsBy.day,
    required this.headerBuilder,
    required this.rowBuilder,
  });

  static double headerExtent(HeaderType header) {
    const double kTimelineHeaderExtent = 80.0;
    switch (header) {
      case HeaderType.year:
        return kTimelineHeaderExtent * 1.2;
      case HeaderType.month:
        return kTimelineHeaderExtent;
      case HeaderType.day:
        return kTimelineHeaderExtent * 0.90;
      case HeaderType.monthAndDay:
        return kTimelineHeaderExtent * 1.6;
      case HeaderType.none:
        return 0.0;
    }
  }

  /// 执行段落预计算生成。
  /// 此函数会遍历所有 Bucket，根据分组规则计算每个 Segment 的索引范围和偏移量。
  List<Segment> generate() {
    final segments = <Segment>[];
    int firstIndex = 0;
    double startOffset = 0;
    int assetIndex = 0;
    DateTime? previousDate;

    for (int i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      final assetCount = bucket.assetCount;
      final numberOfRows = (assetCount / columnCount).ceil();
      final segmentCount = numberOfRows + 1;

      final segmentFirstIndex = firstIndex;
      firstIndex += segmentCount;
      final segmentLastIndex = firstIndex - 1;

      HeaderType timelineHeader;
      switch (groupBy) {
        case GroupAssetsBy.year:
          timelineHeader = HeaderType.year;
          break;
        case GroupAssetsBy.month:
          timelineHeader = HeaderType.month;
          break;
        case GroupAssetsBy.day:
        case GroupAssetsBy.auto:
          timelineHeader = (bucket is TimeBucket && previousDate != null && bucket.date.month != previousDate.month) || (bucket is TimeBucket && previousDate == null) 
              ? HeaderType.monthAndDay 
              : HeaderType.day;
          break;
        case GroupAssetsBy.none:
          timelineHeader = HeaderType.none;
          break;
      }
      
      final currentHeaderExtent = headerExtent(timelineHeader);
      final segmentStartOffset = startOffset;
      startOffset += currentHeaderExtent + (tileHeight * numberOfRows) + spacing * (numberOfRows - 1);
      final segmentEndOffset = startOffset;

      segments.add(
        FixedSegment(
          firstIndex: segmentFirstIndex,
          lastIndex: segmentLastIndex,
          startOffset: segmentStartOffset,
          endOffset: segmentEndOffset,
          firstAssetIndex: assetIndex,
          bucket: bucket,
          tileHeight: tileHeight,
          columnCount: columnCount,
          headerExtent: currentHeaderExtent,
          spacing: spacing,
          header: timelineHeader,
          headerBuilder: headerBuilder,
          rowBuilder: rowBuilder,
        ),
      );

      assetIndex += assetCount;
      if (bucket is TimeBucket) {
        previousDate = bucket.date;
      }
    }
    return segments;
  }
}
