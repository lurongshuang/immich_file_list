import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 2. Large Snap Example (Magnetic Snapping)
// ============================================
class LargeSnapExample extends StatelessWidget {
  const LargeSnapExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '超大数据量磁吸测试 (48个月极限方案)',
      items: DummyDataFactory.generateDummyData(48, 30000),
      builder: (context, items, controller) => PhotoGridGallery.grid(
        items: items,
        crossAxisCount: 5,               
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 1.0,
        groupBy: GroupPhotoBy.month,
        showScrubber: true,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
        itemBuilder: buildDummyThumbnail,
      ),
    );
  }
}
