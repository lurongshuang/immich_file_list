import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/example_page_wrapper.dart';
import '../widgets/photo_grid_gallery.dart';

class DesktopMacOSExample extends StatefulWidget {
  const DesktopMacOSExample({super.key});

  @override
  State<DesktopMacOSExample> createState() => _DesktopMacOSExampleState();
}

class _DesktopMacOSExampleState extends State<DesktopMacOSExample> {
  final List<DummyPhotoItem> _items = DummyDataFactory.generateDummyData(60, 5000);
  
  double _crossAxisCount = 6;
  double _mainAxisSpacing = 4.0;
  double _crossAxisSpacing = 4.0;
  double _aspectRatio = 1.0;

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: 'macOS 访达级桌面交互方案 (框选/键鼠/自动滚动)',
      items: _items,
      initialSelectionActive: true,
      builder: (context, items, controller) {
        return Column(
          children: [
            // 操作面板：动态调整布局参数以验证圈选与导航的健壮性
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                   _buildControl('列数: ${_crossAxisCount.toInt()}', (v) => setState(() => _crossAxisCount = v), 2, 12),
                   const VerticalDivider(),
                   _buildControl('主间距: ${_mainAxisSpacing.toInt()}', (v) => setState(() => _mainAxisSpacing = v), 0, 20),
                   const VerticalDivider(),
                   _buildControl('横间距: ${_crossAxisSpacing.toInt()}', (v) => setState(() => _crossAxisSpacing = v), 0, 20),
                   const VerticalDivider(),
                   _buildControl('比例: ${_aspectRatio.toStringAsFixed(1)}', (v) => setState(() => _aspectRatio = v), 0.5, 2.0),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withAlpha(20),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '通过上方滑块动态改变布局，验证圈选和方向键是否依然精准对齐。支持全量 Off-screen 持久化选中。',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PhotoGridGallery.grid(
                items: items,
                crossAxisCount: _crossAxisCount.toInt(),
                mainAxisSpacing: _mainAxisSpacing,
                crossAxisSpacing: _crossAxisSpacing,
                childAspectRatio: _aspectRatio,
                groupBy: GroupPhotoBy.month,
                showScrubber: true,
                selectionController: controller,
                onTap: (item) => handleTap(context, item, controller),
                onDoubleTap: (item) => handleDoubleTap(context, item, controller),
                onLongPress: (item) => handleLongPress(context, item, controller),
                onSecondaryTap: (item, pos) => handleSecondaryTap(context, item, pos),
                // 自定义滑块样式：现代简约圆形
                scrubberThumbBuilder: (context, offset, isDragging) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isDragging ? 12 : 8,
                    height: 60,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDragging 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.withAlpha(150),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isDragging ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ] : [],
                    ),
                  );
                },
                // 自定义气泡样式：玻璃拟态沉浸式设计
                scrubberLabelBuilder: (context, label, isDragging) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(220),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
                itemBuilder: buildDummyThumbnail,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControl(String label, ValueChanged<double> onChanged, double min, double max) {
    final double currentValue = label.contains('列') 
        ? _crossAxisCount 
        : (label.contains('主间') ? _mainAxisSpacing : (label.contains('横间') ? _crossAxisSpacing : _aspectRatio));

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
           Slider(
             value: currentValue,
             min: min,
             max: max,
             onChanged: onChanged,
           ),
        ],
      ),
    );
  }
}
