import 'package:flutter/material.dart';
import "../widgets/example_page_wrapper.dart";
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

// ============================================
// 16. Divider List Example (Custom Dividers)
// ============================================
class DividerListExample extends StatelessWidget {
  const DividerListExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ExamplePageWrapper(
      title: '列表分割线示例',
      items: DummyDataFactory.generateDummyData(1, 100, mixedTypes: true),
      builder: (context, items, controller) => PhotoGridGallery.list(
        items: items,
        itemHeight: 70,
        selectionController: controller,
        onTap: (item) => handleTap(context, item, controller),
        itemBuilder: (context, item, isSelected, selectionActive) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: buildDummyThumbnail(context, item, isSelected, selectionActive),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.id,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Date: ${item.date.toIso8601String().split('T')[0]} | ID: ${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue)
                else
                  const Icon(Icons.circle_outlined, color: Colors.grey),
              ],
            ),
          );
        },
        // 构建自定义分割线
        dividerBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 82), // 让线对齐文字
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }
}
