import 'package:flutter/material.dart';
import 'package:immich_file_list/photo_grid/photo_grid.dart';
import '../dummy_data.dart';
import '../widgets/photo_grid_gallery.dart';

class ScrubberToggleExample extends StatefulWidget {
  const ScrubberToggleExample({super.key});

  @override
  State<ScrubberToggleExample> createState() => _ScrubberToggleExampleState();
}

class _ScrubberToggleExampleState extends State<ScrubberToggleExample> {
  bool _showPrompt = true;
  bool _showRuler = true;
  late final List<PhotoGridItem> _items;

  @override
  void initState() {
    super.initState();
    // 生成 12 个月的数据以触发磁吸和显示刻度
    _items = DummyDataFactory.generateDummyData(12, 1000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('滑块组件开关测试'),
        actions: [
          Row(
            children: [
              const Text('气泡', style: TextStyle(fontSize: 12)),
              Switch(
                value: _showPrompt,
                onChanged: (v) => setState(() => _showPrompt = v),
              ),
            ],
          ),
          Row(
            children: [
              const Text('标尺', style: TextStyle(fontSize: 12)),
              Switch(
                value: _showRuler,
                onChanged: (v) => setState(() => _showRuler = v),
              ),
            ],
          ),
        ],
      ),
      body: PhotoGridGallery.grid(
        items: _items,
        crossAxisCount: 4, // 默认补上
        showScrubber: true,
        showScrubberPrompt: _showPrompt,
        showScrubberRuler: _showRuler,
        onTap: (item) => print('Tap: ${item.id}'),
        itemBuilder: (context, item) => Container(
          color: Colors.grey.shade300,
          child: Center(child: Text(item.id.substring(0, 4), style: const TextStyle(fontSize: 10))),
        ),
      ),
    );
  }
}
