import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid_library/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/example_page_wrapper.dart';

// ============================================
// 1. Basic Scrubber Example (Smooth Linear)
// ============================================
class BasicScrubberExample extends StatelessWidget {
  const BasicScrubberExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '基础平滑测试',
      items: DummyDataFactory.generateDummyData(5, 500),
      builder: (context, items, controller) => PhotoGridView(
        items: items,
        assetsPerRow: 4,               
        margin: 2.0,                   
        groupBy: GroupPhotoBy.month,   
        showDragScroll: true,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
      ),
    );
  }
}
