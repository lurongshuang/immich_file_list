import 'dart:math';
import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';

class DummyPhotoItem implements PhotoGridItem {
  @override
  final String id;
  @override
  final DateTime date;
  final Color color;
  final String title;
  final bool isVideo;

  DummyPhotoItem({
    required this.id,
    required this.date,
    required this.color,
    this.title = '',
    this.isVideo = false,
  });
}

/// 示例 UI 构建器：将 DummyPhotoItem 渲染为网格项。
Widget buildDummyThumbnail(
  BuildContext context,
  PhotoGridItem item,
  bool isSelected,
  bool selectionActive,
) {
  if (item is! DummyPhotoItem) return const SizedBox();

  return Stack(
    fit: StackFit.expand,
    children: [
      Container(
        color: item.color,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                item.id,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (item.title.isNotEmpty)
              Positioned(
                bottom: 4,
                left: 4,
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    backgroundColor: Colors.black45,
                  ),
                ),
              ),
            if (item.isVideo)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
      // 业务层定义的选中遮罩
      if (selectionActive || isSelected)
        Container(
          color: isSelected
              ? (Theme.of(context).primaryColor.withAlpha(50))
              : Colors.transparent,
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(4.0),
          child: selectionActive
              ? Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.white70,
                )
              : null,
        ),
    ],
  );
}

class DummyDataFactory {
  /// Generates dummy photo items covering the specified number of months.
  static List<DummyPhotoItem> generateDummyData(
    int months,
    int count, {
    bool mixedTypes = false,
  }) {
    final random = Random(42);
    final List<DummyPhotoItem> generated = [];
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      final randomDaysAgo = random.nextInt(months * 30 + 1);
      final date = now.subtract(Duration(days: randomDaysAgo));
      final color = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1.0,
      );

      final isVideo = mixedTypes ? random.nextBool() : false;
      final title = mixedTypes && random.nextBool() ? '标题 $i' : '';

      generated.add(
        DummyPhotoItem(
          id: '图片 $i',
          date: date,
          color: color,
          isVideo: isVideo,
          title: title,
        ),
      );
    }

    generated.sort((a, b) => b.date.compareTo(a.date));
    return generated;
  }
}
