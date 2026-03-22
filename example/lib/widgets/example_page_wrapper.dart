import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid_library/photo_grid.dart';
import '../dummy_data.dart';

// 提取一个通用的带有控制器、删除和导航条逻辑的骨架壳子，避免每个案例写重复代码。
class ExamplePageWrapper extends StatefulWidget {
  final String title;
  final List<DummyPhotoItem> items;
  final bool initialSelectionActive;
  final Widget Function(BuildContext context, List<DummyPhotoItem> updatedItems, PhotoSelectionController controller) builder;

  const ExamplePageWrapper({
    super.key,
    required this.title,
    required this.items,
    this.initialSelectionActive = false,
    required this.builder,
  });

  @override
  State<ExamplePageWrapper> createState() => _ExamplePageWrapperState();
}

class _ExamplePageWrapperState extends State<ExamplePageWrapper> {
  final PhotoSelectionController _selectionController = PhotoSelectionController();
  late List<DummyPhotoItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    if (widget.initialSelectionActive) {
      _selectionController.setSelectionActive(true);
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _selectionController,
      builder: (context, _) {
        final isSelecting = _selectionController.isSelectionActive;
        final selectedCount = _selectionController.selectedIds.length;

        return Scaffold(
          appBar: widget.title.contains('复合') // 对于第5个案例由于内部集成了 SliverAppBar，所以外部不要加。
              ? null
              : AppBar(
                  title: Text(isSelecting && selectedCount > 0 ? '已选择 $selectedCount 项' : widget.title),
                  leading: isSelecting
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _selectionController.clearSelection();
                            _selectionController.setSelectionActive(false);
                          },
                        )
                      : const BackButton(),
                  actions: [
                    if (isSelecting && selectedCount > 0)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _items.removeWhere((item) => _selectionController.selectedIds.contains(item.id));
                            _selectionController.clearSelection();
                            _selectionController.setSelectionActive(false);
                          });
                        },
                      ),
                  ],
                ),
          body: widget.builder(context, _items, _selectionController),
        );
      }
    );
  }
}

// 通用点击事件包装器，区分多选还是正常查看大图
void handleTap(BuildContext context, PhotoGridItem item, PhotoSelectionController controller) {
  if (controller.isSelectionActive) {
    controller.toggleItem(item.id);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('查看大图: ${item.id} (长按可进入多选)')));
  }
}
