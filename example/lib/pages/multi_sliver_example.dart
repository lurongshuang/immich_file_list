import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 10. Multi-Sliver Mixed Headers Example
// ============================================
class MultiSliverExample extends StatefulWidget {
  const MultiSliverExample({super.key});

  @override
  State<MultiSliverExample> createState() => _MultiSliverExampleState();
}

class _MultiSliverExampleState extends State<MultiSliverExample> {
  bool _isScrubbing = false;

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '复合多 Sliver 吸顶测试',
      items: DummyDataFactory.generateDummyData(24, 8000),
      builder: (context, items, controller) {
        final isSelecting = controller.isSelectionActive;
        final selectedCount = controller.selectedIds.length;
        final totalAssetCount = items.length;

        return Stack(
          children: [
            PhotoGridGallery(
              items: items,
              assetsPerRow: 4,
              margin: 2.0,
              groupBy: GroupPhotoBy.month,
              showScrubber: true,
              selectionController: controller,
              onTap: (item) => handleTap(context, item, controller),
              itemBuilder: buildDummyThumbnail,
              // 关键：设置滑块的顶部边距，使其避开顶部的 AppBar 和筛选栏区域
              scrubberTopPadding: 180, 
              scrubberBottomPadding: 40,
              // 关键：设置滚动基准值，使滑块的 0% 位置对应列表的开始（跳过 180px 的头部）
              scrubberScrollOffsetBaseline: 180,
              // 这里展示 topSlivers 的强大之处：
              // 可以同时拥有一个吸顶的 AppBar 和一个随列表滑动的工具栏
              topSlivers: [
                SliverAppBar(
                  expandedHeight: 120.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: isSelecting ? Colors.orange : Colors.blue,
                  elevation: 0,
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
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                           controller.clearSelection();
                           controller.setSelectionActive(false);
                        },
                      ),
                    if (!isSelecting)
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                    if (!isSelecting)
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
                    centerTitle: false,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSelecting && selectedCount > 0 ? '已选择 $selectedCount 项' : '媒体库',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (!isSelecting)
                          Text(
                            '共 $totalAssetCount 个文件',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal, color: Colors.white70),
                          ),
                      ],
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isSelecting 
                              ? [Colors.orange.shade700, Colors.orange.shade400]
                              : [Colors.blue.shade700, Colors.blue.shade400],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list, size: 18, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text('筛选器与快速搜索区域 (随动)', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
              onScrubberDragStart: () => setState(() => _isScrubbing = true),
              onScrubberDragEnd: () => setState(() => _isScrubbing = false),
            ),
            // 滑动状态反馈层
            if (_isScrubbing)
              IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text(
                          '快速定位中...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
