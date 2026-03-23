import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 5. Complex List View Example (SliverAppBar)
// ============================================
class ListViewExample extends StatelessWidget {
  const ListViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '复杂 SliverAppBar 测试',
      items: DummyDataFactory.generateDummyData(48, 10000),
      builder: (context, items, controller) {
        final isSelecting = controller.isSelectionActive;
        final selectedCount = controller.selectedIds.length;

        return PhotoGridGallery(
          items: items,
          assetsPerRow: 1,               
          childAspectRatio: 3.5,
          margin: 8.0,
          groupBy: GroupPhotoBy.month,
          showScrubber: true,
          selectionController: controller,
          onTap: (item) => handleTap(context, item, controller),
          // 这里动态利用控制器来重塑顶层头部
          topSliver: SliverAppBar(
            title: Text(isSelecting && selectedCount > 0 ? '已选择 $selectedCount 项' : '复合 SliverAppBar 测试'),
            pinned: true,
            expandedHeight: 200.0,
            leading: isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clearSelection();
                      controller.setSelectionActive(false);
                    },
                  )
                : const BackButton(),
            actions: [
               if (isSelecting && selectedCount > 0)
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('确认提交 $selectedCount 项。')));
                      controller.clearSelection();
                      controller.setSelectionActive(false);
                    },
                  ),
            ],
            flexibleSpace: const FlexibleSpaceBar(
              background: ColoredBox(color: Colors.blueGrey),
            ),
          ),
        );
      },
    );
  }
}
