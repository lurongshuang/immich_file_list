import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

class FixedExtentExample extends StatelessWidget {
  const FixedExtentExample({super.key});

  @override
  Widget build(BuildContext context) {
    final items = DummyDataFactory.generateDummyData(24, 200, mixedTypes: true);

    return Scaffold(
      appBar: AppBar(title: const Text('固定高度列表 (List Mode)')),
      body: PhotoGridGallery.list(
        items: items,
        itemHeight: 82.0,
        mainAxisSpacing: 0.0,
        crossAxisSpacing: 0.0,
        groupBy: GroupPhotoBy.day,
        showScrubber: true,
        itemBuilder: (context, item) {
          final dummy = item as DummyPhotoItem;
          return _FileListTile(item: dummy);
        },
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final DummyPhotoItem item;

  const _FileListTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 缩略图
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (item.isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.isVideo ? '0:45' : 'RAW',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 文件名与详情
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'IMG_${item.id.replaceAll(RegExp(r'[^0-9]'), '')}.jpg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.date.hour}:${item.date.minute} • 2.4 MB • 4032 × 3024',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // 操作按钮
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
    );
  }
}
