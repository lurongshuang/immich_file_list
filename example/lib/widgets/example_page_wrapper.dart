import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
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

// 通用点击事件包装器：实现单选/首选逻辑（符合普通桌面端文件管理器体验）
void handleTap(BuildContext context, PhotoGridItem item, PhotoSelectionController controller) {
  final bool hasModifier = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                           HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);

  // 如果有修饰键，说明 PhotoDesktopSelectionRegion 的 PointerDown 已经处理过增量/范围选择了。
  // 我们这里直接跳过，避免 onTap 的 selectOnly 覆盖掉它。
  if (hasModifier) return;

  final platform = Theme.of(context).platform;
  final bool isMobile = platform == TargetPlatform.iOS || platform == TargetPlatform.android;

  // 如果处于选择模式且在移动端，则执行 toggle 操作（方便单手取消选中）
  if (controller.isSelectionActive && isMobile) {
    controller.toggleItem(item.id);
  } else {
    // 在桌面端或未进入选择模式时，执行单选逻辑（清空其他选中，符合访达/标准文件管理器习惯）
    controller.selectOnly(item.id);
  }
}

// 通用双击事件包装器
// 注意：启用此回调会导致 GestureDetector 的 onTap 产生约 300ms 的识别延迟。
// 如果追求极致的单击响应速度，请不要在 PhotoGridGallery 中传入 onDoubleTap 参数。
void handleDoubleTap(BuildContext context, PhotoGridItem item, PhotoSelectionController controller) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('🚀 双击触发（已知局限：会导致单击识别延迟 300ms）: ${item.id}'),
    duration: const Duration(seconds: 1),
    behavior: SnackBarBehavior.floating,
  ));
}

void handleLongPress(BuildContext context, PhotoGridItem item, PhotoSelectionController controller) {
  if (!controller.isSelectionActive) {
    controller.setSelectionActive(true);
  }
  controller.selectItem(item.id);
}

// 通用右键点击事件包装器：触发上下文菜单
void handleSecondaryTap(BuildContext context, PhotoGridItem item, Offset position) {
  final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) return;
  
  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      position & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: <PopupMenuEntry>[
      PopupMenuItem(
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 20),
            SizedBox(width: 8),
            Text('查看详情'),
          ],
        ),
        onTap: () => print('查看 ${item.id} 详情'),
      ),
      PopupMenuItem(
        child: const Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('复制 ID'),
          ],
        ),
        onTap: () => print('复制 ${item.id} ID'),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        child: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('删除', style: TextStyle(color: Colors.red)),
          ],
        ),
        onTap: () => print('删除 ${item.id}'),
      ),
    ],
  );
}
