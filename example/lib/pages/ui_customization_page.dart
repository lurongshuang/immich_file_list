import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';
import '../widgets/example_page_wrapper.dart';

class UICustomizationExample extends StatefulWidget {
  const UICustomizationExample({super.key});

  @override
  State<UICustomizationExample> createState() => _UICustomizationExampleState();
}

class _UICustomizationExampleState extends State<UICustomizationExample> {
  final List<DummyPhotoItem> _items = DummyDataFactory.generateDummyData(12, 500);
  final PhotoSelectionController _selectionController = PhotoSelectionController();

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
        return Scaffold(
          appBar: AppBar(
            title: Text(_selectionController.isSelectionActive 
                ? '已选择 ${_selectionController.selectedIds.length} 项' 
                : 'UI 定制化大赏 (Item & Header)'),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
          ),
          body: PhotoGridGallery.grid(
            items: _items,
            crossAxisCount: 3,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            groupBy: GroupPhotoBy.month,
            selectionController: _selectionController,
            onTap: (item) => handleTap(context, item, _selectionController), 
            onDoubleTap: (item) => handleDoubleTap(context, item, _selectionController),
            onLongPress: (item) => handleLongPress(context, item, _selectionController),
            onSecondaryTap: (item, pos) => handleSecondaryTap(context, item, pos),
            // 1. 自定义桌面端选框样式：橙色描边 + 极低透明度填充
            selectionBoxPainterBuilder: (rect, color) => _CustomSelectionPainter(rect, Colors.orange),
            // 2. 自定义头部：深色雅致风格 + 简单的全选交互逻辑演示
            headerBuilder: (context, bucket, type, height, assetOffset) {
              final date = (bucket as TimeBucket).date;
              return Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${date.year} 年 ${date.month} 月',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    TextButton(
                      onPressed: () => print('点击了 ${date.month} 月的全选'),
                      child: const Text('全选', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
            // 2. 自定义项视图：实现类似网盘的选中效果（圆圈勾选 + 缩放感）
            itemBuilder: (context, item, isSelected, selectionActive) {
              final dummy = item as DummyPhotoItem;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: EdgeInsets.all(isSelected ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSelected ? 16 : 0),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]
                      : [],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 底色
                    Container(color: dummy.color),
                    // 图片 ID
                    Center(
                      child: Text(
                        dummy.id,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // 选中状态的特定叠加层
                    if (isSelected)
                      Positioned.fill(
                        child: Container(color: Colors.blue.withAlpha(40)),
                      ),
                    // 勾选图标 (仅在选中或多选模式激活时显示)
                    if (selectionActive || isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          color: isSelected ? Colors.blue : Colors.white70,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CustomSelectionPainter extends CustomPainter {
  final Rect rect;
  final Color color;

  _CustomSelectionPainter(this.rect, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color.withAlpha(20)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 甚至可以用虚线（这里简化为实线，但增加了宽度和透明度区分）
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_CustomSelectionPainter oldDelegate) => oldDelegate.rect != rect;
}
