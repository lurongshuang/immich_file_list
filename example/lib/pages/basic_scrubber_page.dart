import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

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
      builder: (context, items, controller) => PhotoGridGallery(
        items: items,
        assetsPerRow: 4,
        margin: 2.0,
        groupBy: GroupPhotoBy.month,
        showScrubber: true,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
        itemBuilder: buildDummyThumbnail,
      ),
    );
  }
}
