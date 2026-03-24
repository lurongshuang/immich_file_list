import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 6. Selection Mode Example (Controller Based)
// ============================================
class SelectionExample extends StatelessWidget {
  const SelectionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '纯净的选择模式 (按住拖拽 - 48个月 10000图极限)',
      items: DummyDataFactory.generateDummyData(48, 10000),
      initialSelectionActive: true,
      builder: (context, items, controller) {
        return PhotoGridGallery.grid(
          items: items,
          crossAxisCount: 4,
          mainAxisSpacing: 2.0,
          crossAxisSpacing: 2.0,
          groupBy: GroupPhotoBy.none,    
          showScrubber: false,         
          selectionController: controller,
          onTap: (item) => handleTap(context, item, controller),
          itemBuilder: buildDummyThumbnail,
        );
      }
    );
  }
}
