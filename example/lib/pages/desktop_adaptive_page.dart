import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 7. Desktop Adaptive Example (Using AdaptiveContainer Wrapper)
// ============================================
class DesktopAdaptiveExample extends StatelessWidget {
  const DesktopAdaptiveExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '桌面端自适应 (防抖容器版)',
      items: DummyDataFactory.generateDummyData(48, 10000),
      builder: (context, items, controller) {
        // 使用通用的 AdaptiveContainer 包裹网格组件
        // 核心目的：拖动窗口边缘时，防止内部 GridView 频繁触发 build，
        // 只有拖动停止 300ms 后，builder 才会收到最新的稳定宽度并仅重绘一次。
        return AdaptiveContainer(
          debounceDuration: const Duration(milliseconds: 300),
          builder: (context, stableWidth) {
            // 这里才是真正的业务计算逻辑：外部决定怎么用这个宽度
            final crossAxisCount = (stableWidth / 180).floor().clamp(2, 20);

            return PhotoGridGallery.grid(
              key: ValueKey('grid_at_width_$stableWidth'), // 给个 key 确保重绘时状态干净
              items: items,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              groupBy: GroupPhotoBy.day,
              showScrubber: true,
              selectionController: controller,
              onTap: (item) => handleTap(context, item, controller),
              itemBuilder: buildDummyThumbnail,
            );
          },
        );
      },
    );
  }
}
