import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid_library/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/example_page_wrapper.dart';

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
      builder: (context, items, controller) => PhotoGridView(
        items: items,
        assetsPerRow: 5,               
        margin: 1.0,
        groupBy: GroupPhotoBy.month,
        showDragScroll: true,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
      ),
    );
  }
}
