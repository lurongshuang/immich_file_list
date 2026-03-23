import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 3. Custom Grid Example (Styles & Day grouping)
// ============================================
class CustomGridExample extends StatelessWidget {
  const CustomGridExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '宫格定制形态',
      items: DummyDataFactory.generateDummyData(2, 100, mixedTypes: true),
      builder: (context, items, controller) => PhotoGridGallery(
        items: items,
        assetsPerRow: 2,               
        margin: 6.0,                   
        groupBy: GroupPhotoBy.day,     
        showScrubber: true,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
        itemBuilder: buildDummyThumbnail,
      ),
    );
  }
}
