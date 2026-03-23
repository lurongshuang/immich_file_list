import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 4. Normal List Example (No grouping, basic list)
// ============================================
class NormalListExample extends StatelessWidget {
  const NormalListExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '普通流水列表',
      items: DummyDataFactory.generateDummyData(1, 200, mixedTypes: true),
      builder: (context, items, controller) => PhotoGridGallery(
        items: items,
        assetsPerRow: 1,               
        childAspectRatio: 2.5,
        margin: 6.0,                   
        groupBy: GroupPhotoBy.none,     
        showScrubber: false,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
        itemBuilder: buildDummyThumbnail,
      ),
    );
  }
}
